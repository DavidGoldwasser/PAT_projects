# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'json'

# start the measure
class OpenStudioModelArticulationTestingScenarioBuilder < OpenStudio::Ruleset::ModelUserScript

  # require all .rb files in resources folder
  Dir[File.dirname(__FILE__) + '/resources/*.rb'].each {|file| require file }

  # resource file modules
  include OsLib_ModelGeneration

  # human readable name
  def name
    return "OpenStudio Model Articulation Testing Scenario Builder"
  end

  # human readable description
  def description
    return "This measure will copy the OSW, alter it based on argument choices selected, run the OSW in the CLI, and pass the resulting model out of the measure. It should be the last OpenStudio measure in the workflow."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Based on selected sceario this measure will set __SKIP__ to false and will change downstream measure argument values as needed. For example Building Type selected here will map to bldg_type_a, total_bldg_floor_area, num_stories_above_grade, and num_stories_below_grade in create_bar_from_building_type_ratios measure."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Make an argument for the bldg_type_a
    building_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('building_type', get_building_types(), true)
    building_type.setDisplayName('Building Type')
    building_type.setDefaultValue('SmallOffice')
    args << building_type

    # Make argument for template
    template = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('template', get_templates(), true)
    template.setDisplayName('Target Standard')
    template.setDefaultValue('90.1-2004')
    args << template

    # Make an argument for the climate zone (copied from create_doe_prototype_building iwth NECB HDD Method removed)
    climate_zone_chs = OpenStudio::StringVector.new
    climate_zone_chs << 'ASHRAE 169-2013-1A'
    #climate_zone_chs << 'ASHRAE 169-2013-1B'
    climate_zone_chs << 'ASHRAE 169-2013-2A'
    climate_zone_chs << 'ASHRAE 169-2013-2B'
    climate_zone_chs << 'ASHRAE 169-2013-3A'
    climate_zone_chs << 'ASHRAE 169-2013-3B'
    climate_zone_chs << 'ASHRAE 169-2013-3C'
    climate_zone_chs << 'ASHRAE 169-2013-4A'
    climate_zone_chs << 'ASHRAE 169-2013-4B'
    climate_zone_chs << 'ASHRAE 169-2013-4C'
    climate_zone_chs << 'ASHRAE 169-2013-5A'
    climate_zone_chs << 'ASHRAE 169-2013-5B'
    #climate_zone_chs << 'ASHRAE 169-2013-5C'
    climate_zone_chs << 'ASHRAE 169-2013-6A'
    climate_zone_chs << 'ASHRAE 169-2013-6B'
    climate_zone_chs << 'ASHRAE 169-2013-7A'
    #climate_zone_chs << 'ASHRAE 169-2013-7B'
    climate_zone_chs << 'ASHRAE 169-2013-8A'
    #climate_zone_chs << 'ASHRAE 169-2013-8B'
    #climate_zone_chs << 'NECB HDD Method'
    climate_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('climate_zone', climate_zone_chs, true)
    climate_zone.setDisplayName('Climate Zone.')
    climate_zone.setDefaultValue('ASHRAE 169-2013-2A')
    args << climate_zone

    # Make an argument for the climate zone (copied from create_doe_prototype_building iwth NECB HDD Method removed)
    scenario_chs = OpenStudio::StringVector.new
    scenario_chs << 's0 Prototype'
    scenario_chs << 's1 Prototype - const'
    scenario_chs << 's2 Prototype - loads'
    scenario_chs << 's3 Prototype - swh exhaust'
    scenario_chs << 's4 Prototype - setpoints'
    scenario_chs << 's5 Prototype - hvac'
    #scenario_chs << 's6 Bar Sliced' # May start from prototype or empty seed model with same simulation settings
    #scenario_chs << 's7 Bar Blended Core and Perimeter'
    #scenario_chs << 's8 Footprint Blended Single Space per Story' # May be whole building blend or, blend by story
    #scenario_chs << 's9 Prototype Geometry Blended' # whole building blended space type applied to prototype geometry, every thing other than geometry should be removed and rebuilt
    #scenario_chs << 's10 Footprint Blended Core and Perimeter'
    scenario = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('scenario', scenario_chs, true)
    scenario.setDisplayName('Model Articulation Scenario.')
    scenario.setDescription("This choice will determine which measures will run and may also alter argument values for those measures.")
    scenario.setDefaultValue('s0 Prototype')
    args << scenario

    # todo - add argument to use pre-saved OSW in resources directory vs. grabbing from live project

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    building_type = runner.getStringArgumentValue("building_type", user_arguments)
    template = runner.getStringArgumentValue("template", user_arguments)
    climate_zone = runner.getStringArgumentValue("climate_zone", user_arguments)
    scenario = runner.getStringArgumentValue("scenario", user_arguments)

    # save new osw
    new_workflow_path = 'scenario_builder/new_workflow.osw'
    new_workflow_path = File.absolute_path(new_workflow_path)
    runner.workflow.saveAs(new_workflow_path)

    # load the new workflows
    new_osw = nil
    File.open(new_workflow_path, 'r') do |f|
      new_osw = JSON::parse(f.read, :symbolize_names => true)
    end

    # map scenarios to integers
    scenario_hash = {}
    scenario_hash['s0 Prototype'] = 0
    scenario_hash['s1 Prototype - const'] = 1
    scenario_hash['s2 Prototype - loads'] = 2
    scenario_hash['s3 Prototype - swh exhaust'] = 3
    scenario_hash['s4 Prototype - setpoints'] = 4
    scenario_hash['s5 Prototype - hvac'] = 5

    # used to differentiate first versus second instance of create_typical
    found_typical = false

    # loop through steps
    new_osw[:steps].each do |step|

      if step[:measure_dir_name] == "openstudio_model_articulation_testing_scenario_builder"
        step[:arguments][:__SKIP__] = true
      else
        runner.registerInfo("Inspecting #{step[:name]}")

        # change building type, template, and climate zone
        step[:arguments].each do |k,v|
          if k == :building_type
            runner.registerInfo("Changing value of #{k} to #{building_type}")
            step[:arguments][k] = building_type
          elsif k == :bldg_type_a
            runner.registerInfo("Changing value of #{k} to #{building_type}")
            step[:arguments][k] = building_type
          elsif k == :template
            runner.registerInfo("Changing value of #{k} to #{template}")
            step[:arguments][k] = template
          elsif k == :climate_zone
            runner.registerInfo("Changing value of #{k} to #{climate_zone}")
            step[:arguments][k] = climate_zone
          end

        end
      end

      # add logic for EMS clean when HVAC is boing to be replaced by create_typical
      if step[:measure_dir_name] == "remove_ems_objects"
        if scenario_hash[scenario] >= 5 then step[:arguments][:__SKIP__] = false else step[:arguments][:__SKIP__] = true end
      end

      # add logic for which measures to skip for each scenario
      # todo - update for scenarios beyond s5
      if step[:measure_dir_name] == "create_typical_building_from_model"

        if scenario_hash[scenario] > 0

          if found_typical
            #add hvac
            if scenario_hash[scenario] >= 5
              step[:arguments][:add_hvac] = true
              step[:arguments][:use_upstream_args] = false # don't want to inherit bools from first instance. Template is already taken care of.
              step[:arguments][:__SKIP__] = false
            else
              step[:arguments][:add_hvac] = false
              step[:arguments][:__SKIP__] = true
            end
          else
            if scenario_hash[scenario] >= 1 then step[:arguments][:add_constructions] = true else step[:arguments][:add_constructions] = false end
            if scenario_hash[scenario] >= 1 then step[:arguments][:add_internal_mass] = true else step[:arguments][:add_internal_mass] = false end
            if scenario_hash[scenario] >= 2 then step[:arguments][:add_space_type_loads] = true else step[:arguments][:add_space_type_loads] = false end
            if scenario_hash[scenario] >= 2 then step[:arguments][:add_elevators] = true else step[:arguments][:add_elevators] = false end
            if scenario_hash[scenario] >= 2 then step[:arguments][:add_exterior_lights] = true else step[:arguments][:add_exterior_lights] = false end
            if scenario_hash[scenario] >= 3 then step[:arguments][:add_exhaust] = true else step[:arguments][:add_exhaust] = false end
            if scenario_hash[scenario] >= 3 then step[:arguments][:add_swh] = true else step[:arguments][:add_swh] = false end
            if scenario_hash[scenario] >= 3 then step[:arguments][:add_refrigeration] = true else step[:arguments][:add_refrigeration] = false end
            if scenario_hash[scenario] >= 4 then step[:arguments][:add_thermostat] = true else step[:arguments][:add_thermostat] = false end
            if scenario_hash[scenario] >= 5 then step[:arguments][:add_hvac] = true else step[:arguments][:add_hvac] = false end
            #step[:arguments][:add_hvac] = false
            step[:arguments][:__SKIP__] = false

            # set flag so next instance will be flagged to set HVAC if requested
            found_typical = true
          end

          # summary of argument values for create_typical_building_from_model
          runner.registerInfo("Summary of final measure argument values for #{step[[:name]]}")
          step[:arguments].each do |arg_k,arg_v|
            runner.registerInfo("#{arg_k} is #{arg_v}")
          end

        else
          step[:arguments][:__SKIP__] = true
        end
      else
        # no catchall behavior
      end

    end

    # todo - map floor area and num stories above and below grade from bldg_type_a

    # todo - map climate zone and weather files if add change building location in vs. running prototype first for bar and footprint workflows

    # update path to measures and seed model
    new_measure_paths = []
    new_osw[:measure_paths].each do |path|
      new_measure_paths << "../../../#{path}"
    end
    new_osw[:measure_paths] = new_measure_paths
    new_file_paths = []
    new_osw[:file_paths].each do |path|
      new_file_paths << "../../../#{path}"
    end
    new_osw[:file_paths] = new_file_paths

    # report initial condition of model
    runner.registerInitialCondition("Reverting back to #{new_osw[:seed_file]}.")

    # save the configured osws
    File.open(new_workflow_path, 'w') do |f|
      f << JSON.pretty_generate(new_osw)
    end

    # run updated OSW (measures only, Model measures only)
    # this will start with the seed model prior to being edited by upstream measures
    runner.registerInfo("Runing modified OSW in OpenStudio CLI")
    cli_path = OpenStudio.getOpenStudioCLI
    cmd = "\"#{cli_path}\" run -m -w \"#{new_workflow_path}\""
    system(cmd)

    # open resulting osw
    out_osw_path = 'scenario_builder/out.osw'
    out_osw_path = File.absolute_path(out_osw_path)
    # load the new workflows
    out_osw = nil
    File.open(out_osw_path, 'r') do |f|
      out_osw = JSON::parse(f.read, :symbolize_names => true)
    end

    # loop through steps
    steps_run = 0
    out_osw[:steps].each do |step|

      next if not step.key?(:result) # this will be hit for E+ or Reporting measures in original OSW
      next if step[:result][:step_result] == 'Skip #'
      steps_run += 1

      runner.registerInfo("***** #{step[:name]} (#{step[:result][:step_result]}) *****")

      # loop through step_info (this contains initial and final condition)
      step[:result][:step_info].each do |log|
        runner.registerInfo(log)
      end

      # loop through step_warning
      step[:result][:step_warnings].each do |log|
        runner.registerWarning(log)
      end

      # loop through step_errors
      step[:result][:step_errors].each do |log|
        runner.registerError(log)
        return false
      end

    end

    # log that cli run is done
    runner.registerInfo("Finished Running OpenStudio CLI")

    # get the model out of the OSW
    new_model_path = 'scenario_builder/run/in.osm'
    new_model_path = File.absolute_path(new_model_path)
    runner.registerInfo("Replacing model with #{new_model_path}")

    translator = OpenStudio::OSVersion::VersionTranslator.new
    newModel = translator.loadModel(new_model_path)
    newModel = newModel.get

    # alternative swap
    # remove existing objects from model
    handles = OpenStudio::UUIDVector.new
    model.objects.each do |obj|
      handles << obj.handle
    end
    model.removeObjects(handles)
    # add new file to empty model
    model.addObjects( newModel.toIdfFile.objects )

    # report final condition of model
    runner.registerFinalCondition("Workflow with #{steps_run} steps ran within this measure and replaced the model that was passed in.")

    return true

  end
  
end

# register the measure to be used by the application
OpenStudioModelArticulationTestingScenarioBuilder.new.registerWithApplication
