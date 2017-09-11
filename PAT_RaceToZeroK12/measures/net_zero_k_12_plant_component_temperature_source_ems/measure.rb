# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class NetZeroK12PlantComponentTemperatureSourceEMS < OpenStudio::Ruleset::WorkspaceUserScript

  # human readable name
  def name
    return "Net Zero K12 Plant Component Temperature Source EMS"
  end

  # human readable description
  def description
    return "This measure is meant to be paired with the Net Zero K12 HVAC measure to add EMS in place of a ground source loop."
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure will get the last OSM and then find the inlet node for the Plant component Temperature Source object. It will then create EMS to schedule the temperature."
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end 

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # reporting initial condition of model
    runner.registerInitialCondition("The building started with #{workspace.objects.size} objects.")

    # Get the last openstudio model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Could not load last OpenStudio model, cannot apply measure.")
      return false
    end
    model = model.get

    plant_component_temperature_source = model.getPlantComponentTemperatureSources.first
    inlet_port = plant_component_temperature_source.inletModelObject.get # todo - confirm this exists
    schedule = plant_component_temperature_source.sourceTemperatureSchedule.get # todo - confirm this exists

    string_objects = []

    string_objects << "
    Output:Variable,
      #{inlet_port.name},                   !- Key Value
      System Node Temperature,              !- Variable Name
      Hourly;                               !- Reporting Frequency
    "

    string_objects << "
    EnergyManagementSystem:Sensor,
      Ground_HX_Inlet_Temp,                   !- Name
      #{inlet_port.name},                     !- Output:Variable or Output:Meter Index Key Name
      System Node Temperature;                !- Output:Variable or Output:Meter Name
    "

    string_objects << "
    EnergyManagementSystem:Actuator,
      Ground_HX_Schedule_Actuator,            !- Name
      #{schedule.name},                       !- Actuated Component Unique Name
      Schedule:Constant,                      !- Actuated Component Type
      Schedule Value;                         !- Actuated Component Control Type
    "

    string_objects << "
    EnergyManagementSystem:Program,
      Ground_HX,                              !- Name
      SET Tin = Ground_HX_Inlet_Temp,         !- Program Line 1
      IF Tin < 15.556,                        !- Program Line 2
      SET Tout = Tin + 5.556,                 !- Program Line 3
      ELSE,                                   !- Program Line 4
      SET Tout = Tin - 5.556,                 !- Program Line 5
      ENDIF,                                  !- Program Line 6
      SET Ground_HX_Schedule_Actuator = Tout; !- Program Line 7
    "

    string_objects << "
    EnergyManagementSystem:ProgramCallingManager,
      Ground HX,                              !- Name
      InsideHVACSystemIterationLoop,          !- EnergyPlus Model Calling Point
      Ground_HX;                              !- Program Name 1
    "

    # add all of the strings to workspace
    string_objects.each do |string_object|
      idfObject = OpenStudio::IdfObject::load(string_object)
      object = idfObject.get
      wsObject = workspace.addObject(object)
    end

    # report final condition of model
    runner.registerFinalCondition("The finished started with #{workspace.objects.size} objects.")
    
    return true
 
  end

end 

# register the measure to be used by the application
NetZeroK12PlantComponentTemperatureSourceEMS.new.registerWithApplication
