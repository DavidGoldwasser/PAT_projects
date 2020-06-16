# frozen_string_literal: true

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

require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"
require "#{File.dirname(__FILE__)}/test_support.rb"

require 'minitest/autorun'

class ZEDGK12HVAC_Test < Minitest::Test
  def test_ZEDGK12HVAC
    output_dir = OpenStudio::Path.new(File.dirname(__FILE__) + '/output')
    OpenStudio.removeDirectory(output_dir)
    Dir.mkdir(output_dir.to_s)

    osm_paths = Dir.glob(File.dirname(__FILE__) + '/*.osm')

    osm_paths.each do |string_path|
      path = OpenStudio::Path.new(string_path)

      # create an instance of the measure
      measure = ZEDGK12HVAC.new

      # create an instance of a runner
      runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      model = translator.loadModel(path)
      assert(!model.empty?)
      model = model.get

      # get arguments and test that they are what we are expecting
      arguments = measure.arguments(model)
      assert_equal(3, arguments.size)
      assert_equal('ceilingReturnPlenumSpaceType', arguments[0].name)
      assert_equal('costTotalHVACSystem', arguments[1].name)
      assert_equal('remake_schedules', arguments[2].name)

      # set argument values to good values and run the measure on model with spaces
      argument_map = OpenStudio::Measure::OSArgumentMap.new

      ceilingReturnPlenumSpaceType = arguments[0].clone
      assert(ceilingReturnPlenumSpaceType.setValue('Plenum'))
      argument_map['ceilingReturnPlenumSpaceType'] = ceilingReturnPlenumSpaceType

      costTotalHVACSystem = arguments[1].clone
      assert(costTotalHVACSystem.setValue(15000.0))
      argument_map['costTotalHVACSystem'] = costTotalHVACSystem

      remake_schedules = arguments[2].clone
      assert(remake_schedules.setValue(true))
      argument_map['remake_schedules'] = remake_schedules

      measure.run(model, runner, argument_map)
      result = runner.result
      show_output(result)
      assert(result.value.valueName == 'Success')

      # save the model for testing purposes
      # TODO: Convert this to using ruby paths, not OpenStudio
      output_model_dir = output_dir / OpenStudio::Path.new(path.stem)
      Dir.mkdir(output_model_dir.to_s)
      output_model_path = output_model_dir / OpenStudio::Path.new('test.osm')
      model.save(output_model_path, true)

      # sql = runSimulation(output_model_path)
      # totalSiteEnergy = sql.totalSiteEnergy();
      # assert(totalSiteEnergy);
      # assert(totalSiteEnergy.get < 1000000);
    end
  end
end
