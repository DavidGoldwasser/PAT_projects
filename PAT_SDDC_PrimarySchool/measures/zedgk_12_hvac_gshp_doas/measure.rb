#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"
require "#{File.dirname(__FILE__)}/resources/OsLib_HVAC_zedg_gshp"
require "#{File.dirname(__FILE__)}/resources/os_lib_schedules"
require "#{File.dirname(__FILE__)}/resources/TableLib"

#start the measure
class ZEDGK12HVAC < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ZEDG K12 HVAC GSHP with DOAS"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # create an argument for a space type to be used in the model, to see if one should be mapped as ceiling return air plenum
    spaceTypes = model.getSpaceTypes
    usedSpaceTypes_handle = OpenStudio::StringVector.new
    usedSpaceTypes_displayName = OpenStudio::StringVector.new
    spaceTypes.each do |spaceType|  #todo - I need to update this to use helper so GUI sorts by display name
      if spaceType.spaces.size > 0 # only show space types used in the building
        usedSpaceTypes_handle << spaceType.handle.to_s
        usedSpaceTypes_displayName << spaceType.name.to_s
      end
    end

    # make an argument for space type
    ceilingReturnPlenumSpaceType = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("ceilingReturnPlenumSpaceType", usedSpaceTypes_handle, usedSpaceTypes_displayName,false)
    ceilingReturnPlenumSpaceType.setDisplayName("This space type should be part of a ceiling return air plenum.")
    #ceilingReturnPlenumSpaceType.setDefaultValue("We don't want a default, this is an optional argument")
    args << ceilingReturnPlenumSpaceType

    # make an argument for material and installation cost
    # todo - I would like to split the costing out to the air loops weighted by area of building served vs. just sticking it on the building
    costTotalHVACSystem = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("costTotalHVACSystem",true)
    costTotalHVACSystem.setDisplayName("Total Cost for HVAC System ($).")
    costTotalHVACSystem.setDefaultValue(0.0)
    args << costTotalHVACSystem
    
    #make an argument to remove existing costs
    remake_schedules = OpenStudio::Ruleset::OSArgument::makeBoolArgument("remake_schedules",true)
    remake_schedules.setDisplayName("Apply recommended availability and ventilation schedules for air handlers?")
    remake_schedules.setDefaultValue(true)
    args << remake_schedules

    return args
  end

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    ### START INPUTS
    #assign the user inputs to variables
    ceilingReturnPlenumSpaceType = runner.getOptionalWorkspaceObjectChoiceValue("ceilingReturnPlenumSpaceType",user_arguments,model)
    costTotalHVACSystem = runner.getDoubleArgumentValue("costTotalHVACSystem",user_arguments)
    remake_schedules = runner.getBoolArgumentValue("remake_schedules",user_arguments)
    # check that spaceType was chosen and exists in model
    ceilingReturnPlenumSpaceTypeCheck = OsLib_HelperMethods.checkOptionalChoiceArgFromModelObjects(ceilingReturnPlenumSpaceType, "ceilingReturnPlenumSpaceType","to_SpaceType", runner, user_arguments)
    if ceilingReturnPlenumSpaceTypeCheck == false then return false else ceilingReturnPlenumSpaceType = ceilingReturnPlenumSpaceTypeCheck["modelObject"] end
    # default building/ secondary space types
    standardBuildingTypeTest = ["PrimarySchool","SecondarySchool"] #ML Not used yet
    secondarySpaceTypeTest = ["Cafeteria", "Kitchen", "Gym", "Auditorium"]
    primarySpaceType = "Classroom" # todo - why aren't all primary space types listed? Maybe only important that not in secondary list
    primaryHVAC = {"doas" => true, "fan" => "Variable", "heat" => "wahpv", "cool" => "wahpv", "unitary" => true}
    secondaryHVAC = {"fan" => "Constant", "heat" => "Gas", "cool" => "SingleDX", "unitary" => true}
    zoneHVAC = "GSHP"
    chillerType = "AirCooled" #set to none if chiller not used
    radiantChillerType = "None" #set to none if not radiant system
    allHVAC = {"primary" => primaryHVAC,"secondary" => secondaryHVAC,"zone" => zoneHVAC}
    ### END INPUTS
  
    ### START SORT ZONES
    options = {"standardBuildingTypeTest" => standardBuildingTypeTest, #ML Not used yet
               "secondarySpaceTypeTest" => secondarySpaceTypeTest,
               "ceilingReturnPlenumSpaceType" => ceilingReturnPlenumSpaceType}
    zonesSorted = OsLib_HVAC_zedg_gshp.sortZones(model, runner, options)
    zonesPrimary = zonesSorted["zonesPrimary"]
    zonesSecondary = zonesSorted["zonesSecondary"]
    zonesPlenum = zonesSorted["zonesPlenum"]
    zonesUnconditioned = zonesSorted["zonesUnconditioned"]
    ### END SORT ZONES
    
    ### START REPORT INITIAL CONDITIONS
    OsLib_HVAC_zedg_gshp.reportConditions(model, runner, "initial")
    ### END REPORT INITIAL CONDITIONS

    ### START ASSIGN HVAC SCHEDULES
    options = {"primarySpaceType" => primarySpaceType,
               "allHVAC" => allHVAC,
               "remake_schedules" => remake_schedules}
    schedulesHVAC = OsLib_HVAC_zedg_gshp.assignHVACSchedules(model, runner, options)
    # assign schedules
    primary_SAT_schedule = schedulesHVAC["primary_sat"]
    building_HVAC_schedule = schedulesHVAC["hvac"]
    building_ventilation_schedule = schedulesHVAC["ventilation"]
    make_hot_water_plant = false
    unless schedulesHVAC["hot_water"].nil?
      hot_water_setpoint_schedule = schedulesHVAC["hot_water"]
      make_hot_water_plant = true
    end
    make_chilled_water_plant = false
    unless schedulesHVAC["chilled_water"].nil?
      chilled_water_setpoint_schedule = schedulesHVAC["chilled_water"]
      make_chilled_water_plant = true
    end
    make_radiant_hot_water_plant = false
    unless schedulesHVAC["radiant_hot_water"].nil?
      radiant_hot_water_setpoint_schedule = schedulesHVAC["radiant_hot_water"]
      make_radiant_hot_water_plant = true
    end
    make_radiant_chilled_water_plant = false
    unless schedulesHVAC["radiant_chilled_water"].nil?
      radiant_chilled_water_setpoint_schedule = schedulesHVAC["radiant_chilled_water"]
      make_radiant_chilled_water_plant = true
    end
    unless schedulesHVAC["hp_loop"].nil?
      heat_pump_loop_setpoint_schedule = schedulesHVAC["hp_loop"]
    end
    unless schedulesHVAC["hp_loop_cooling"].nil?
      heat_pump_loop_cooling_setpoint_schedule = schedulesHVAC["hp_loop_cooling"]
    end
    unless schedulesHVAC["hp_loop_heating"].nil?
      heat_pump_loop_heating_setpoint_schedule = schedulesHVAC["hp_loop_heating"]
    end
    unless schedulesHVAC["mean_radiant_heating"].nil?
      mean_radiant_heating_setpoint_schedule = schedulesHVAC["mean_radiant_heating"]
    end
    unless schedulesHVAC["mean_radiant_cooling"].nil?
      mean_radiant_cooling_setpoint_schedule = schedulesHVAC["mean_radiant_cooling"]
    end
    ### END ASSIGN HVAC SCHEDULES
    
    ### START REMOVE EQUIPMENT
    OsLib_HVAC_zedg_gshp.removeEquipment(model, runner)
    ### END REMOVE EQUIPMENT
    
    ### START CREATE NEW PLANTS
    # create new plants
    # hot water plant
    if make_hot_water_plant
      hot_water_plant = OsLib_HVAC_zedg_gshp.createHotWaterPlant(model, runner, hot_water_setpoint_schedule, "Hot Water")
    end
    # chilled water plant
    if make_chilled_water_plant
      chilled_water_plant = OsLib_HVAC_zedg_gshp.createChilledWaterPlant(model, runner, chilled_water_setpoint_schedule, "Chilled Water", chillerType)
    end
    # radiant hot water plant
    if make_radiant_hot_water_plant
      radiant_hot_water_plant = OsLib_HVAC_zedg_gshp.createHotWaterPlant(model, runner, radiant_hot_water_setpoint_schedule, "Radiant Hot Water")
    end
    # chilled water plant
    if make_radiant_chilled_water_plant
      radiant_chilled_water_plant = OsLib_HVAC_zedg_gshp.createChilledWaterPlant(model, runner, radiant_chilled_water_setpoint_schedule, "Radiant Chilled Water", radiantChillerType)
    end
    # condenser loop
    # need condenser loop if there is a water-cooled chiller or if there is a water source heat pump loop
    options = {}
    options["zoneHVAC"] = zoneHVAC
    if zoneHVAC == "WSHP" or zoneHVAC == "GSHP"
      options["loop_setpoint_schedule"] = heat_pump_loop_setpoint_schedule
      options["cooling_setpoint_schedule"] = heat_pump_loop_cooling_setpoint_schedule
      options["heating_setpoint_schedule"] = heat_pump_loop_heating_setpoint_schedule
    end  
    condenserLoops = OsLib_HVAC_zedg_gshp.createCondenserLoop(model, runner, options)
    unless condenserLoops["condenser_loop"].nil?
      condenser_loop = condenserLoops["condenser_loop"]
    end
    make_heat_pump_loop = false
    unless condenserLoops["heat_pump_loop"].nil?
      heat_pump_loop = condenserLoops["heat_pump_loop"]
      make_heat_pump_loop = true
    end
    ### END CREATE NEW PLANTS

    ### START CREATE PRIMARY ZONE EQUIPMENT
    options = {}
    options["zonesPrimary"] = zonesPrimary
    options["zoneHVAC"] = zoneHVAC
    if make_hot_water_plant
      options["hot_water_plant"] = hot_water_plant
    end
    if make_chilled_water_plant
      options["chilled_water_plant"] = chilled_water_plant
    end
    if zoneHVAC == "WSHP" or zoneHVAC == "GSHP"
      options["heat_pump_loop"] = heat_pump_loop
    end
    if zoneHVAC == "DualDuct"
      options["ventilation_schedule"] = building_ventilation_schedule
    end
    if zoneHVAC == "Radiant"
      options["radiant_hot_water_plant"] = radiant_hot_water_plant
      options["radiant_chilled_water_plant"] = radiant_chilled_water_plant
      options["mean_radiant_heating_setpoint_schedule"] = mean_radiant_heating_setpoint_schedule
      options["mean_radiant_cooling_setpoint_schedule"] = mean_radiant_cooling_setpoint_schedule
    end
    OsLib_HVAC_zedg_gshp.createPrimaryZoneEquipment(model, runner, options)
    ### END CREATE PRIMARY ZONE EQUIPMENT

    ### START CREATE PRIMARY AIRLOOPS
    # populate inputs hash for create primary airloops method
    options = {}
    options["zonesPrimary"] = zonesPrimary
    options["primaryHVAC"] = primaryHVAC
    options["zoneHVAC"] = zoneHVAC
    if primaryHVAC["doas"]
      options["hvac_schedule"] = building_ventilation_schedule
      options["ventilation_schedule"] = building_ventilation_schedule
    else
      # primary HVAC is multizone VAV
      unless zoneHVAC == "DualDuct"
        # primary system is multizone VAV that cools and ventilates
        options["hvac_schedule"] = building_HVAC_schedule
        options["ventilation_schedule"] = building_ventilation_schedule
      else
        # primary system is a multizone VAV that cools only (primary system ventilation schedule is set to always off; hvac set to always on)
        options["hvac_schedule"] = model.alwaysOnDiscreteSchedule()
      end
    end
    options["primary_sat_schedule"] = primary_SAT_schedule
    if make_hot_water_plant
      options["hot_water_plant"] = hot_water_plant
    end
    if make_chilled_water_plant
      options["chilled_water_plant"] = chilled_water_plant
    end
    if make_heat_pump_loop
      options["heat_pump_loop"] = heat_pump_loop
    end
    primary_airloops = OsLib_HVAC_zedg_gshp.createPrimaryAirLoops(model, runner, options)
    ### END CREATE PRIMARY AIRLOOPS
    
    ### START CREATE SECONDARY AIRLOOPS
    # populate inputs hash for create primary airloops method
    # todo - set this up to take unitary system
    options = {}
    options["zonesSecondary"] = zonesSecondary
    options["secondaryHVAC"] = secondaryHVAC
    options["hvac_schedule"] = building_HVAC_schedule
    options["ventilation_schedule"] = building_ventilation_schedule
    if make_hot_water_plant
      options["hot_water_plant"] = hot_water_plant
    end
    if make_chilled_water_plant
      options["chilled_water_plant"] = chilled_water_plant
    end
    if make_heat_pump_loop
      options["heat_pump_loop"] = heat_pump_loop
    end
    secondary_airloops = OsLib_HVAC_zedg_gshp.createSecondaryAirLoops(model, runner, options)
    ### END CREATE SECONDARY AIRLOOPS
    
    ### START ASSIGN PLENUMS
    options = {"zonesPrimary" => zonesPrimary,"zonesPlenum" => zonesPlenum}
    zone_plenum_hash = OsLib_HVAC_zedg_gshp.validateAndAddPlenumZonesToSystem(model, runner, options)
    ### END ASSIGN PLENUMS
    
    # START ADD DCV
    options = {}
    unless zoneHVAC == "DualDuct"
      options["primary_airloops"] = primary_airloops
    end
    options["secondary_airloops"] = secondary_airloops
    options["allHVAC"] = allHVAC
    OsLib_HVAC_zedg_gshp.addDCV(model, runner, options)

    options = {}
    options["secondary_airloops"] = secondary_airloops
    options["allHVAC"] = allHVAC
    OsLib_HVAC_zedg_gshp.addDCV(model, runner, options)

    # END ADD DCV
       
    # add in lifecycle costs
    expected_life = 25
    years_until_costs_start = 0
    costHVAC = costTotalHVACSystem
    lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("HVAC System", model.getBuilding, costHVAC, "CostPerEach", "Construction", expected_life, years_until_costs_start).get

    # todo - add EMS
    # totod - test ems in run before commit
    plant_component_temperature_source = model.getPlantComponentTemperatureSources.first
    inlet_port = plant_component_temperature_source.inletModelObject.get # todo - confirm this exists
    schedule = plant_component_temperature_source.sourceTemperatureSchedule.get # todo - confirm this exists
    runner.registerInfo("Adding Plant Component Temperature Source EMS code for #{plant_component_temperature_source.name}")

    # add output variable
    outputVariable = OpenStudio::Model::OutputVariable.new("System Node Temperature",model)
    outputVariable.setReportingFrequency("Hourly")
    outputVariable.setKeyValue(plant_component_temperature_source.name.get)

    # add sensor
    sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "System Node Temperature")
    sensor.setKeyName(inlet_port.name.get)
    sensor.setName("Ground_HX_Inlet_Temp")

    # add actuator
    actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(schedule,"Schedule:Constant","Schedule Value")
    actuator.setName("Ground_HX_Schedule_Actuator")

    # add program
    control_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    control_program.setName("Ground HX")
    control_program.addLine("SET Tin = Ground_HX_Inlet_Temp")
    control_program.addLine("IF Tin < 15.556")
    control_program.addLine("SET Tout = Tin + 5.556")
    control_program.addLine("ELSE")
    control_program.addLine("SET Tout = Tin - 5.556")
    control_program.addLine("ENDIF")
    control_program.addLine("SET Ground_HX_Schedule_Actuator = Tout")

    # add program calling manager
    pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    pcm.setName("Ground HX")
    pcm.setCallingPoint("InsideHVACSystemIterationLoop")
    pcm.addProgram(control_program)

    ### START REPORT FINAL CONDITIONS
    OsLib_HVAC_zedg_gshp.reportConditions(model, runner, "final")
    ### END REPORT FINAL CONDITIONS

    return true

  end

end

#this allows the measure to be used by the application
ZEDGK12HVAC.new.registerWithApplication