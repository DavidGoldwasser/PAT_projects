# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# load helper
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"

# start the measure
class AddElectricEquipmentInstanceToSpace < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Add Electric Equipment Instance to Space"
  end

  # human readable description
  def description
    return "This measure allows you to create new electric equipment instance and assign it directly to a space in the model. It requires that the schedule and electric equipment definition already exist in the model. Additionally it has arguments for target space and multiplier"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Example use case is adding special loads like an elevator to a model as part of an analysis workflow"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # make argument for space
    space = OpenStudio::Ruleset::makeChoiceArgumentOfWorkspaceObjects("space","OS_Space".to_IddObjectType,model,true)
    space.setDisplayName("Select Space for Load Instance")
    args << space

    # make argument for definition
    elec_equip_def = OpenStudio::Ruleset::makeChoiceArgumentOfWorkspaceObjects("elec_equip_def","OS_ElectricEquipment_Definition".to_IddObjectType,model,true)
    elec_equip_def.setDisplayName("Select Electric Equipment Definition")
    args << elec_equip_def

    # make argument for schedule
    # todo - setup so only shows fractional schedules, and with any kind of schedule OS_Schedule
    schedule = OpenStudio::Ruleset::makeChoiceArgumentOfWorkspaceObjects("schedule","OS_Schedule_Ruleset".to_IddObjectType,model,true)
    schedule.setDisplayName("Select Fractional Schedule")
    args << schedule

    # make argument for multiplier
    multiplier = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("multiplier", true)
    multiplier.setDisplayName("Load Instance Multiplier")
    multiplier.setDescription("Identify the number of these load objects to add to the space.")
    multiplier.setDefaultValue(1)
    args << multiplier

    # todo - add argument for fraction of load lost (for traction elevators)

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
    space = runner.getOptionalWorkspaceObjectChoiceValue('space',user_arguments, model)
    elec_equip_def = runner.getOptionalWorkspaceObjectChoiceValue('elec_equip_def',user_arguments, model)
    schedule = runner.getOptionalWorkspaceObjectChoiceValue('schedule',user_arguments, model)
    multiplier = runner.getDoubleArgumentValue("multiplier", user_arguments)

    # check arguments for reasonableness
    space = OsLib_HelperMethods.checkOptionalChoiceArgFromModelObjects(space, "elec_equip_def","to_Space", runner, user_arguments)
    if space == false then return false else space = space["modelObject"] end
    elec_equip_def = OsLib_HelperMethods.checkOptionalChoiceArgFromModelObjects(elec_equip_def, "elec_equip_def","to_ElectricEquipmentDefinition", runner, user_arguments)
    if elec_equip_def == false then return false else elec_equip_def = elec_equip_def["modelObject"] end
    schedule = OsLib_HelperMethods.checkOptionalChoiceArgFromModelObjects(schedule, "elec_equip_def","to_Schedule", runner, user_arguments)
    if schedule == false then return false else schedule = schedule["modelObject"] end
    if multiplier <= 0
      runner.registerError("Please choose a multiplier value greater than 0")
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getElectricEquipments.size} electric equipment instances.")

    # create and populate instance
    elec_equip = OpenStudio::Model::ElectricEquipment.new(elec_equip_def)
    elec_equip.setSpace(space)
    elec_equip.setSchedule(schedule)
    elec_equip.setMultiplier(multiplier)

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getElectricEquipments.size} electric equipment instances.")

    return true

  end
  
end

# register the measure to be used by the application
AddElectricEquipmentInstanceToSpace.new.registerWithApplication
