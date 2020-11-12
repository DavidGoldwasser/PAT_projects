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
class AedgK12InteriorLightingControls < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'AedgK12InteriorLightingControls'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for material and installation cost
    costTotal = OpenStudio::Measure::OSArgument.makeDoubleArgument('costTotal', true)
    costTotal.setDisplayName('Total cost for all Lighting Controls in the Building ($).')
    costTotal.setDefaultValue(0.0)
    args << costTotal

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
    costTotal = runner.getDoubleArgumentValue('costTotal', user_arguments)

    non_neg_args = ['costTotal']
    non_neg = OsLib_HelperMethods.checkDoubleAndIntegerArguments(runner, user_arguments, 'min' => 0.0, 'max' => nil, 'min_eq_bool' => true, 'max_eq_bool' => false, 'arg_array' => non_neg_args)
    if !non_neg then return false end

    # create not applicable flag if building doesn't have any lights.
    if model.getBuilding.lightingPower == 0
      runner.registerAsNotApplicable('The model does not appear to have interior lighting, the model will not be altered.')
      return true
    end

    # TODO: - add in a warning about luminaires or have this handle them as well.

    # get the initial range of light schedule values in the building for initial condition
    lightsHash = {} # key = existSch, value = newSch
    affectedSpaceTypeArray = []

    existMin = []
    existMax = []
    newMin = []
    newMax = []

    # make array of space and space types to loop through
    spacesAndSpaceTypes = []
    model.getSpaceTypes.each do |spaceType|
      if !spaceType.spaces.empty?
        spacesAndSpaceTypes << spaceType
        affectedSpaceTypeArray << spaceType
      end
    end
    model.getSpaces.each do |space|
      spacesAndSpaceTypes << space
    end

    # loop through used space types and spaces
    spacesAndSpaceTypes.each do |object|
      # only alter space types that are used
      if !object.to_SpaceType.empty?
        next if object.to_SpaceType.get.spaces.size <= 0
      end

      lights = object.lights
      lights.each do |light|
        # get schedule
        if !light.schedule.empty?
          existSch = light.schedule.get

          # can't process if not ruleset
          if existSch.to_ScheduleRuleset.empty?
            runner.registerWarning("#{existSch.name} isn't a ruleset schedule. It can't be altered by this measure.")
            next
          end

          # update schedule
          if lightsHash.key?(existSch)
            # connect light to new schedule
            light.setSchedule(lightsHash[existSch])
          else

            # make new schedule
            newSchedule = existSch.clone(model).to_ScheduleRuleset.get
            newSchedule.setName("#{existSch.name} - Controls Reduction")

            # connect to lights
            light.setSchedule(newSchedule)

            # edit schedule
            OsLib_Schedules.simpleScheduleValueAdjust(model, newSchedule, 0.85, modificationType = 'Percentage')

            # add info to hash
            lightsHash[existSch] = newSchedule

            # get sch values from new and old schedules to use in initial and final condition
            existMinMax = OsLib_Schedules.getMinMaxAnnualProfileValue(model, existSch.to_ScheduleRuleset.get)
            existMin <<  existMinMax['min']
            existMax <<  existMinMax['max']
            newMinMax = OsLib_Schedules.getMinMaxAnnualProfileValue(model, newSchedule)
            newMin <<  newMinMax['min']
            newMax <<  newMinMax['max']
          end

        else
          runner.registerWarning("Can't find schedule for #{light.name} in #{object.name}. Won't attempt to create schedule for it.")
        end
      end
    end

    affectedSpaceTypeArray.each do |spaceType|
      runner.registerInfo("Adjusting lighting schedules for #{spaceType.name}.")
    end

    # reporting initial condition of model
    runner.registerInitialCondition("Fractional schedule values for lights in the initial model range from #{OpenStudio.toNeatString(existMin.min, 2, true)} to #{OpenStudio.toNeatString(existMax.max, 2, true)}.")

    # get building to add cost to
    building = model.getBuilding

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0

    # add cost to building
    if costTotal > 0
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost('Interior Lighting Controls', building, costTotal, 'CostPerEach', 'Construction', expected_life, years_until_costs_start)
      lcc_mat_TotalCost = lcc_mat.get.totalCost
    else
      lcc_mat_TotalCost = 0
    end

    # populate AEDG tip keys
    aedgTips = ['EL08', 'EL09', 'EL11', 'EL12', 'EL13', 'EL14', 'EL15', 'EL16', 'EL17', 'EL18', 'EL19', 'EL20']

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips('K12', aedgTips.uniq.sort, runner)
    if !aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    # reporting final condition of model
    if lcc_mat_TotalCost > 0
      runner.registerFinalCondition("Fractional schedule values for lights in the final model range from #{OpenStudio.toNeatString(newMin.min, 2, true)} to #{OpenStudio.toNeatString(newMax.max, 2, true)}. The cost for these control improvements is $#{OpenStudio.toNeatString(lcc_mat_TotalCost, 2, true)}. #{aedgTipsLong}")
    else
      runner.registerFinalCondition("Fractional schedule values for lights in the final model range from #{OpenStudio.toNeatString(newMin.min, 2, true)} to #{OpenStudio.toNeatString(newMax.max, 2, true)}. #{aedgTipsLong}")
    end

    return true
  end
end

# this allows the measure to be use by the application
AedgK12InteriorLightingControls.new.registerWithApplication
