require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class AedgSmallToMediumOfficeExteriorLighting_Test < MiniTest::Unit::TestCase

  
  def test_AedgSmallToMediumOfficeExteriorLighting
     
    # create an instance of the measure
    measure = AedgSmallToMediumOfficeExteriorLighting.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/0210_SimpleSchool_d_123_dev.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("target", arguments[0].name)
    assert_equal("lightingZone", arguments[1].name)
    assert_equal("facadeLandscapeLighting", arguments[2].name)
    assert_equal("parkingDrivesLighting", arguments[3].name)
    assert_equal("walkwayPlazaSpecialLighting", arguments[4].name)
    assert_equal("costTotalExteriorLights", arguments[5].name)
       
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    target = arguments[0].clone
    assert(target.setValue("AEDG SmMdOff - Target"))
    argument_map["target"] = target
    lightingZone = arguments[1].clone
    assert(lightingZone.setValue("2 - Residential, Mixed Use"))
    argument_map["lightingZone"] = lightingZone
    facadeLandscapeLighting = arguments[2].clone
    assert(facadeLandscapeLighting.setValue(1000.0))
    argument_map["facadeLandscapeLighting"] = facadeLandscapeLighting
    parkingDrivesLighting = arguments[3].clone
    assert(parkingDrivesLighting.setValue(10000.0))
    argument_map["parkingDrivesLighting"] = parkingDrivesLighting
    walkwayPlazaSpecialLighting = arguments[4].clone
    assert(walkwayPlazaSpecialLighting.setValue(5000.0))
    argument_map["walkwayPlazaSpecialLighting"] = walkwayPlazaSpecialLighting
    costTotalExteriorLights = arguments[5].clone
    assert(costTotalExteriorLights.setValue(15000.0))
    argument_map["costTotalExteriorLights"] = costTotalExteriorLights
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 1)
    #assert(result.info.size == 2)

  end  

end
