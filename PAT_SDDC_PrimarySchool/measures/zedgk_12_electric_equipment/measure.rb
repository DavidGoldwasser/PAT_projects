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
require 'openstudio/extension/core/os_lib_lighting_and_equipment'
require 'openstudio/extension/core/os_lib_schedules'

# load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"

# start the measure
class ZEDGK12ElectricEquipment < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'ZEDG K12 ElectricEquipment'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for material and installation cost
    material_cost_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost_ip', true)
    material_cost_ip.setDisplayName('Material and Installation Costs for Electric Equipment per Floor Area ($/ft^2).')
    material_cost_ip.setDefaultValue(0.0)
    args << material_cost_ip

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
    material_cost_ip = runner.getDoubleArgumentValue('material_cost_ip', user_arguments)

    # prepare rule hash
    rules = [] # target, space type, EPD_ip

    # currently only target is lower energy, but setup hash this way so could add baseline in future
    # climate zone doesn't impact values for EPD in ZEDG

    # populate rules hash
    rules << ['LowEnergy', 'PrimarySchool', 'Auditorium', 0.2] # while now primary recommendation in TSD, if primary has one then follow secondary recommendations
    rules << ['LowEnergy', 'PrimarySchool', 'Cafeteria', 0.3]
    rules << ['LowEnergy', 'PrimarySchool', 'Classroom', 0.84]
    rules << ['LowEnergy', 'PrimarySchool', 'Corridor', 0.04] # for zedg change from 0.0 to  0.04
    rules << ['LowEnergy', 'PrimarySchool', 'Gym', 0.0]
    rules << ['LowEnergy', 'PrimarySchool', 'Kitchen', 14.2] # this should be set in kitchen measure instead of here. Add code to alert user of that.
    rules << ['LowEnergy', 'PrimarySchool', 'Library', 0.3]
    rules << ['LowEnergy', 'PrimarySchool', 'Lobby', 0.04] # for zedg change from 0.0 to  0.04
    rules << ['LowEnergy', 'PrimarySchool', 'Mechanical', 0.00]
    rules << ['LowEnergy', 'PrimarySchool', 'Office', 0.6] # for zedg change from 0.3 to  0.6
    rules << ['LowEnergy', 'PrimarySchool', 'Restroom', 0.0]
    rules << ['LowEnergy', 'SecondarySchool', 'Auditorium', 0.2]
    rules << ['LowEnergy', 'SecondarySchool', 'Cafeteria', 1.08]
    rules << ['LowEnergy', 'SecondarySchool', 'Classroom', 0.54]
    rules << ['LowEnergy', 'SecondarySchool', 'Corridor', 0.12]
    rules << ['LowEnergy', 'SecondarySchool', 'Gym', 0.12]
    rules << ['LowEnergy', 'SecondarySchool', 'Kitchen', 12.0] # this should be set in kitchen measure instead of here. Add code to alert user of that.
    rules << ['LowEnergy', 'SecondarySchool', 'Library', 0.54]
    rules << ['LowEnergy', 'SecondarySchool', 'Lobby', 0.24]
    rules << ['LowEnergy', 'SecondarySchool', 'Mechanical', 0.24]
    rules << ['LowEnergy', 'SecondarySchool', 'Office', 0.6]
    rules << ['LowEnergy', 'SecondarySchool', 'Restroom', 0.24]

    # make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]} #{rule[2]}"] = rule[3]
    end

    # calculate building EPD
    building = model.getBuilding
    initialEpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.electricEquipmentPowerPerFloorArea, 'W/m^2', 'W/ft^2', 1) # can add choices for unit display

    # calculate initial EPD to use later
    equipmentDefs = model.getElectricEquipmentDefinitions
    initialCostForElecEquip = OsLib_HelperMethods.getTotalCostForObjects(equipmentDefs)

    # reporting initial condition of model
    runner.registerInitialCondition("The building started with an EPD #{initialEpdDisplay}.")

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0

    # loop through space types
    model.getSpaceTypes.each do |spaceType|
      # skip of not used in model
      next if spaceType.spaces.empty?

      # confirm recognized spaceType standards information
      standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])
      if rulesHash["LowEnergy #{standardsInfo[spaceType][0]} #{standardsInfo[spaceType][1]}"].nil?
        runner.registerInfo("Couldn't map #{spaceType.name} to a recognized space type used in the ZEDG. Electric equipment levels for this SpaceType will not be altered.")
        next
      elsif standardsInfo[spaceType][1] == 'Kitchen'
        runner.registerInfo("#{spaceType.name} equipment won't be altered by this measure. Run the ZEDG K12 Kitchen measure to apply kitchen recommendations.")
        next
      end

      # get initial EPD for space type
      initialSpaceTypeEpd = OsLib_LightingAndEquipment.getEpdForSpaceArray(spaceType.spaces)

      # get target EPD
      targetEPD = OpenStudio.convert(rulesHash["LowEnergy #{standardsInfo[spaceType][0]} #{standardsInfo[spaceType][1]}"], 'W/ft^2', 'W/m^2').to_f

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
          if space_definition.name.get.downcase.include? 'elev'
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
      oldElecEquip.size == oldScheduleHash.size ? (defaultUsedAtLeastOnce = false) : (defaultUsedAtLeastOnce = true)

      # add new equipment
      spaceType.setElectricEquipmentPowerPerFloorArea(targetEPD) # not sure if this is instance or def?
      newElecEquip = spaceType.electricEquipment[0]
      newElecEquipDef = newElecEquip.electricEquipmentDefinition
      newElecEquipDef.setName("ZEDG K12 - #{standardsInfo[spaceType][1]} equipment")

      # add cost to equipment
      lcc_equipment = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("lcc_#{newElecEquipDef.name}", newElecEquipDef, material_cost_ip, 'CostPerArea', 'Construction', expected_life, years_until_costs_start)

      # report change
      if !spaceType.electricEquipmentPowerPerFloorArea.empty?
        oldEpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(initialSpaceTypeEpd, 'W/m^2', 'W/ft^2', 1)
        newEpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(spaceType.electricEquipmentPowerPerFloorArea.get, 'W/m^2', 'W/ft^2', 1) # can add choices for unit display
        runner.registerInfo("Changing EPD of #{spaceType.name} space type to #{newEpdDisplay} from #{oldEpdDisplay}")
      else
        runner.registerInfo("For some reason no EPD was set for #{spaceType.name} space type.")
      end

      if spaceElecEquipRemoved
        runner.registerInfo("One more more electric equipment objects directly assigned to spaces using #{spaceType.name} were removed. This is to limit EPD to what is added by this measure.")
      end

      # adjust schedules as necessary only hard assign if the default schedule was never used
      if (defaultUsedAtLeastOnce == false) && !oldElecEquip.empty?
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
      next if !space.spaceType.empty?
      runner.registerWarning("#{space.name} doesn't have a space type. Couldn't identify target EPD without a space type. EPD was not altered.")
    end

    # calculate final building EPD
    building = model.getBuilding
    finalEpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.electricEquipmentPowerPerFloorArea, 'W/m^2', 'W/ft^2', 1) # can add choices for unit display

    # calculate final EPD to use later
    equipmentDefs = model.getElectricEquipmentDefinitions
    finalCostForElecEquip = OsLib_HelperMethods.getTotalCostForObjects(equipmentDefs)

    # change in cost
    costRelatedToMeasure = finalCostForElecEquip - initialCostForElecEquip
    costRelatedToMeasureDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(costRelatedToMeasure, '$', '$', 0, true, false, false, false) # bools (prefix,suffix,space,parentheses)

    # reporting final condition of model
    if costRelatedToMeasure > 0
      runner.registerFinalCondition("The resulting building has an EPD #{finalEpdDisplay}. Initial capital cost related to this measure is #{costRelatedToMeasureDisplay}.")
    else
      runner.registerFinalCondition("The resulting building has an EPD #{finalEpdDisplay}.")
    end

    return true
  end
end

# this allows the measure to be use by the application
ZEDGK12ElectricEquipment.new.registerWithApplication
