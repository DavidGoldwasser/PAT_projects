# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
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

# load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"
require "#{File.dirname(__FILE__)}/resources/os_lib_lighting_and_equipment"
require "#{File.dirname(__FILE__)}/resources/os_lib_schedules"

# start the measure
class AedgSmallToMediumOfficeInteriorLighting < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'AedgSmallToMediumOfficeInteriorLighting'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for material and installation cost
    material_cost_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost_ip', true)
    material_cost_ip.setDisplayName('Material and Installation Costs for Lights per Floor Area ($/ft^2).')
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
    rules = [] # target, space type, LPD_ip

    # currently only target is lower energy, but setup hash this way so could add baseline in future
    # climate zone doesn't impact values for LPD in AEDG

    # populate rules hash (from TSD's for small and medium office)
    rules << ['LowEnergy', 'BreakRoom', 0.73]
    rules << ['LowEnergy', 'ClosedOffice', (0.97 + 0.8) / 2]
    rules << ['LowEnergy', 'Conference', 0.77]
    rules << ['LowEnergy', 'Corridor', 0.5]
    rules << ['LowEnergy', 'IT_Room', 0.64] # mapping to AEDG Active Storage
    rules << ['LowEnergy', 'Lobby', 1.09]
    rules << ['LowEnergy', 'Elec/MechRoom', 1.24]
    rules << ['LowEnergy', 'OpenOffice', 0.68]
    rules << ['LowEnergy', 'PrintRoom', 0.64] # mapping to AEDG Active Storage
    rules << ['LowEnergy', 'Restroom', 0.82]
    rules << ['LowEnergy', 'Stair', 0.6]
    rules << ['LowEnergy', 'Storage', 0.64]
    rules << ['LowEnergy', 'Vending', 0.73] # mapping to print room from AEDG

    # make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]}"] = rule[2]
    end

    # calculate building LPD
    building = model.getBuilding
    initialLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.lightingPowerPerFloorArea, 'W/m^2', 'W/ft^2', 1) # can add choices for unit display

    # calculate initial LPD to use later
    lightDefs = model.getLightsDefinitions
    initialCostForLights = OsLib_HelperMethods.getTotalCostForObjects(lightDefs)

    # reporting initial condition of model
    runner.registerInitialCondition("The building started with an LPD #{initialLpdDisplay}.")

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0

    # loop through space types
    model.getSpaceTypes.each do |spaceType|
      # skip of not used in model
      next if spaceType.spaces.empty?

      # confirm recognized spaceType standards information
      standardsInfo = OsLib_HelperMethods.getSpaceTypeStandardsInformation([spaceType])
      if rulesHash["LowEnergy #{standardsInfo[spaceType][1]}"].nil?
        runner.registerInfo("Couldn't map #{spaceType.name} to a recognized space type used in the AEDG. Lighting levels for this SpaceType will not be altered.")
        next
      end

      # get initial LPD for space type
      initialSpaceTypeLpd = OsLib_LightingAndEquipment.getLpdForSpaceArray(spaceType.spaces)

      # get target LPD
      targetLPD = OpenStudio.convert(rulesHash["LowEnergy #{standardsInfo[spaceType][1]}"], 'W/ft^2', 'W/m^2').to_f

      # harvest any hard assigned schedules along with lighting power of light. If there is no default the use the largest one of these
      oldLights = []
      spaceType.lights.each do |light|
        oldLights << light
      end

      # remove lights associated directly with spaces
      spaceLightRemoved = false
      spaceLightsSchedules = []
      spaceType.spaces.each do |space|
        lights = space.lights
        lights.each do |light|
          oldLights << light
          light.remove
          spaceLightRemoved = true
        end
      end

      # in future versions will use (lighting power)weighted average schedule merge for new schedule
      oldScheduleHash = OsLib_LightingAndEquipment.createHashOfInternalLoadWithHardAssignedSchedules(oldLights)
      oldLights.size == oldScheduleHash.size ? (defaultUsedAtLeastOnce = false) : (defaultUsedAtLeastOnce = true)

      # add new lights
      spaceType.setLightingPowerPerFloorArea(targetLPD) # not sure if this is instance or def?
      newLight = spaceType.lights[0]
      newLightDef = newLight.lightsDefinition
      newLightDef.setName("AEDG SmMdOff - #{standardsInfo[spaceType][1]} lights")

      # add cost to lights
      lcc_lights = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("lcc_#{newLightDef.name}", newLightDef, material_cost_ip, 'CostPerArea', 'Construction', expected_life, years_until_costs_start)

      # report change
      if !spaceType.lightingPowerPerFloorArea.empty?
        oldLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(initialSpaceTypeLpd, 'W/m^2', 'W/ft^2', 1)
        newLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(spaceType.lightingPowerPerFloorArea.get, 'W/m^2', 'W/ft^2', 1) # can add choices for unit display
        runner.registerInfo("Changing LPD of #{spaceType.name} space type to #{newLpdDisplay} from #{oldLpdDisplay}")
      else
        runner.registerInfo("For some reason no LPD was set for #{spaceType.name} space type.")
      end

      if spaceLightRemoved
        runner.registerInfo("One more more lights directly assigned to spaces using #{spaceType.name} were removed. This is to limit lighting to what is added by this measure.")
      end

      # adjust schedules as necessary only hard assign if the default schedule was never used
      if (defaultUsedAtLeastOnce == false) && !oldLights.empty?
        # retrieve hard assigned schedule
        newLight.setSchedule(oldScheduleHash.sort.reverse[0][0])
      else
        if newLight.schedule.empty?
          runner.registerWarning("Didn't find an inherited or hard assigned schedule for lights in #{spaceType.name} or underlying spaces. Please add a schedule before running a simulation.")
        end
      end
    end

    # warn if some spaces didn't have lights altered at all (this would apply to spaces with space types not mapped)
    model.getSpaces.each do |space|
      next if !space.spaceType.empty?
      runner.registerWarning("#{space.name} doesn't have a space type. Couldn't identify target LPD without a space type. Lights were not altered.")
    end

    # populate AEDG tip keys
    aedgTips = []
    aedgTips.push('DL01', 'DL02', 'DL03', 'DL04', 'DL05', 'EL02', 'EL03', 'EL05', 'EL06', 'EL07', 'EL08', 'EL12', 'EL13', 'EL14', 'EL15', 'EL16', 'EL17', 'EL18', 'EL19', 'EL20')

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips('SmMdOff', aedgTips.uniq.sort, runner)
    if !aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    # calculate final building LPD
    building = model.getBuilding
    finalLpdDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(building.lightingPowerPerFloorArea, 'W/m^2', 'W/ft^2', 1) # can add choices for unit display

    # calculate final LPD to use later
    lightDefs = model.getLightsDefinitions
    finalCostForLights = OsLib_HelperMethods.getTotalCostForObjects(lightDefs)

    # change in cost
    costRelatedToMeasure = finalCostForLights - initialCostForLights
    costRelatedToMeasureDisplay = OsLib_HelperMethods.neatConvertWithUnitDisplay(costRelatedToMeasure, '$', '$', 0, true, false, false, false) # bools (prefix,suffix,space,parentheses)

    # reporting final condition of model
    if costRelatedToMeasure > 0
      runner.registerFinalCondition("The resulting building has an LPD #{finalLpdDisplay}. Initial capital cost related to this measure is #{costRelatedToMeasureDisplay}. #{aedgTipsLong}")
    else
      runner.registerFinalCondition("The resulting building has an LPD #{finalLpdDisplay}. #{aedgTipsLong}")
    end

    return true
  end
end

# this allows the measure to be use by the application
AedgSmallToMediumOfficeInteriorLighting.new.registerWithApplication
