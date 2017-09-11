require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'

require 'minitest/autorun'

require_relative '../measure.rb'

require 'fileutils'

class ChangeBuildingLocation_Test < MiniTest::Unit::TestCase
  def test_weather_file
    test_out_file = File.join(File.dirname(__FILE__), 'output', 'test_out.osm')
    FileUtils.rm_f test_out_file if File.exist? test_out_file

    #test_new_weather_file = 'another_weather_file.epw'
    test_new_weather_file = 'USA_MA_Boston-Logan.Intl.AP.725090_TMY3.epw'

    # create an instance of the measure
    measure = ChangeBuildingLocation.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = File.join(File.dirname(__FILE__), "test.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # convert this to measure attributes
    if model.weatherFile.empty?
      puts "No weather file in current model"
    else
      puts "Current weather file is #{model.weatherFile}"# unless model.weatherFile.empty?
    end

    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)

    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1
    arg = arguments[count += 1].clone
    assert(arg.setValue(File.dirname(__FILE__)))
    argument_map["weather_directory"] = arg

    arg = arguments[count += 1].clone
    assert(arg.setValue(test_new_weather_file))
    argument_map["weather_file_name"] = arg

    arg = arguments[count += 1].clone
    assert(arg.setValue('5B'))
    argument_map["climate_zone"] = arg

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 0, "Warnings are greater than 0")
    #assert(result.info.size == 2)

    assert(model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).count == 3, "Expected only 3 design day objects")

    puts "Final weather file is #{model.weatherFile.get}" unless model.weatherFile.empty?
    puts "Final site data is #{model.getSite}" if model.getSite
    puts "Final Water Mains Temp is #{model.getSiteWaterMainsTemperature}" if model.getSiteWaterMainsTemperature
    model.save(test_out_file)

    assert(File.basename(model.weatherFile.get.path.get.to_s) == test_new_weather_file)
    if test_new_weather_file =~ /Boston/
      assert(model.getSite.latitude == 42.37)
      assert(model.getSite.longitude == -71.02)
    else
      assert(model.getSite.latitude == 45)
      assert(model.getSite.longitude == -45)
    end
  end

  def test_weather_file_WA_Renton
    test_out_file = File.join(File.dirname(__FILE__), 'output', 'test_WA_Renton.osm')
    FileUtils.rm_f test_out_file if File.exist? test_out_file

    #test_new_weather_file = 'another_weather_file.epw'
    test_new_weather_file = 'USA_WA_Renton.Muni.AP.727934_TMY3.epw'

    # create an instance of the measure
    measure = ChangeBuildingLocation.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = File.join(File.dirname(__FILE__), "test.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # convert this to measure attributes
    if model.weatherFile.empty?
      puts "No weather file in current model"
    else
      puts "Current weather file is #{model.weatherFile}"# unless model.weatherFile.empty?
    end

    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)

    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1
    arg = arguments[count += 1].clone
    assert(arg.setValue(File.dirname(__FILE__)))
    argument_map["weather_directory"] = arg

    arg = arguments[count += 1].clone
    assert(arg.setValue(test_new_weather_file))
    argument_map["weather_file_name"] = arg

    arg = arguments[count += 1].clone
    assert(arg.setValue('5B'))
    argument_map["climate_zone"] = arg

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 0, "Warnings are greater than 0")
    #assert(result.info.size == 2)

    #assert(model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).count == 3, "Expected only 3 design day objects")

    puts "Final weather file is #{model.weatherFile.get}" unless model.weatherFile.empty?
    puts "Final site data is #{model.getSite}" if model.getSite
    puts "Final Water Mains Temp is #{model.getSiteWaterMainsTemperature}" if model.getSiteWaterMainsTemperature
    #model.save(test_out_file) # this was causing test on rake test:unit:all

    assert(File.basename(model.weatherFile.get.path.get.to_s) == test_new_weather_file)
  end

  def test_multiyear_weather_file
    test_out_file = File.join(File.dirname(__FILE__), 'output', 'test_out_mulityear.osm')
    FileUtils.rm_f test_out_file if File.exist? test_out_file

    #test_new_weather_file = 'another_weather_file.epw'
    test_new_weather_file = 'multiyear.epw'

    # create an instance of the measure
    measure = ChangeBuildingLocation.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = File.join(File.dirname(__FILE__), "test.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # convert this to measure attributes
    if model.weatherFile.empty?
      puts "No weather file in current model"
    else
      puts "Current weather file is #{model.weatherFile}"# unless model.weatherFile.empty?
    end

    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)

    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1
    arg = arguments[count += 1].clone
    assert(arg.setValue(File.dirname(__FILE__)))
    argument_map["weather_directory"] = arg

    arg = arguments[count += 1].clone
    assert(arg.setValue(test_new_weather_file))
    argument_map["weather_file_name"] = arg

    arg = arguments[count += 1].clone
    assert(arg.setValue('5B'))
    argument_map["climate_zone"] = arg

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 0, "Warnings are greater than 0")
    #assert(result.info.size == 2)

    assert(model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).count == 3, "Expected only 3 design day objects")

    puts "Final weather file is #{model.weatherFile.get}" unless model.weatherFile.empty?
    puts "Final site data is #{model.getSite}" if model.getSite
    puts "Final Water Mains Temp is #{model.getSiteWaterMainsTemperature}" if model.getSiteWaterMainsTemperature
    model.save(test_out_file)

    assert(File.basename(model.weatherFile.get.path.get.to_s) == test_new_weather_file)
    if test_new_weather_file =~ /Boston/
      assert(model.getSite.latitude == 42.37)
      assert(model.getSite.longitude == -71.02)
    else
      assert(model.getSite.latitude == 41.678)
      assert(model.getSite.longitude == -70.937)
    end
  end

  def test_path_from_osw
    test_out_file = File.join(File.dirname(__FILE__), 'output', 'test_out_path_from_osw.osm')
    FileUtils.rm_f test_out_file if File.exist? test_out_file

    #test_new_weather_file = 'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw'
    test_new_weather_file = 'USA_MA_Boston-Logan.Intl.AP.725090_TMY3.epw' # seems to search directory of OSW even with empty file_paths

    # create an instance of the measure
    measure = ChangeBuildingLocation.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Ruleset::OSRunner.new(osw)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = File.join(File.dirname(__FILE__), "test.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # convert this to measure attributes
    if model.weatherFile.empty?
      puts "No weather file in current model"
    else
      puts "Current weather file is #{model.weatherFile}"# unless model.weatherFile.empty?
    end

    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)

    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = 0 # skipped weather_file_path for this test
    arg = arguments[count += 1].clone
    assert(arg.setValue(test_new_weather_file))
    argument_map["weather_file_name"] = arg

    arg = arguments[count += 1].clone
    assert(arg.setValue('5B'))
    argument_map["climate_zone"] = arg

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    assert(result.warnings.size == 0, "Warnings are greater than 0")
    #assert(result.info.size == 2)

    assert(model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).count == 3, "Expected only 3 design day objects")

    puts "Final weather file is #{model.weatherFile.get}" unless model.weatherFile.empty?
    puts "Final site data is #{model.getSite}" if model.getSite
    puts "Final Water Mains Temp is #{model.getSiteWaterMainsTemperature}" if model.getSiteWaterMainsTemperature
    model.save(test_out_file)

    assert(File.basename(model.weatherFile.get.path.get.to_s) == test_new_weather_file)

  end

  def test_weather_file_bad
    test_out_file = File.join(File.dirname(__FILE__), 'output', 'test_out.osm')
    FileUtils.rm_f test_out_file if File.exist? test_out_file

    #test_new_weather_file = 'another_weather_file.epw'
    test_new_weather_file = 'BadFileName.epw'

    # create an instance of the measure
    measure = ChangeBuildingLocation.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = File.join(File.dirname(__FILE__), "test.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # convert this to measure attributes
    if model.weatherFile.empty?
      puts "No weather file in current model"
    else
      puts "Current weather file is #{model.weatherFile}"# unless model.weatherFile.empty?
    end

    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)

    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1
    arg = arguments[count += 1].clone
    assert(arg.setValue(File.dirname(__FILE__)))
    argument_map["weather_directory"] = arg

    arg = arguments[count += 1].clone
    assert(arg.setValue(test_new_weather_file))
    argument_map["weather_file_name"] = arg

    arg = arguments[count += 1].clone
    assert(arg.setValue('5B'))
    argument_map["climate_zone"] = arg

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Fail")
    assert(result.warnings.size == 0, "Warnings are greater than 0")
    #assert(result.info.size == 2)

    model.save(test_out_file)

  end

end
