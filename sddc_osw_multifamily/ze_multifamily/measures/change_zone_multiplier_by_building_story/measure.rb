# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ChangeZoneMultiplierByBuildingStory < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Change Zone Multiplier by Building Story'
  end

  # human readable description
  def description
    return 'This measure will loop through all spaces on user specified bulidng story and will increase the multiplier by a user suplied multiplier. Matched floor/ceiling surfaces with zones that no longer have the same boundary condition will be chagned to adiabaitc'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This will not just set the multiplier to the user specified value. Instead it will take the original value and multiplier it by the user specified value. So if the user specifed value is 2.0, and a zone started with a multiplier of 3.0 it would be changed to 6.0. A zone starting at 1.0 would chagne to 2.0. If a zone contains spaces from two different stories, including the user specified story the measure will error instead of attempting to change the zone multipliers. The measure will also error if the spaces on the selected story have any roofs or floors with exterior or ground exposure.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # populate choice argument for building stories
    building_story_handles = OpenStudio::StringVector.new
    building_story_display_names = OpenStudio::StringVector.new

    # putting space types and names into hash
    building_story_args = model.getBuildingStorys
    building_story_args_hash = {}
    building_story_args.each do |building_story_arg|
      building_story_args_hash[building_story_arg.name.to_s] = building_story_arg
    end

    # looping through sorted hash of building_stories
    building_story_args_hash.sort.map do |key, value|
      # only include if building_story is used on surface
      if value.spaces.size > 0
        building_story_handles << value.handle.to_s
        building_story_display_names << key
      end
    end

    # make an argument for building_story
    building_story = OpenStudio::Measure::OSArgument.makeChoiceArgument('building_story', building_story_handles, building_story_display_names, true)
    building_story.setDisplayName('Choose a building story to alter zone multipliers for.')
    args << building_story

    # make an argument for material and installation cost
    multiplier_adj = OpenStudio::Measure::OSArgument.makeIntegerArgument('multiplier_adj', true)
    multiplier_adj.setDisplayName('Thermal zone multiplier adjustment')
    multiplier_adj.setDescription('The existing thermal zone multiplier for zones that contain spaces on this story will be multiplied by this value.')
    multiplier_adj.setDefaultValue(2)
    args << multiplier_adj

    # todo - add in optional argument to vertically move model elements to reflect the multiplier

    # todo - there is another measure that can infill shading surfaces for non-rectangular buildings. That functionality could be added here, or the other measure could be called after this.

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
    building_story = runner.getOptionalWorkspaceObjectChoiceValue('building_story', user_arguments, model)
    multiplier_adj = runner.getIntegerArgumentValue('multiplier_adj', user_arguments)

    # check the building_story for reasonableness
    if building_story.empty?
      handle = runner.getStringArgumentValue('building_story', user_arguments)
      if handle.empty?
        runner.registerError('No building_story was chosen.')
      else
        runner.registerError("The selected building_story with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if !building_story.get.to_BuildingStory.empty?
        building_story = building_story.get.to_BuildingStory.get
      else
        runner.registerError('Script Error - argument not showing up as building story.')
        return false
      end
    end

    # inspect building selected story, spaces, and zones
    if building_story.spaces.size == 0
      runner.registerNotApplicable("The selected story does not contain any spaces or thermal zones")
      return true
    end
    thermal_zones = {}
    building_stories = []
    building_story.spaces.each do |space|
      if !space.thermalZone.empty?
        thermal_zones[space.thermalZone.get] = space.thermalZone.get.multiplier
        space.thermalZone.get.spaces.each do |zone_space|
          if !zone_space.buildingStory.empty?
            building_stories << zone_space.buildingStory.get
          end
        end
      else
        runner.registerWarning("#{space.name} is on #{building_story.name} but does not contain a thermal zone, it will not be impacted by this measure.")
      end
    end
    # stop measure if the select building story doesn't have any spaces
    if building_stories.size == 0
      runner.registerAsNotApplicable("None of the spaces on the selected story contain any thermal zones.")
      return true
    end

    # stop measure if any zones that have spaces on selected building story straddle building stories
    if building_stories.uniq.size > 1
      runner.registerError('One or more thermal zones that contain spaces on this building story also contain spaces on other building stories. The measure can not properly run on this model.')
      return false
    end

    # report initial condition of model
    final_multiplier = []
    runner.registerInitialCondition("#{building_story.name} started with thermal zone multipliers ranging from #{thermal_zones.values.min} to #{thermal_zones.values.max}.")

      thermal_zones.each do |thermal_zone,multiplier|

        # change multipliers
        target_multiplier = multiplier * multiplier_adj
        final_multiplier << target_multiplier
        runner.registerInfo("Changing multiplier for #{thermal_zone.name} from #{multiplier} to #{target_multiplier}.")
        thermal_zone.setMultiplier(target_multiplier)

        thermal_zone.spaces.each do |space|
          runner.registerInfo("Changing boundary condition of floors and ceilings in and adjacent to space #{space.name} to adiabatic.")
          space.surfaces.each do |surface|

            next if !["Floor","RoofCeiling"].include?(surface.surfaceType.to_s)

            if surface.outsideBoundaryCondition == "Outdoors" || surface.outsideBoundaryCondition == "Ground"
              runner.registerError("One or more roof or floor surfaces on the selected building story have ground or exterior exposure. The measure can not properly run on this model.")
              return false
            end

            # hard assign construction for surfaces and adjacent surfaces
            if !surface.construction.empty?
              surface.setConstruction(surface.construction.get)
            end
            if !surface.adjacentSurface.empty? && !surface.adjacentSurface.get.construction.empty?
              surface.adjacentSurface.get.setConstruction(surface.adjacentSurface.get.construction.get)
            end

            # change boundary condition of surfaces an adjacent surfaces
            if !surface.adjacentSurface.empty?
              surface.adjacentSurface.get.setOutsideBoundaryCondition("Adiabatic")
            end
            surface.setOutsideBoundaryCondition("Adiabatic")
          end
        end

      end

    # report final condition of model
    runner.registerFinalCondition("#{building_story.name} finished with thermal zone multipliers ranging from #{final_multiplier.min} to #{final_multiplier.max}.")

    return true
  end
end

# register the measure to be used by the application
ChangeZoneMultiplierByBuildingStory.new.registerWithApplication
