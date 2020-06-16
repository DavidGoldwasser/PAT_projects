# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# load OpenStudio measure libraries from openstudio-extension gem
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'
require 'openstudio/extension/core/os_lib_hvac'
require 'openstudio/extension/core/os_lib_schedules'

# load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"

# start the measure
class ZEDGK12SWH < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'ZEDG K12 SWH'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for material and installation cost
    costTotalSwhSystem = OpenStudio::Measure::OSArgument.makeDoubleArgument('costTotalSwhSystem', true)
    costTotalSwhSystem.setDisplayName('Total Cost for Kitchen System ($).')
    costTotalSwhSystem.setDefaultValue(0.0)
    args << costTotalSwhSystem

    # make an argument number of students
    numberOfStudents = OpenStudio::Measure::OSArgument.makeIntegerArgument('numberOfStudents', true)
    numberOfStudents.setDisplayName('Total Number of Students.')
    # calculate default value
    # get total number of students
    studentCount = 0
    model.getThermalZones.each do |zone|
      zoneMultiplier = zone.multiplier
      zone.spaces.each do |space|
        if space.spaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.get.include? 'Classroom'
              # add up number of people from each classroom space
              studentCount += space.numberOfPeople * zoneMultiplier
            end
          end
        end
      end
    end
    if studentCount.to_i > 0
      numberOfStudents.setDefaultValue(studentCount.to_i)
    end
    args << numberOfStudents
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    ### START INPUTS
    # assign the user inputs to variables
    costTotalSwhSystem = runner.getDoubleArgumentValue('costTotalSwhSystem', user_arguments)
    numberOfStudents = runner.getIntegerArgumentValue('numberOfStudents', user_arguments)

    # initial condition
    runner.registerInitialCondition("The initial model has #{model.getWaterUseEquipments.size} water use equipment objects")

    # look at upstream measure for 'numberOfStudents' argument
    # todo - in future make template in this measure an optional argument and only override value when it is not initialized. There may be valid use cases for using different template values in different measures within the same workflow.
    value_from_osw = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, 'numberOfStudents')
    if !value_from_osw.empty?
      runner.registerInfo("Replacing argument named 'numberOfStudents' from current measure with a value of #{value_from_osw[:value]} from #{value_from_osw[:measure_name]}.")
      numberOfStudents = value_from_osw[:value].to_i
    end

    # default building/kitchen space types
    standardBuildingTypeTest = ['PrimarySchool', 'SecondarySchool']
    primarySpaceType = 'Classroom'
    swhSpaceTypes = {}
    swhSpaceTypes['PrimarySchool'] = ['Kitchen', 'Restroom']
    swhSpaceTypes['SecondarySchool'] = ['Kitchen', 'Restroom', 'Gym']
    # water use equipment inputs
    waterUsePerStudent = {}
    # kitchen
    kitchenWaterUsePerStudent = {}
    kitchenWaterUsePerStudent['PrimarySchool'] = 0.00000016176923077 # m3/s*student
    kitchenWaterUsePerStudent['SecondarySchool'] = 0.00000011654166667 # m3/s*student
    waterUsePerStudent['Kitchen'] = kitchenWaterUsePerStudent
    # restroom
    restroomWaterUsePerStudent = {}
    restroomWaterUsePerStudent['PrimarySchool'] = 0.00000009145299145 # m3/s*student
    restroomWaterUsePerStudent['SecondarySchool'] = 0.00000009143518519 # m3/s*student
    waterUsePerStudent['Restroom'] = restroomWaterUsePerStudent
    # gym
    gymWaterUsePerStudent = {}
    gymWaterUsePerStudent['PrimarySchool'] = 0 # m3/s*student
    gymWaterUsePerStudent['SecondarySchool'] = 0.00000016602546296 # m3/s*student
    waterUsePerStudent['Gym'] = gymWaterUsePerStudent
    ### END INPUTS

    ### START DETERMINE BUILDING TYPE
    standardBuildingType = false
    if model.building.is_initialized
      if model.building.get.standardsBuildingType.is_initialized
        standardBuildingType = model.building.get.standardsBuildingType.get
      end
    end
    unless standardBuildingType
      # search primary space type for standardsBuildingType
      model.getSpaces.each do |space|
        next if standardBuildingType
        if space.spaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.get.include? primarySpaceType
              if space.spaceType.get.standardsBuildingType.is_initialized
                standardBuildingType = space.spaceType.get.standardsBuildingType.get
              end
            end
          end
        end
      end
    end
    building_type = false
    standardBuildingTypeTest.each do |building_type_test|
      if standardBuildingType == building_type_test
        building_type = building_type_test
      end
    end
    unless building_type
      # building type not specified or not appropriate for this measure
      runner.registerInfo("Building type is not specified or not supported.  Measure will proceed assuming type is #{standardBuildingTypeTest[0]}.")
      building_type = standardBuildingTypeTest[0]
    end
    ### END DETERMINE BUILDING TYPE

    ### START FIND REPRESENTATIVE THERMAL ZONES AND SPACES
    # for kitchen and gym, water use will be applied to representative spaces
    # for restroom, water use will be applied to each restroom
    applyMeasure = false
    numberOfRestrooms = 0
    restroomSpaces = []
    representativeZone = {}
    representativeSpace = {}
    swhSpaceTypes[building_type].each do |applicableSpaceType|
      if applicableSpaceType == 'Restroom'
        # get all restroom spaces
        model.getSpaces.each do |space|
          if space.spaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.is_initialized
              if space.spaceType.get.standardsSpaceType.get.include? applicableSpaceType
                restroomSpaces << space
                numberOfRestrooms += 1
              end
            end
          end
        end
        if numberOfRestrooms > 0
          applyMeasure = true
        else
          runner.registerInfo("Model does not have any #{applicableSpaceType} spaces.  Measure will not apply #{applicableSpaceType} recommendations.")
        end
      else
        # applicable space type is kitchen or gym
        maxRepresentativeZoneArea = 0
        spaceTypeZones = []
        representativeZone[applicableSpaceType] = false
        representativeSpace[applicableSpaceType] = false
        # find representative zone
        model.getThermalZones.each do |zone|
          isRepresentativeZone = false
          zoneArea = 0
          zone.spaces.each do |space|
            zoneArea += space.floorArea
            if space.spaceType.is_initialized
              if space.spaceType.get.standardsSpaceType.is_initialized
                if space.spaceType.get.standardsSpaceType.get.include? applicableSpaceType
                  # if zone contains an applicable space, assume it is an applicable zone
                  isRepresentativeZone = true
                end
              end
            end
          end
          if isRepresentativeZone
            spaceTypeZones << zone
            if zoneArea > maxRepresentativeZoneArea
              # set zone as the representative zone if it is the largest applicable zone
              representativeZone[applicableSpaceType] = zone
              maxRepresentativeZoneArea = zoneArea
            end
          end
        end
        # find largest space in representative zone
        if representativeZone[applicableSpaceType]
          applyMeasure = true
          maxRepresentativeSpaceArea = 0
          representativeZone[applicableSpaceType].spaces.each do |space|
            if space.spaceType.is_initialized
              if space.spaceType.get.standardsSpaceType.is_initialized
                if space.spaceType.get.standardsSpaceType.get.include? applicableSpaceType
                  if space.floorArea > maxRepresentativeSpaceArea
                    maxRepresentativeSpaceArea = space.floorArea
                    representativeSpace[applicableSpaceType] = space
                  end
                end
              end
            end
          end
        else
          runner.registerInfo("Model does not have any #{applicableSpaceType} spaces.  Measure will not apply #{applicableSpaceType} recommendations.")
        end
      end
    end
    # exit measure if nothing to apply
    unless applyMeasure
      runner.registerInfo('Model does not have any spaces expected to have SWH use.  Measure will not modify the model.')
      return true
    end
    ### END FIND REPRESENTATIVE THERMAL ZONE AND SPACE

    ### START DELETE EXISTING EQUIPMENT
    # remove plant loops for SWH
    model.getPlantLoops.each do |plantLoop|
      usedForSHW = false
      plantLoop.demandComponents.each do |comp|
        if comp.to_WaterUseConnections.is_initialized
          usedForSHW = true
        end
      end
      if usedForSHW
        plantLoop.remove
        runner.registerWarning("#{plantLoop.name} for service water heating will be deleted so that ZEDG recommendations can be applied.")
      end
    end
    ### END DELETE EXISTING EQUIPMENT

    ### START APPLY SWH RECOMMENDATIONS
    # create swh water plant
    swhPlant = OpenStudio::Model::PlantLoop.new(model)
    swhPlant.setName('ZEDG SWH Loop')
    swhPlant.setMaximumLoopTemperature(60)
    swhPlant.setMinimumLoopTemperature(10)
    loopSizing = swhPlant.sizingPlant
    loopSizing.setLoopType('Heating')
    loopSizing.setDesignLoopExitTemperature(60) # ML follows convention of sizing temp being larger than supply temp
    loopSizing.setLoopDesignTemperatureDifference(5)
    # create a pump
    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setRatedPumpHead(1) # Pa
    pump.setMotorEfficiency(1.0)
    pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    # supply components
    # create a water heater
    waterHeater = OpenStudio::Model::WaterHeaterMixed.new(model)
    waterHeater.setTankVolume(1) # ML volume is arbitrary; just needs to be big enough to serve building
    waterHeater.setHeaterThermalEfficiency(0.9)
    waterHeater.setOffCycleParasiticHeatFractiontoTank(0.9)
    waterHeater.setAmbientTemperatureIndicator('Schedule')
    # setpoint temperature schedule
    waterHeaterSetpointSchedule = OsLib_Schedules.createComplexSchedule(model, 'name' => 'ZEDG Water-Heater-Temp-Schedule',
                                                                               'default_day' => ['All Days', [24, 60.0]])
    waterHeater.setSetpointTemperatureSchedule(waterHeaterSetpointSchedule)
    # ambient temperature schedule
    waterHeaterAmbientTemperatureSchedule = OsLib_Schedules.createComplexSchedule(model, 'name' => 'ZEDG Water-Heater-Ambient-Temp-Schedule',
                                                                                         'default_day' => ['All Days', [24, 22.0]])
    waterHeater.setAmbientTemperatureSchedule(waterHeaterAmbientTemperatureSchedule)
    # create a scheduled setpoint manager
    swhSetpointSchedule = OsLib_Schedules.createComplexSchedule(model, 'name' => 'ZEDG SWH-Loop-Temp-Schedule',
                                                                       'default_day' => ['All Days', [24, 60.0]])
    setpointManagerScheduled = OpenStudio::Model::SetpointManagerScheduled.new(model, swhSetpointSchedule)
    # create a supply bypass pipe
    pipeSupplyBypass = OpenStudio::Model::PipeAdiabatic.new(model)
    # create a supply outlet pipe
    pipeSupplyOutlet = OpenStudio::Model::PipeAdiabatic.new(model)
    # demand components
    waterUseEquipmentDefinition = {}
    waterUseConnections = []
    # building swh flow fraction schedule
    ruleset_name = 'ZEDG SWH-Flow-Fraction-Schedule'
    winter_design_day = [[24, 0]]
    summer_design_day = [[24, 1]]
    default_day = ['Weekday', [7, 0.05], [8, 0.10], [9, 0.34], [10, 0.60], [11, 0.63], [12, 0.72], [13, 0.79], [14, 0.83], [15, 0.61], [16, 0.65], [18, 0.10], [19, 0.19], [20, 0.25], [22, 0.22], [23, 0.12], [24, 0.09]]
    rules = []
    rules << ['Weekend', '1/1-12/31', 'Sat/Sun', [8, 0.03], [14, 0.05], [24, 0.03]]
    rules << ['Summer Weekday', '7/1-8/31', 'Mon/Tue/Wed/Thu/Fri', [7, 0.05], [18, 0.10], [19, 0.19], [20, 0.25], [22, 0.22], [23, 0.12], [24, 0.09]]
    optionsFlowFraction = { 'name' => ruleset_name,
                            'winter_design_day' => winter_design_day,
                            'summer_design_day' => summer_design_day,
                            'default_day' => default_day,
                            'rules' => rules }
    flowFractionSchedule = OsLib_Schedules.createComplexSchedule(model, optionsFlowFraction)
    # target temperature schedule
    targetTemperatureSchedule = OsLib_Schedules.createComplexSchedule(model, 'name' => 'ZEDG SWH-Target-Temperature-Schedule',
                                                                             'default_day' => ['All Days', [24, 40]])
    # sensible fraction schedule name
    sensibleFractionSchedule = OsLib_Schedules.createComplexSchedule(model, 'name' => 'ZEDG SWH-Sensible-Fraction-Schedule',
                                                                            'default_day' => ['All Days', [24, 0.2]])
    # latent fraction schedule name
    latentFractionSchedule = OsLib_Schedules.createComplexSchedule(model, 'name' => 'ZEDG SWH-Latent-Fraction-Schedule',
                                                                          'default_day' => ['All Days', [24, 0.05]])
    # hot water supply temperature schedule
    hotWaterSupplyTemperatureSchedule = OsLib_Schedules.createComplexSchedule(model, 'name' => 'ZEDG SWH-Hot-Supply-Temperature-Schedule',
                                                                                     'default_day' => ['All Days', [24, 55]])
    # create water use equipment definitions, equipment, and connections
    swhSpaceTypes[building_type].each do |applicableSpaceType|
      if (applicableSpaceType == 'Restroom') && (numberOfRestrooms > 0)
        waterUsePerRestroom = waterUsePerStudent[applicableSpaceType][building_type] * numberOfStudents / numberOfRestrooms
        # create water use equipment definition for restrooms
        waterUseEquipmentDefinition[applicableSpaceType] = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
        waterUseEquipmentDefinition[applicableSpaceType].setName("ZEDG #{applicableSpaceType} Water Use")
        waterUseEquipmentDefinition[applicableSpaceType].setPeakFlowRate(waterUsePerRestroom)
        waterUseEquipmentDefinition[applicableSpaceType].setTargetTemperatureSchedule(targetTemperatureSchedule)
        waterUseEquipmentDefinition[applicableSpaceType].setSensibleFractionSchedule(sensibleFractionSchedule)
        waterUseEquipmentDefinition[applicableSpaceType].setLatentFractionSchedule(latentFractionSchedule)
        runner.registerInfo("Adding SWH to #{restroomSpaces.size} restrooms.")
        restroomSpaces.each do |restroomSpace|
          # water use equipment
          waterUseEquipment = OpenStudio::Model::WaterUseEquipment.new(waterUseEquipmentDefinition[applicableSpaceType])
          waterUseEquipment.setSpace(restroomSpace)
          waterUseEquipment.setFlowRateFractionSchedule(flowFractionSchedule)
          # water use connection
          waterUseConnection = OpenStudio::Model::WaterUseConnections.new(model)
          waterUseConnection.addWaterUseEquipment(waterUseEquipment)
          waterUseConnection.setHotWaterSupplyTemperatureSchedule(hotWaterSupplyTemperatureSchedule)
          waterUseConnections << waterUseConnection
        end
      else
        if representativeSpace[applicableSpaceType]
          runner.registerInfo("Adding SWH to #{applicableSpaceType}.")
          # water use equipment definition
          waterUseEquipmentDefinition[applicableSpaceType] = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
          waterUseEquipmentDefinition[applicableSpaceType].setName("ZEDG #{applicableSpaceType} Water Use")
          waterUse = waterUsePerStudent[applicableSpaceType][building_type] * numberOfStudents
          waterUseEquipmentDefinition[applicableSpaceType].setPeakFlowRate(waterUse)
          waterUseEquipmentDefinition[applicableSpaceType].setTargetTemperatureSchedule(targetTemperatureSchedule)
          waterUseEquipmentDefinition[applicableSpaceType].setSensibleFractionSchedule(sensibleFractionSchedule)
          waterUseEquipmentDefinition[applicableSpaceType].setLatentFractionSchedule(latentFractionSchedule)
          # water use equipment
          waterUseEquipment = OpenStudio::Model::WaterUseEquipment.new(waterUseEquipmentDefinition[applicableSpaceType])
          waterUseEquipment.setSpace(representativeSpace[applicableSpaceType])
          waterUseEquipment.setFlowRateFractionSchedule(flowFractionSchedule)
          # water use connection
          waterUseConnection = OpenStudio::Model::WaterUseConnections.new(model)
          waterUseConnection.addWaterUseEquipment(waterUseEquipment)
          waterUseConnection.setHotWaterSupplyTemperatureSchedule(hotWaterSupplyTemperatureSchedule)
          waterUseConnections << waterUseConnection
        end
      end
    end
    # create a demand bypass pipe
    pipeDemandBypass = OpenStudio::Model::PipeAdiabatic.new(model)
    # create a demand inlet pipe
    pipeDemandInlet = OpenStudio::Model::PipeAdiabatic.new(model)
    # create a demand outlet pipe
    pipeDemandOutlet = OpenStudio::Model::PipeAdiabatic.new(model)
    # connect components to plant loop
    # supply side components
    swhPlant.addSupplyBranchForComponent(waterHeater)
    swhPlant.addSupplyBranchForComponent(pipeSupplyBypass)
    pump.addToNode(swhPlant.supplyInletNode)
    pipeSupplyOutlet.addToNode(swhPlant.supplyOutletNode)
    setpointManagerScheduled.addToNode(swhPlant.supplyOutletNode)
    # demand side components (water coils are added as they are added to airloops and zoneHVAC)
    waterUseConnections.each do |waterUseConnection|
      swhPlant.addDemandBranchForComponent(waterUseConnection)
    end
    swhPlant.addDemandBranchForComponent(pipeDemandBypass)
    pipeDemandInlet.addToNode(swhPlant.demandInletNode)
    pipeDemandOutlet.addToNode(swhPlant.demandOutletNode)
    ### END APPLY SWH RECOMMENDATIONS

    # lifecycle costs
    expected_life = 25
    years_until_costs_start = 0
    costSwh = costTotalSwhSystem
    lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost('Service Water Heating', model.getBuilding, costSwh, 'CostPerEach', 'Construction', expected_life, years_until_costs_start).get

    # initial condition
    runner.registerFinalCondition("The final model has #{model.getWaterUseEquipments.size} water use equipment objects")

    return true
  end
end

# this allows the measure to be used by the application
ZEDGK12SWH.new.registerWithApplication
