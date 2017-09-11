require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class NetZeroK12FenestrationAndDaylightingControls_Test < MiniTest::Unit::TestCase

  
  def test_NetZeroK12FenestrationAndDaylightingControls
     
    # create an instance of the measure
    measure = NetZeroK12FenestrationAndDaylightingControls.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/SecondarySchoolCustomRef_01_0228.osm")
    #path = OpenStudio::Path.new(File.dirname(__FILE__) + "/DoorTest.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("cost_daylight_glazing", arguments[0].name)
    assert_equal("cost_view_glazing", arguments[1].name)
    assert_equal("cost_skylight", arguments[2].name)
    assert_equal("cost_shading_surface", arguments[3].name)
    assert_equal("cost_light_shelf", arguments[4].name)
    assert_equal("target", arguments[5].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    cost_daylight_glazing = arguments[0].clone
    assert(cost_daylight_glazing.setValue(0.0))
    argument_map["cost_daylight_glazing"] = cost_daylight_glazing

    cost_view_glazing = arguments[1].clone
    assert(cost_view_glazing.setValue(0.0))
    argument_map["cost_view_glazing"] = cost_view_glazing

    cost_skylight = arguments[2].clone
    assert(cost_skylight.setValue(0.0))
    argument_map["cost_skylight"] = cost_skylight

    cost_shading_surface = arguments[3].clone
    assert(cost_shading_surface.setValue(0.0))
    argument_map["cost_shading_surface"] = cost_shading_surface

    cost_light_shelf = arguments[4].clone
    assert(cost_light_shelf.setValue(0.0))
    argument_map["cost_light_shelf"] = cost_light_shelf

    target = arguments[5].clone
    assert(target.setValue("AEDG K-12 - Target"))
    argument_map["target"] = target

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 1)
    #assert(result.info.size == 2)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_output.osm")
    model.save(output_file_path,true)

  end

  def test_NetZeroK12FenestrationAndDaylightingControls_zedg

    # create an instance of the measure
    measure = NetZeroK12FenestrationAndDaylightingControls.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/SecondarySchoolCustomRef_01_0228.osm")
    #path = OpenStudio::Path.new(File.dirname(__FILE__) + "/DoorTest.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("cost_daylight_glazing", arguments[0].name)
    assert_equal("cost_view_glazing", arguments[1].name)
    assert_equal("cost_skylight", arguments[2].name)
    assert_equal("cost_shading_surface", arguments[3].name)
    assert_equal("cost_light_shelf", arguments[4].name)
    assert_equal("target", arguments[5].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    cost_daylight_glazing = arguments[0].clone
    assert(cost_daylight_glazing.setValue(0.0))
    argument_map["cost_daylight_glazing"] = cost_daylight_glazing

    cost_view_glazing = arguments[1].clone
    assert(cost_view_glazing.setValue(0.0))
    argument_map["cost_view_glazing"] = cost_view_glazing

    cost_skylight = arguments[2].clone
    assert(cost_skylight.setValue(0.0))
    argument_map["cost_skylight"] = cost_skylight

    cost_shading_surface = arguments[3].clone
    assert(cost_shading_surface.setValue(0.0))
    argument_map["cost_shading_surface"] = cost_shading_surface

    cost_light_shelf = arguments[4].clone
    assert(cost_light_shelf.setValue(0.0))
    argument_map["cost_light_shelf"] = cost_light_shelf

    target = arguments[5].clone
    assert(target.setValue("AEDG K-12 - ZEDG 2017"))
    argument_map["target"] = target

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 1)
    #assert(result.info.size == 2)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_output_zedg.osm")
    model.save(output_file_path,true)

  end

  def test_NetZeroK12FenestrationAndDaylightingControls_zedg_daylighting

    # create an instance of the measure
    measure = NetZeroK12FenestrationAndDaylightingControls.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/SecondarySchoolCustomRef_01_0228.osm")
    #path = OpenStudio::Path.new(File.dirname(__FILE__) + "/DoorTest.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal("cost_daylight_glazing", arguments[0].name)
    assert_equal("cost_view_glazing", arguments[1].name)
    assert_equal("cost_skylight", arguments[2].name)
    assert_equal("cost_shading_surface", arguments[3].name)
    assert_equal("cost_light_shelf", arguments[4].name)
    assert_equal("target", arguments[5].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    cost_daylight_glazing = arguments[0].clone
    assert(cost_daylight_glazing.setValue(0.0))
    argument_map["cost_daylight_glazing"] = cost_daylight_glazing

    cost_view_glazing = arguments[1].clone
    assert(cost_view_glazing.setValue(0.0))
    argument_map["cost_view_glazing"] = cost_view_glazing

    cost_skylight = arguments[2].clone
    assert(cost_skylight.setValue(0.0))
    argument_map["cost_skylight"] = cost_skylight

    cost_shading_surface = arguments[3].clone
    assert(cost_shading_surface.setValue(0.0))
    argument_map["cost_shading_surface"] = cost_shading_surface

    cost_light_shelf = arguments[4].clone
    assert(cost_light_shelf.setValue(0.0))
    argument_map["cost_light_shelf"] = cost_light_shelf

    target = arguments[5].clone
    assert(target.setValue("AEDG K-12 - ZEDG 2017 with Daylighting"))
    argument_map["target"] = target

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 1)
    #assert(result.info.size == 2)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_output_zedg_daylighting.osm")
    model.save(output_file_path,true)

  end

end