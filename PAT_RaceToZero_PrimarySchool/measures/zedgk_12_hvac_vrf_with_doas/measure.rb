#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
#require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"
require "#{File.dirname(__FILE__)}/resources/OsLib_HVAC_zedg_vrf"
require "#{File.dirname(__FILE__)}/resources/os_lib_schedules"

#start the measure
class ZEDGVRFWithDOAS < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ZEDG VRF with DOAS"
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

=begin
    # VRF Condenser Type
		condenserChs = OpenStudio::StringVector.new
		# condenserChs << "WaterCooled"
		# condenserChs << "EvaporativelyCooled"
		condenserChs << "AirCooled"
		vrfCondenserType = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("vrfCondenserType",condenserChs,true)
		vrfCondenserType.setDisplayName("VRF Condenser Type")
		vrfCondenserType.setDefaultValue("AirCooled")
		args<<vrfCondenserType
					
		#Cooling COP of VRF
		vrfCoolCOP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("vrfCoolCOP",false)
		vrfCoolCOP.setDisplayName("VRF Rated Cooling COP (Not Including Supply Fan)")
		vrfCoolCOP.setDefaultValue(4.0)
		args << vrfCoolCOP
		
		#Heating COP of VRF
		vrfHeatCOP = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("vrfHeatCOP",false)
		vrfHeatCOP.setDisplayName("VRF Rated Heating COP (Not Including Supply Fan)")
		vrfHeatCOP.setDefaultValue(4.0)
		args << vrfHeatCOP

		#Minimum Outdoor Temperature in Heating Mode
		vrfMinOATHPHeat = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("vrfMinOATHPHeat",false)
		vrfMinOATHPHeat.setDisplayName("Minimum Outdoor Temperature in Heat Pump Heating Mode (F)")
		vrfMinOATHPHeat.setDefaultValue(-4.0)
		args<< vrfMinOATHPHeat
		
		# Defrost Strategy		
		defrostChs = OpenStudio::StringVector.new
		# defrostChs << "ReverseCycle"
		defrostChs << "Resistive"
		vrfDefrost = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("vrfDefrost",defrostChs,true)
		vrfDefrost.setDisplayName("Defrost Strategy")
		vrfDefrost.setDefaultValue("Resistive")
		args << vrfDefrost
		
		# Heat Pump Waste Heat Recovery
		chs = OpenStudio::StringVector.new
		chs << "Yes"
		chs << "No"
		vrfHPHeatRecovery = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("vrfHPHeatRecovery",chs,true)
		vrfHPHeatRecovery.setDisplayName("Heat Pump Waste Heat Recovery")
		vrfHPHeatRecovery.setDefaultValue("Yes")
		args << vrfHPHeatRecovery
		
		# Equivalent Piping Length used for Piping Correction Factor in Cooling and Heating Mode
		vrfEquivPipingLength = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("vrfEquivPipingLength",false)
		vrfEquivPipingLength.setDisplayName("Equivalent Piping Length Used for Piping Correction Factor (ft)")
		vrfEquivPipingLength.setDefaultValue(100.0)
		args << vrfEquivPipingLength
		
		# Vertical Height Used for Piping Correction Factor
		vrfPipingHeight = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("vrfPipingHeight",false)
		vrfPipingHeight.setDisplayName("Vertical Height used for Piping Correction Factor (ft)")
		vrfPipingHeight.setDefaultValue(35.0)
		args << vrfPipingHeight
	
		# DOAS Fan Type
		doasFanChs = OpenStudio::StringVector.new
		doasFanChs << "Constant"
		doasFanChs << "Variable"
		doasFanType = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("doasFanType",doasFanChs,true)
		doasFanType.setDisplayName("DOAS Fan Flow Control - Variable means DCV controls")
		doasFanType.setDefaultValue("Variable")
		args << doasFanType
		
		# DOAS Energy Recovery
		ervChs = OpenStudio::StringVector.new
		ervChs << "plate w/o economizer lockout"
		ervChs << "plate w/ economizer lockout"
		ervChs << "rotary wheel w/o economizer lockout"
    ervChs << "rotary wheel w/ economizer lockout"
    ervChs << "plate w/o economizer lockout - zedg"
		ervChs << "none"
		doasERV = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("doasERV",ervChs,true)
		doasERV.setDisplayName("DOAS Energy Recovery?")
		doasERV.setDefaultValue("plate w/o economizer lockout - zedg")
		args << doasERV
		
		# DOAS Evaporative Cooling
		evapChs = OpenStudio::StringVector.new
		evapChs << "Direct Evaporative Cooler"
		evapChs << "none"
		doasEvap = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("doasEvap",evapChs,true)
		doasEvap.setDisplayName("DOAS Direct Evaporative Cooling ?")
		doasEvap.setDefaultValue("none")
		args << doasEvap
		
		# DOAS DX Cooling
		doasDXEER = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("doasDXEER",false)
		doasDXEER.setDisplayName("DOAS DX Cooling EER")
		doasDXEER.setDefaultValue(10.0)
		args << doasDXEER
=end
		
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
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

=begin
	  vrfCondenserType = runner.getStringArgumentValue("vrfCondenserType",user_arguments)
		vrfCoolCOP = runner.getDoubleArgumentValue("vrfCoolCOP",user_arguments)
		vrfHeatCOP = runner.getDoubleArgumentValue("vrfHeatCOP",user_arguments)
		vrfMinOATHPHeat = runner.getDoubleArgumentValue("vrfMinOATHPHeat",user_arguments)
		vrfDefrost = runner.getStringArgumentValue("vrfDefrost",user_arguments)
		vrfHPHeatRecovery = runner.getStringArgumentValue("vrfHPHeatRecovery",user_arguments)
		vrfEquivPipingLength = runner.getDoubleArgumentValue("vrfEquivPipingLength",user_arguments)
		vrfPipingHeight = runner.getDoubleArgumentValue("vrfPipingHeight",user_arguments)
		doasFanType = runner.getStringArgumentValue("doasFanType",user_arguments)
		doasERV = runner.getStringArgumentValue("doasERV",user_arguments)
		doasEvap = runner.getStringArgumentValue("doasEvap",user_arguments)
		doasDXEER = runner.getDoubleArgumentValue("doasDXEER",user_arguments)
=end

    # hard coded default values from old measure arguments
    vrfCondenserType = "AirCooled"
    vrfCoolCOP = 4.0
    vrfHeatCOP = 4.0
    vrfMinOATHPHeat = -4.0
    vrfDefrost = "Resistive"
    vrfHPHeatRecovery = "Yes"
    vrfEquivPipingLength = 100.0
    vrfPipingHeight = 35.0
    doasFanType = "Variable"
    doasERV = "plate w/o economizer lockout - zedg"
    doasEvap = "none"
    doasDXEER = 10.0

	  parameters ={"vrfCondenserType" => vrfCondenserType,
									"vrfCoolCOP" => vrfCoolCOP,
									"vrfHeatCOP" => vrfHeatCOP,
									"vrfMinOATHPHeat" => vrfMinOATHPHeat,
									"vrfDefrost" => vrfDefrost,
									"vrfHPHeatRecovery" => vrfHPHeatRecovery,
									"vrfEquivPipingLength" => vrfEquivPipingLength,
									"vrfPipingHeight" => vrfPipingHeight,
									"doasFanType" => doasFanType,
									"doasERV" => doasERV,
									"doasEvap" => doasEvap,
									"doasDXEER" => doasDXEER}
									
									
    ### START INPUTS
    #assign the user inputs to variables
    ceilingReturnPlenumSpaceType = runner.getOptionalWorkspaceObjectChoiceValue("ceilingReturnPlenumSpaceType",user_arguments,model)
    costTotalHVACSystem = runner.getDoubleArgumentValue("costTotalHVACSystem",user_arguments)
    remake_schedules = runner.getBoolArgumentValue("remake_schedules",user_arguments)
    # check that spaceType was chosen and exists in model
    ceilingReturnPlenumSpaceTypeCheck = OsLib_HelperMethods.checkOptionalChoiceArgFromModelObjects(ceilingReturnPlenumSpaceType, "ceilingReturnPlenumSpaceType","to_SpaceType", runner, user_arguments)
    if ceilingReturnPlenumSpaceTypeCheck == false then return false else ceilingReturnPlenumSpaceType = ceilingReturnPlenumSpaceTypeCheck["modelObject"] end
    # default building/ secondary space types
    standardBuildingTypeTest = [] #ML Not used yet
    secondarySpaceTypeTest = ["Cafeteria", "Kitchen", "Gym", "Auditorium"]
    primarySpaceType = "Office"
		if doasFanType == "Variable"
			primaryHVAC = {"doas" => true, "fan" => "Variable", "heat" => "SingleDX", "cool" => "TwoSpeedDX"}
		else
			primaryHVAC = {"doas" => true, "fan" => "Constant", "heat" => "Gas", "cool" => "SingleDX"}
		end
    secondaryHVAC = {"fan" => "None", "heat" => "None", "cool" => "None"} #ML not used for office; leave or empty?
    zoneHVAC = "VRF"
    chillerType = "None" #set to none if chiller not used
    radiantChillerType = "None" #set to none if not radiant system
    allHVAC = {"primary" => primaryHVAC,"secondary" => secondaryHVAC,"zone" => zoneHVAC}

		
    ### END INPUTS
  
    ### START SORT ZONES
    options = {"standardBuildingTypeTest" => standardBuildingTypeTest, #ML Not used yet
               "secondarySpaceTypeTest" => secondarySpaceTypeTest,
               "ceilingReturnPlenumSpaceType" => ceilingReturnPlenumSpaceType}
    zonesSorted = OsLib_HVAC_zedg_vrf.sortZones(model, runner, options)
    zonesPrimary = zonesSorted["zonesPrimary"]
    zonesSecondary = zonesSorted["zonesSecondary"]
    zonesPlenum = zonesSorted["zonesPlenum"]
    zonesUnconditioned = zonesSorted["zonesUnconditioned"]
    ### END SORT ZONES
    
    ### START REPORT INITIAL CONDITIONS
    OsLib_HVAC_zedg_vrf.reportConditions(model, runner, "initial")
    ### END REPORT INITIAL CONDITIONS

    ### START ASSIGN HVAC SCHEDULES
    options = {"primarySpaceType" => primarySpaceType,
               "allHVAC" => allHVAC,
               "remake_schedules" => remake_schedules}
    schedulesHVAC = OsLib_HVAC_zedg_vrf.assignHVACSchedules(model, runner, options)
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
    
    # START REMOVE EQUIPMENT
		options = {}
		options["zonesPrimary"] = zonesPrimary
		if options["zonesPrimary"].empty?
			runner.registerInfo("User did not pick any zones to be added to VRF system, no changes to the model were made.")
 		else
			OsLib_HVAC_zedg_vrf.removeEquipment(model, runner, options)
		end
    ### END REMOVE EQUIPMENT
    
    ### START CREATE NEW PLANTS
    # create new plants
    # hot water plant
    if make_hot_water_plant
      hot_water_plant = OsLib_HVAC_zedg_vrf.createHotWaterPlant(model, runner, hot_water_setpoint_schedule, "Hot Water", parameters)
    end
    # chilled water plant
    if make_chilled_water_plant
      chilled_water_plant = OsLib_HVAC_zedg_vrf.createChilledWaterPlant(model, runner, chilled_water_setpoint_schedule, "Chilled Water", chillerType)
    end
    # radiant hot water plant
    if make_radiant_hot_water_plant
      radiant_hot_water_plant = OsLib_HVAC_zedg_vrf.createHotWaterPlant(model, runner, radiant_hot_water_setpoint_schedule, "Radiant Hot Water",parameters)
    end
    # chilled water plant
    if make_radiant_chilled_water_plant
      radiant_chilled_water_plant = OsLib_HVAC_zedg_vrf.createChilledWaterPlant(model, runner, radiant_chilled_water_setpoint_schedule, "Radiant Chilled Water", radiantChillerType)
    end
    # condenser loop
    # need condenser loop if there is a water-cooled chiller or if there is a water source heat pump loop or a water cooled VRF condenser
    options = {}
		options["zonesPrimary"] = zonesPrimary
    options["zoneHVAC"] = zoneHVAC
    if zoneHVAC.include? "SHP" or zoneHVAC == "VRF" and parameters["vrfCondenserType"] == "WaterCooled"
      options["loop_setpoint_schedule"] = heat_pump_loop_setpoint_schedule
      options["cooling_setpoint_schedule"] = heat_pump_loop_cooling_setpoint_schedule
      options["heating_setpoint_schedule"] = heat_pump_loop_heating_setpoint_schedule
			runner.registerInfo("yes, loop schedule created")
    end  
		unless parameters["vrfCondenserType"] == "WaterCooled"
			condenserLoops = {}
		else
			condenserLoops = OsLib_HVAC_zedg_vrf.createCondenserLoop(model, runner, options, parameters)
		end
    unless condenserLoops["condenser_loop"].nil?
      condenser_loop = condenserLoops["condenser_loop"]
    end
    unless condenserLoops["heat_pump_loop"].nil?
      heat_pump_loop = condenserLoops["heat_pump_loop"]
			runner.registerInfo("vrf condenser loop is created")
    end
    ### END CREATE NEW PLANTS
    
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
    primary_airloops = OsLib_HVAC_zedg_vrf.createPrimaryAirLoops(model, runner, options, parameters)
    ### END CREATE PRIMARY AIRLOOPS
     if zoneHVAC.include? "VRF"
      options["heat_pump_loop"] = heat_pump_loop
     end

    # added in custom code to load components to be used by createVRFAirConditioners
    files = Dir.entries("#{File.dirname(__FILE__)}/resources/")
    files.each do |new_object|
      next if not new_object.include?(".osc")

      #load the osc file
      new_object_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/#{new_object}")
      new_object_file = OpenStudio::IdfFile::load(new_object_path)

      if new_object_file.empty?
        runner.registerError("Unable to find the file #{new_object}.osc")
        return false
      else
        new_object_file = new_object_file.get
      end

      vt = OpenStudio::OSVersion::VersionTranslator.new
      new_objectComponent = vt.loadComponent(OpenStudio::Path.new(new_object_path))
      if new_objectComponent.empty?
        runner.registerError("Cannot load new_object component '#{new_object_file}'")
        return false
      else
        object = new_objectComponent.get.primaryObject
        componentData = model.insertComponent(new_objectComponent.get)
        if componentData.empty?
          runner.registerError("Failed to insert new_object component '#{new_object_file}' into model")
          return false
        else
          new_new_object = componentData.get.primaryComponentObject
          runner.registerInfo("Added #{new_new_object.name} into model")

          # add to options hash
          if new_new_object.to_AirConditionerVariableRefrigerantFlow.is_initialized
            options['vrf_ac'] = new_new_object
          elsif new_new_object.to_ZoneHVACTerminalUnitVariableRefrigerantFlow.is_initialized
            options['vrf_terminal'] = new_new_object
          else
            runner.regsiterError('Unexpected object type')
            return false
          end

        end
      end
    end

		vrf_airconditioners = OsLib_HVAC_zedg_vrf.createVRFAirConditioners(model,runner,options,parameters)

    ### START CREATE SECONDARY AIRLOOPS
    # populate inputs hash for create primary airloops method
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
    # secondary_airloops = OsLib_HVAC_zedg_vrf.createSecondaryAirLoops(model, runner, options)
    ### END CREATE SECONDARY AIRLOOPS
    
    ### START ASSIGN PLENUMS
    options = {"zonesPrimary" => zonesPrimary,"zonesPlenum" => zonesPlenum}
    zone_plenum_hash = OsLib_HVAC_zedg_vrf.validateAndAddPlenumZonesToSystem(model, runner, options)
    ### END ASSIGN PLENUMS
    
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
    if zoneHVAC.include? "SHP" or zoneHVAC == "VRF"
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
    OsLib_HVAC_zedg_vrf.createPrimaryZoneEquipment(model, runner, options, parameters)
    ### END CREATE PRIMARY ZONE EQUIPMENT
    
    # START ADD DCV
    options = {}
    unless zoneHVAC == "DualDuct"
      options["primary_airloops"] = primary_airloops
    end
    # options["secondary_airloops"] = secondary_airloops
    options["allHVAC"] = allHVAC
    OsLib_HVAC_zedg_vrf.addDCV(model, runner, options)
    # END ADD DCV
       
    # add in lifecycle costs
    expected_life = 25
    years_until_costs_start = 0
    costHVAC = costTotalHVACSystem
    lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("HVAC System", model.getBuilding, costHVAC, "CostPerEach", "Construction", expected_life, years_until_costs_start).get


    # added in custom code to load components to be used by createVRFAirConditioners
    base_vrf_ac = nil
    base_vrf_terminalUnit = nil
    files = Dir.entries("#{File.dirname(__FILE__)}/resources/")
    files.each do |new_object|
      next if not new_object.include?(".osc")
      runner.registerInfo("Importing component from #{new_object}")

      #load the osc file
      new_object_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/resources/#{new_object}")
      new_object_file = OpenStudio::IdfFile::load(new_object_path)

      if new_object_file.empty?
        runner.registerError("Unable to find the file #{new_object}.osc")
        return false
      else
        new_object_file = new_object_file.get
      end

      vt = OpenStudio::OSVersion::VersionTranslator.new
      new_objectComponent = vt.loadComponent(OpenStudio::Path.new(new_object_path))
      if new_objectComponent.empty?
        runner.registerError("Cannot load new_object component '#{new_object_file}'")
        return false
      else
        object = new_objectComponent.get.primaryObject
        componentData = model.insertComponent(new_objectComponent.get)
        if componentData.empty?
          runner.registerError("Failed to insert new_object component '#{new_object_file}' into model")
          return false
        else
          new_new_object = componentData.get.primaryComponentObject
          runner.registerInfo("Added #{new_new_object.name} into model")

          # add to options hash
          if new_new_object.to_AirConditionerVariableRefrigerantFlow.is_initialized
            base_vrf_ac = new_new_object
          elsif new_new_object.to_ZoneHVACTerminalUnitVariableRefrigerantFlow.is_initialized
            base_vrf_terminalUnit = new_new_object
          else
            runner.regsiterError('Unexpected object type')
            return false
          end

        end
      end
    end

    # add and alter base vrf acbase units in model
    base_vrf_ac = base_vrf_ac.to_AirConditionerVariableRefrigerantFlow.get
    base_vrf_ac.autosizeRatedTotalCoolingCapacity
    base_vrf_ac.autosizeRatedTotalHeatingCapacity
    base_vrf_ac.setHeatPumpWasteHeatRecovery(true)

    # add and alter base vrf terminal
    base_vrf_terminalUnit = base_vrf_terminalUnit.to_ZoneHVACTerminalUnitVariableRefrigerantFlow.get
    base_vrf_terminalUnit.autosizeSupplyAirFlowRateDuringCoolingOperation
    base_vrf_terminalUnit.autosizeSupplyAirFlowRateDuringHeatingOperation
    base_vrf_terminalUnit.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    # don't set outdoor air flow rates to 0 since used in place of DOAS

    # get coils
    os_version = OpenStudio::VersionString.new(OpenStudio::openStudioVersion())
    min_version_feature1 = OpenStudio::VersionString.new("2.3.1")
    if os_version >= min_version_feature1
      if base_vrf_terminalUnit.coolingCoil.is_initialized
        vrf_clg_coil = base_vrf_terminalUnit.coolingCoil.get
      else
        runner.registerWarning("Didn't find expected cooling coil for #{base_vrf_terminalUnit.name}")
      end
      if base_vrf_terminalUnit.heatingCoil.is_initialized
        vrf_htg_coil = base_vrf_terminalUnit.heatingCoil.get
      else
        runner.registerWarning("Didn't find expected heating coil for #{base_vrf_terminalUnit.name}")
      end
    else
      vrf_clg_coil = base_vrf_terminalUnit.coolingCoil
      vrf_htg_coil = base_vrf_terminalUnit.heatingCoil
    end

    # alter coils and fans
    vrf_clg_coil.autosizeRatedTotalCoolingCapacity
    vrf_clg_coil.autosizeRatedAirFlowRate
    vrf_clg_coil.autosizeRatedSensibleHeatRatio
    vrf_htg_coil.autosizeRatedTotalHeatingCapacity
    vrf_htg_coil.autosizeRatedAirFlowRate
    vrf_fan = base_vrf_terminalUnit.supplyAirFan.to_FanOnOff.get
    vrf_fan.autosizeMaximumFlowRate
    vrf_fan.setPressureRise(498)
    vrf_fan.setMotorEfficiency(0.85)

    # loop through zones assing HVAC
    zonesSecondary.each do |zone|
      runner.registerInfo("Adding VRF to #{zone.name}")

      # clone vrf_ac
      vrfAirConditioner = base_vrf_ac.clone(model).to_AirConditionerVariableRefrigerantFlow.get

      # construct Terminal VRF Unit
      vrf_terminalUnit = base_vrf_terminalUnit.clone(model).to_ZoneHVACTerminalUnitVariableRefrigerantFlow.get

      vrf_terminalUnit.addToThermalZone(zone)
      vrfAirConditioner.addTerminal(vrf_terminalUnit)
    end

    # remove base vrf units that were cloned into stories and spaces
    base_vrf_ac.remove
    base_vrf_terminalUnit.remove



    ### START REPORT FINAL CONDITIONS
    OsLib_HVAC_zedg_vrf.reportConditions(model, runner, "final")
    ### END REPORT FINAL CONDITIONS

    return true

  end #end the run method

end #end the measure

#this allows the measure to be used by the application
ZEDGVRFWithDOAS.new.registerWithApplication