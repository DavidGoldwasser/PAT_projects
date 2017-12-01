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
    climate_zone_chs << 'ASHRAE 169-2006-1A'
    #climate_zone_chs << 'ASHRAE 169-2006-1B'
    climate_zone_chs << 'ASHRAE 169-2006-2A'
    climate_zone_chs << 'ASHRAE 169-2006-2B'
    climate_zone_chs << 'ASHRAE 169-2006-3A'
    climate_zone_chs << 'ASHRAE 169-2006-3B'
    climate_zone_chs << 'ASHRAE 169-2006-3C'
    climate_zone_chs << 'ASHRAE 169-2006-4A'
    climate_zone_chs << 'ASHRAE 169-2006-4B'
    climate_zone_chs << 'ASHRAE 169-2006-4C'
    climate_zone_chs << 'ASHRAE 169-2006-5A'
    climate_zone_chs << 'ASHRAE 169-2006-5B'
    #climate_zone_chs << 'ASHRAE 169-2006-5C'
    climate_zone_chs << 'ASHRAE 169-2006-6A'
    climate_zone_chs << 'ASHRAE 169-2006-6B'
    climate_zone_chs << 'ASHRAE 169-2006-7A'
    #climate_zone_chs << 'ASHRAE 169-2006-7B'
    climate_zone_chs << 'ASHRAE 169-2006-8A'
    #climate_zone_chs << 'ASHRAE 169-2006-8B'
    #climate_zone_chs << 'NECB HDD Method'
    climate_zone = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('climate_zone', climate_zone_chs, true)
    climate_zone.setDisplayName('Climate Zone.')
    climate_zone.setDefaultValue('ASHRAE 169-2006-2A')
    args << climate_zone

    # Make an argument for the climate zone (copied from create_doe_prototype_building iwth NECB HDD Method removed)
    scenario_chs = OpenStudio::StringVector.new
    scenario_chs << 'DOE Prototype Building'
    scenario_chs << 'DOE Prototype Building with new constructions'
    scenario_chs << 'DOE Prototype Building with changes above and new loads, sch, and ext lights'
    scenario_chs << 'DOE Prototype Building with changes above and new swh and exhaust'
    scenario_chs << 'DOE Prototype Building with changes above and new thermostats'
    scenario_chs << 'DOE Prototype Building with changes above and new HVAC system'
    scenario_chs << 'Bar Sliced' # May start from prototype or empty seed model with same simulation settings
    scenario_chs << 'Bar Blended Core and Perimeter'
    scenario_chs << 'Footprint Blended Single Space per Story' # May be whole building blend or, blend by story
    #scenario_chs << 'Prototype Geometry Blended' # whole building blended space type applied to prototype geometry, every thing other than geometry should be removed and rebuilt
    #scenario_chs << 'Footprint Blended Core and Perimeter'
    scenario = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('scenario', scenario_chs, true)
    scenario.setDisplayName('Model Articulation Scenario.')
    scenario.setDescription("This choice will determine which measrues will run and may also alter argument values for those measures.")
    scenario.setDefaultValue('DOE Prototype Building')
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

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # save new osw
    new_workflow_path = 'output/new_workflow.osw'
    new_workflow_path = File.absolute_path(new_workflow_path)
    runner.workflow.saveAs(new_workflow_path)

    # load the new workflows
    new_osw = nil
    File.open(new_workflow_path, 'r') do |f|
      new_osw = JSON::parse(f.read, :symbolize_names => true)
    end

    # map scenarios to integers
    scenario_hash = {}
    scenario_hash['DOE Prototype Building'] = 0
    scenario_hash['DOE Prototype Building with new constructions'] = 1
    scenario_hash['DOE Prototype Building with changes above and new loads, sch, and ext lights'] = 2
    scenario_hash['DOE Prototype Building with changes above and new swh and exhaust'] = 3
    scenario_hash['DOE Prototype Building with changes above and new thermostats'] = 4
    scenario_hash['DOE Prototype Building with changes above and new HVAC system'] = 5

    # loop through steps
    new_osw[:steps].each do |step|

      if step[:measure_dir_name] == "openstudio_model_articulation_testing_scenario_builder"
        step[:arguments][:__SKIP__] = true
      else
        runner.registerInfo("Inspecting #{step[:name]}")

        # change building type, temlpate, and climate zone
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

      # todo - add logic for which measures to skip for each scenario
      found_typical = false
      if step[:measure_dir_name] == "create_typical_building_from_model"

        if scenario_hash[scenario] > 0
          step[:arguments][:__SKIP__] = false

          if found_typical
            #add hvac
            if scenario_hash[scenario] >= 5
              step[:arguments][:add_hvac] = true
            else
              step[:arguments][:add_hvac] = false
            end
          else
            if scenario_hash[scenario] >= 1 then step[:arguments][:add_constructions] = true else step[:arguments][:add_constructions] = false end
            if scenario_hash[scenario] >= 2 then step[:arguments][:add_space_type_loads] = true else step[:arguments][:add_space_type_loads] = false end
            if scenario_hash[scenario] >= 2 then step[:arguments][:add_elevators] = true else step[:arguments][:add_elevators] = false end
            if scenario_hash[scenario] >= 2 then step[:arguments][:add_exterior_lights] = true else step[:arguments][:add_exterior_lights] = false end
            if scenario_hash[scenario] >= 3 then step[:arguments][:add_exhaust] = true else step[:arguments][:add_exhaust] = false end
            if scenario_hash[scenario] >= 3 then step[:arguments][:add_swh] = true else step[:arguments][:add_swh] = false end
            if scenario_hash[scenario] >= 4 then step[:arguments][:add_thermostat] = true else step[:arguments][:add_thermostat] = false end
            step[:arguments][:add_hvac] = false

            # set flag so next instance will be flagged to set HVAC if requested
            found_typical = true
          end

        else
          step[:arguments][:__SKIP__] = true
        end
      else
        # no catchall behavior
      end

    end

    # todo - map floor area and num stories above and below grade from bldg_type_a

    # todo - map climate zone and weather files if add change building location in vs. running prototptye first for bar and footprint workflows

    # update path to measures and seed model
    new_osw[:measure_paths] = ["../../../../measures"]
    new_osw[:file_paths] = ["../../../../seeds","../../../../weather"]

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
    runner.registerInfo("Finished Running OpenStudio CLI")

    # get the model out of the OSW
    new_model_path = 'output/run/in.osm'
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

    # todo - map info, warning, and error messages from out.osw
    # todo - when workflow fails now, PAT doesn't know things are done, I need to rescue that and have measure finish and fail

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")

    return true

  end
  
end

# register the measure to be used by the application
OpenStudioModelArticulationTestingScenarioBuilder.new.registerWithApplication
