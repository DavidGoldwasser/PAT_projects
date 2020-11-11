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

# load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"

# start the measure
class AedgK12ExteriorLighting < OpenStudio::Measure::ModelMeasure
  include OsLib_AedgMeasures
  include OsLib_HelperMethods
  include OsLib_LightingAndEquipment

  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'AedgK12ExteriorLighting'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # no argument to remove exterior lights. that will always be done.

    # make choice argument for target performance
    choices = OpenStudio::StringVector.new
    choices << 'AEDG K-12 - Baseline'
    choices << 'AEDG K-12 - Target'
    target = OpenStudio::Measure::OSArgument.makeChoiceArgument('target', choices)
    target.setDisplayName('Exterior Lighting Target Performance')
    target.setDefaultValue('AEDG K-12 - Target')
    args << target

    # make choice argument for target performance
    choices = OpenStudio::StringVector.new
    # hiding area 1 and 2 because no lighting is recommended
    # choices << "0 - Parks/Rural Areas (Undeveloped)"
    # choices << "1 - Parks/Rural Areas (Developed)"
    choices << '2 - Residential, Mixed Use'
    choices << '3 - All Other Areas'
    choices << '4 - High Activity Commercial'
    lightingZone = OpenStudio::Measure::OSArgument.makeChoiceArgument('lightingZone', choices)
    lightingZone.setDisplayName('Exterior Lighting Zone')
    lightingZone.setDefaultValue('2 - Residential, Mixed Use')
    args << lightingZone

    # make an argument for facadeLandscapeLighting
    facadeLandscapeLighting = OpenStudio::Measure::OSArgument.makeDoubleArgument('facadeLandscapeLighting', true)
    facadeLandscapeLighting.setDisplayName('Wall Coverage Area for Decorative Facade Lighting (ft^2)')
    facadeLandscapeLighting.setDefaultValue(0.0)
    args << facadeLandscapeLighting

    # make an argument for parkingDrivesLighting
    parkingDrivesLighting = OpenStudio::Measure::OSArgument.makeDoubleArgument('parkingDrivesLighting', true)
    parkingDrivesLighting.setDisplayName('Ground Coverage Area for Parking Lots and Drives Lighting (ft^2)')
    parkingDrivesLighting.setDefaultValue(0.0)
    args << parkingDrivesLighting

    # make an argument for walkwayPlazaSpecialLighting
    walkwayPlazaSpecialLighting = OpenStudio::Measure::OSArgument.makeDoubleArgument('walkwayPlazaSpecialLighting', true)
    walkwayPlazaSpecialLighting.setDisplayName('Ground Coverage Area for Walkway and Plaza Lighting (ft^2)')
    walkwayPlazaSpecialLighting.setDefaultValue(0.0)
    args << walkwayPlazaSpecialLighting

    # make an argument for material and installation cost
    costTotalExteriorLights = OpenStudio::Measure::OSArgument.makeDoubleArgument('costTotalExteriorLights', true)
    costTotalExteriorLights.setDisplayName('Total cost for all Exterior Lighting ($).')
    costTotalExteriorLights.setDefaultValue(0.0)
    args << costTotalExteriorLights

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
    target = runner.getStringArgumentValue('target', user_arguments)
    lightingZone = runner.getStringArgumentValue('lightingZone', user_arguments).split(//).first # I only want the first character
    facadeLandscapeLighting = runner.getDoubleArgumentValue('facadeLandscapeLighting', user_arguments)
    parkingDrivesLighting = runner.getDoubleArgumentValue('parkingDrivesLighting', user_arguments)
    walkwayPlazaSpecialLighting = runner.getDoubleArgumentValue('walkwayPlazaSpecialLighting', user_arguments)
    costTotalExteriorLights = runner.getDoubleArgumentValue('costTotalExteriorLights', user_arguments)

    non_neg_args = ['facadeLandscapeLighting', 'parkingDrivesLighting', 'walkwayPlazaSpecialLighting', 'costTotalExteriorLights']
    non_neg = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min' => 0.0, 'max' => nil, 'min_eq_bool' => true, 'max_eq_bool' => false, 'arg_array' => non_neg_args)
    if !non_neg then return false end

    # prepare rule hash
    rules = [] # exterior lighting zone, lighting type, LPD W/ft^2, setback fraction

    # exterior lighting recommendations is the same across all climate zones
    # TSD low energy - primary (2219 W), secondary (18,980 W). Total (21,200) .Both controlled by astronomical clock and schedule
    # TSD baseline - primary (5547 W), secondary (47,450 W). Total (53,000). Only controlled by astronomical clock.
    # Using 2.5x target values for baseline value.
    baselineToTargetRatio = 2.5

    # facadeLandscapeLighting Target
    # notes on control  s: auto OFF between 12am and 6am
    rules << ['0', 'facadeLandscapeLighting', 'AEDG K-12 - Target', 'NA', 'NA']
    rules << ['1', 'facadeLandscapeLighting', 'AEDG K-12 - Target', 'NA', 'NA']
    rules << ['2', 'facadeLandscapeLighting', 'AEDG K-12 - Target', 0.05, 0.0]
    rules << ['3', 'facadeLandscapeLighting', 'AEDG K-12 - Target', 0.075, 0.0]
    rules << ['4', 'facadeLandscapeLighting', 'AEDG K-12 - Target', 0.075, 0.0]

    # parkingDrivesLighting  Target
    # notes on controls: reduce to 25% between 12am and 6am
    rules << ['0', 'parkingDrivesLighting', 'AEDG K-12 - Target', 'NA', 'NA', 'NA']
    rules << ['1', 'parkingDrivesLighting', 'AEDG K-12 - Target', 'NA', 'NA', 'NA']
    rules << ['2', 'parkingDrivesLighting', 'AEDG K-12 - Target', 0.06, 0.25]
    rules << ['3', 'parkingDrivesLighting', 'AEDG K-12 - Target', 0.1, 0.25]
    rules << ['4', 'parkingDrivesLighting', 'AEDG K-12 - Target', 0.1, 0.25]

    # walkwayPlazaSpecialLighting Target
    # notes on controls: reduce to 25% between 12am and 6am
    rules << ['0', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Target', 'NA', 'NA']
    rules << ['1', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Target', 'NA', 'NA']
    rules << ['2', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Target', 0.16, 0.25]
    rules << ['3', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Target', 0.14, 0.25]
    rules << ['4', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Target', 0.14, 0.25]

    # facadeLandscapeLighting Baseline
    # notes on controls: only astronomical
    rules << ['0', 'facadeLandscapeLighting', 'AEDG K-12 - Baseline', 'NA', 'NA']
    rules << ['1', 'facadeLandscapeLighting', 'AEDG K-12 - Baseline', 'NA', 'NA']
    rules << ['2', 'facadeLandscapeLighting', 'AEDG K-12 - Baseline', 0.05 * baselineToTargetRatio, 1.0]
    rules << ['3', 'facadeLandscapeLighting', 'AEDG K-12 - Baseline', 0.075 * baselineToTargetRatio, 1.0]
    rules << ['4', 'facadeLandscapeLighting', 'AEDG K-12 - Baseline', 0.075 * baselineToTargetRatio, 1.0]

    # parkingDrivesLighting Baseline
    # notes on controls: only astronomical
    rules << ['0', 'parkingDrivesLighting', 'AEDG K-12 - Baseline', 'NA', 'NA']
    rules << ['1', 'parkingDrivesLighting', 'AEDG K-12 - Baseline', 'NA', 'NA']
    rules << ['2', 'parkingDrivesLighting', 'AEDG K-12 - Baseline', 0.06 * baselineToTargetRatio, 1.0]
    rules << ['3', 'parkingDrivesLighting', 'AEDG K-12 - Baseline', 0.1 * baselineToTargetRatio, 1.0]
    rules << ['4', 'parkingDrivesLighting', 'AEDG K-12 - Baseline', 0.1 * baselineToTargetRatio, 1.0]

    # walkwayPlazaSpecialLighting Baseline
    # notes on controls: only astronomical
    rules << ['0', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Baseline', 'NA', 'NA']
    rules << ['1', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Baseline', 'NA', 'NA']
    rules << ['2', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Baseline', 0.16 * baselineToTargetRatio, 1.0]
    rules << ['3', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Baseline', 0.14 * baselineToTargetRatio, 1.0]
    rules << ['4', 'walkwayPlazaSpecialLighting', 'AEDG K-12 - Baseline', 0.14 * baselineToTargetRatio, 1.0]

    # make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]} #{rule[2]}"] = { 'LPD_ip' => rule[3], 'setbackFraction' => rule[4] }
    end

    # flag for roof surface type for tips
    facadeLandscapeLightingFlag = false
    parkingDrivesLightingFlag = false
    walkwayPlazaSpecialLightingFlag = false

    # get starting exterior lighting value
    getExteriorLightsValue = OsLib_LightingAndEquipment.getExteriorLightsValue(model)

    # reporting initial condition of model
    runner.registerInitialCondition("The initial model had #{getExteriorLightsValue['exterior_lights'].size} exterior lights with a total power of #{getExteriorLightsValue['exteriorLightingPower']} Watts.")

    # remove exterior lights
    lightsRemoved = OsLib_LightingAndEquipment.removeAllExteriorLights(model, runner)

    # TODO: - later could calculate good default value for facade lights, and possibly smart defaults based on building size

    # add facade lights
    if facadeLandscapeLighting > 0
      addExteriorLights_inputs = {
        'name' => 'Exterior Lights - Facade',
        'power' => rulesHash["#{lightingZone} facadeLandscapeLighting #{target}"]['LPD_ip'] * facadeLandscapeLighting,
        'setbackStartTime' => 0,
        'setbackEndTime' => 6,
        'setbackFraction' => rulesHash["#{lightingZone} facadeLandscapeLighting #{target}"]['setbackFraction']
      }
      facadeLights = OsLib_LightingAndEquipment.addExteriorLights(model, runner, addExteriorLights_inputs)
      facadeLandscapeLightingFlag = true
    end

    # add parking lights
    if parkingDrivesLighting > 0
      addExteriorLights_inputs = {
        'name' => 'Exterior Lights - Parking',
        'power' => rulesHash["#{lightingZone} parkingDrivesLighting #{target}"]['LPD_ip'] * parkingDrivesLighting,
        'setbackStartTime' => 0,
        'setbackEndTime' => 6,
        'setbackFraction' => rulesHash["#{lightingZone} parkingDrivesLighting #{target}"]['setbackFraction']
      }
      parkingLights = OsLib_LightingAndEquipment.addExteriorLights(model, runner, addExteriorLights_inputs)
      parkingDrivesLightingFlag = true
    end

    # add walkway lights
    if walkwayPlazaSpecialLighting > 0
      addExteriorLights_inputs = {
        'name' => 'Exterior Lights - Walkway',
        'power' => rulesHash["#{lightingZone} walkwayPlazaSpecialLighting #{target}"]['LPD_ip'] * walkwayPlazaSpecialLighting,
        'setbackStartTime' => 0,
        'setbackEndTime' => 6,
        'setbackFraction' => rulesHash["#{lightingZone} walkwayPlazaSpecialLighting #{target}"]['setbackFraction']
      }
      walkwayLights = OsLib_LightingAndEquipment.addExteriorLights(model, runner, addExteriorLights_inputs)
      walkwayPlazaSpecialLightingFlag = true
    end

    # get building to add cost to
    building = model.getBuilding

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0

    # add cost to building
    if costTotalExteriorLights > 0
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost('Exterior Lights', building, costTotalExteriorLights, 'CostPerEach', 'Construction', expected_life, years_until_costs_start)
      lcc_mat_TotalCost = lcc_mat.get.totalCost
    else
      lcc_mat_TotalCost = 0
    end

    # populate AEDG tip keys
    aedgTips = []

    # note: the K12 AEDG doesn't mention EL20 or EL24 but they both seem relevant.

    if facadeLandscapeLightingFlag
      aedgTips.push('EL20', 'EL23', 'EL24', 'EL25')
    end
    if parkingDrivesLightingFlag
      aedgTips.push('EL20', 'EL21', 'EL24', 'EL25')
    end
    if walkwayPlazaSpecialLightingFlag
      aedgTips.push('EL20', 'EL22', 'EL24', 'EL25')
    end

    # create not applicable of no constructions were tagged to change
    if aedgTips.empty? && !lightsRemoved
      runner.registerAsNotApplicable('No exterior lights were added to the model, and no lights were removed.')
      return true
    end

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips('K12', aedgTips.uniq.sort, runner)
    if !aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    # get final exterior lighting value
    getExteriorLightsValue = OsLib_LightingAndEquipment.getExteriorLightsValue(model)

    # reporting final condition of model
    # todo - add cost to final condition
    runner.registerFinalCondition("The final model had #{getExteriorLightsValue['exterior_lights'].size} exterior lights with a total power of #{getExteriorLightsValue['exteriorLightingPower']} Watts. Cost of exterior lights are $#{OpenStudio.toNeatString(lcc_mat_TotalCost, 0, true)}. #{aedgTipsLong}")

    return true
  end
end

# this allows the measure to be use by the application
AedgK12ExteriorLighting.new.registerWithApplication
