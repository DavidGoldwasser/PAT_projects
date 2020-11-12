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
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class AedgSmallToMediumOfficeExteriorLighting_Test < Minitest::Test
  def test_AedgSmallToMediumOfficeExteriorLighting
    # create an instance of the measure
    measure = AedgSmallToMediumOfficeExteriorLighting.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/0210_SimpleSchool_d_123_dev.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal('target', arguments[0].name)
    assert_equal('lightingZone', arguments[1].name)
    assert_equal('facadeLandscapeLighting', arguments[2].name)
    assert_equal('parkingDrivesLighting', arguments[3].name)
    assert_equal('walkwayPlazaSpecialLighting', arguments[4].name)
    assert_equal('costTotalExteriorLights', arguments[5].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    target = arguments[0].clone
    assert(target.setValue('AEDG SmMdOff - Target'))
    argument_map['target'] = target
    lightingZone = arguments[1].clone
    assert(lightingZone.setValue('2 - Residential, Mixed Use'))
    argument_map['lightingZone'] = lightingZone
    facadeLandscapeLighting = arguments[2].clone
    assert(facadeLandscapeLighting.setValue(1000.0))
    argument_map['facadeLandscapeLighting'] = facadeLandscapeLighting
    parkingDrivesLighting = arguments[3].clone
    assert(parkingDrivesLighting.setValue(10000.0))
    argument_map['parkingDrivesLighting'] = parkingDrivesLighting
    walkwayPlazaSpecialLighting = arguments[4].clone
    assert(walkwayPlazaSpecialLighting.setValue(5000.0))
    argument_map['walkwayPlazaSpecialLighting'] = walkwayPlazaSpecialLighting
    costTotalExteriorLights = arguments[5].clone
    assert(costTotalExteriorLights.setValue(15000.0))
    argument_map['costTotalExteriorLights'] = costTotalExteriorLights
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 1)
    # assert(result.info.size == 2)
  end
end
