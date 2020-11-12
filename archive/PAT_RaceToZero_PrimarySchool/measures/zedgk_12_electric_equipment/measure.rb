#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"
require "#{File.dirname(__FILE__)}/resources/os_lib_lighting_and_equipment"
require "#{File.dirname(__FILE__)}/resources/os_lib_schedules"

#start the measure
class ZEDGK12ElectricEquipment < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ZEDG K12 ElectricEquipment"
  end
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for material and installation cost
    material_cost_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost_ip",true)
    material_cost_ip.setDisplayName("Material and Installation Costs for Electric Equipment per Floor Area ($/ft^2).")
    material_cost_ip.setDefaultValue(0.0)
    args << material_cost_ip

    return args
  end

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    material_cost_ip = runner.getDoubleArgumentValue("material_cost_ip",user_arguments)

    #prepare rule hash
    rules = [] #target, space type, EPD_ip

    # currently only target is lower energy, but setup hash this way so could add baseline in future
    # climate zone doesn't impact values for EPD in ZEDG

    # populate rules hash
    rules << ["LowEnergy","PrimarySchool","Auditorium",0.2] # while now primary recommendation in TSD, if primary has one then follow secondary recommendations
    rules << ["LowEnergy","PrimarySchool","Cafeteria",0.3]
    rules << ["LowEnergy","PrimarySchool","Classroom",0.84]
    rules << ["LowEnergy","PrimarySchool","Corridor",0.04] # for zedg change from 0.0 to  0.04
    rules << ["LowEnergy","PrimarySchool","Gym",0.0]
    rules << ["LowEnergy","PrimarySchool","Kitchen",14.2] #this should be set in kitchen measure instead of here. Add code to alert user of that.
    rules << ["LowEnergy","PrimarySchool","Library",0.3]
    rules << ["LowEnergy","PrimarySchool","Lobby",0.04] # for zedg change from 0.0 to  0.04
    rules << ["LowEnergy","PrimarySchool","Mechanical",0.00]
    rules << ["LowEnergy","PrimarySchool","Office",0.6]  # for zedg change from 0.3 to  0.6
    rules << ["LowEnergy","PrimarySchool","Restroom",0.0]
    rules << ["LowEnergy","SecondarySchool","Auditorium",0.2]
    rules << ["LowEnergy","SecondarySchool","Cafeteria",1.08]
    rules << ["LowEnergy","SecondarySchool","Classroom",0.54]
    rules << ["LowEnergy","SecondarySchool","Corridor",0.12]
    rules << ["LowEnergy","SecondarySchool","Gym",0.12]
    rules << ["LowEnergy","SecondarySchool","Kitchen",12.0] #this should be set in kitchen measure instead of here. Add code to alert user of that.
    rules << ["LowEnergy","SecondarySchool","Library",0.54]
    rules << ["LowEnergy","SecondarySchool","Lobby",0.24]
    rules << ["LowEnergy","SecondarySchool","Mechanical",0.24]
    rules << ["LowEnergy","SecondarySchool","Office",0.6]
    rules << ["LowEnergy","SecondarySchool","Restroom",0.24]

    #make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]} #{rule[2]}"] = rule[3]
    end

    # calculate building EPD
    building = model.getBuilding
    initialEpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.electricEquipmentPowerPerFloorArea,"W/m^2","W/ft^2",1) # can add choices for unit display

    # calculate initial EPD to use later
    equipmentDefs = model.getElectricEquipmentDefinitions
    initialCostForElecEquip = OsLib_HelperMethods.getTotalCostForObjects(equipmentDefs)

    #reporting initial condition of model
    runner.registerInitialCondition("The building started with an EPD #{initialEpdDisplay}.")

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0

    # loop through space types
    model.getSpaceTypes.each do |spaceType|

      # skip of not used in model
      next if spaceType.spaces.size == 0

      # confirm recognized spaceType standards information
      standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])
      if rulesHash["LowEnergy #{standardsInfo[spaceType][0]} #{standardsInfo[spaceType][1]}"].nil?
        runner.registerInfo("Couldn't map #{spaceType.name} to a recognized space type used in the ZEDG. Electric equipment levels for this SpaceType will not be altered.")
        next
      elsif standardsInfo[spaceType][1] == "Kitchen"
        runner.registerInfo("#{spaceType.name} equipment won't be altered by this measure. Run the ZEDG K12 Kitchen measure to apply kitchen recommendations.")
        next
      end

      # get initial EPD for space type
      initialSpaceTypeEpd = OsLib_LightingAndEquipment.getEpdForSpaceArray(spaceType.spaces)

      # get target EPD
      targetEPD = OpenStudio::convert(rulesHash["LowEnergy #{standardsInfo[spaceType][0]} #{standardsInfo[spaceType][1]}"],"W/ft^2","W/m^2").to_f

      # harvest any hard assigned schedules along with equipmenting power of elecEquip. If there is no default the use the largest one of these
      oldElecEquip = []
      spaceType.electricEquipment.each do |elecEquip|
        oldElecEquip << elecEquip
      end

      # remove equipment associated directly with spaces
      spaceElecEquipRemoved = false
      spaceElecEquipSchedules = []
      spaceType.spaces.each do |space|
        equipment = space.electricEquipment
        equipment.each do |elecEquip|

          # leave space equpipment if definition is contains "elev" case insensitive
          space_definition = elecEquip.definition
          if space_definition.name.get.downcase.include? "elev"
            runner.registerInfo("Won't remove #{space_definition.name} in space #{space.name}")
          else
            oldElecEquip << elecEquip
            elecEquip.remove
            spaceElecEquipRemoved = true
          end
        end
      end

      # in future versions will use (equipmenting power)weighted average schedule merge for new schedule
      oldScheduleHash = OsLib_LightingAndEquipment.createHashOfInternalLoadWithHardAssignedSchedules(oldElecEquip)
      if oldElecEquip.size == oldScheduleHash.size then defaultUsedAtLeastOnce = false else defaultUsedAtLeastOnce = true end

      # add new equipment
      spaceType.setElectricEquipmentPowerPerFloorArea(targetEPD) # not sure if this is instance or def?
      newElecEquip = spaceType.electricEquipment[0]
      newElecEquipDef = newElecEquip.electricEquipmentDefinition
      newElecEquipDef.setName("ZEDG K12 - #{standardsInfo[spaceType][1]} equipment")

      # add cost to equipment
      lcc_equipment = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("lcc_#{newElecEquipDef.name}", newElecEquipDef, material_cost_ip, "CostPerArea", "Construction", expected_life, years_until_costs_start)

      # report change
      if not spaceType.electricEquipmentPowerPerFloorArea.empty?
        oldEpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(initialSpaceTypeEpd,"W/m^2","W/ft^2",1)
        newEpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(spaceType.electricEquipmentPowerPerFloorArea.get,"W/m^2","W/ft^2",1) # can add choices for unit display
        runner.registerInfo("Changing EPD of #{spaceType.name} space type to #{newEpdDisplay} from #{oldEpdDisplay}")
      else
        runner.registerInfo("For some reason no EPD was set for #{spaceType.name} space type.")
      end

      if spaceElecEquipRemoved
        runner.registerInfo("One more more electric equipment objects directly assigned to spaces using #{spaceType.name} were removed. This is to limit EPD to what is added by this measure.")
      end

      # adjust schedules as necessary only hard assign if the default schedule was never used
      if defaultUsedAtLeastOnce == false and oldElecEquip.size > 0
        # retrieve hard assigned schedule
        newElecEquip.setSchedule(oldScheduleHash.sort.reverse[0][0])
      else
        if newElecEquip.schedule.empty?
          runner.registerWarning("Didn't find an inherited or hard assigned schedule for equipment in #{spaceType.name} or underlying spaces. Please add a schedule before running a simulation.")
        end
      end

    end

    # warn if some spaces didn't have equipment altered at all (this would apply to spaces with space types not mapped)
    model.getSpaces.each do |space|
      next if not space.spaceType.empty?
      runner.registerWarning("#{space.name} doesn't have a space type. Couldn't identify target EPD without a space type. EPD was not altered.")
    end

    # calculate final building EPD
    building = model.getBuilding
    finalEpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.electricEquipmentPowerPerFloorArea,"W/m^2","W/ft^2",1) # can add choices for unit display

    # calculate final EPD to use later
    equipmentDefs = model.getElectricEquipmentDefinitions
    finalCostForElecEquip = OsLib_HelperMethods.getTotalCostForObjects(equipmentDefs)

    # change in cost
    costRelatedToMeasure = finalCostForElecEquip - initialCostForElecEquip
    costRelatedToMeasureDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(costRelatedToMeasure,"$","$",0,true,false,false,false) # bools (prefix,suffix,space,parentheses)

    #reporting final condition of model
    if costRelatedToMeasure > 0
      runner.registerFinalCondition("The resulting building has an EPD #{finalEpdDisplay}. Initial capital cost related to this measure is #{costRelatedToMeasureDisplay}.")
    else
      runner.registerFinalCondition("The resulting building has an EPD #{finalEpdDisplay}.")
    end

    return true

  end

end

#this allows the measure to be use by the application
ZEDGK12ElectricEquipment.new.registerWithApplication