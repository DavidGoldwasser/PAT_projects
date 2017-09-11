require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'

require_relative '../measure.rb'

class NetZeroK12PlantComponentTemperatureSourceEMS_Test < MiniTest::Unit::TestCase

  # def setup
  # end

  # def teardown

  def test_good_argument_values

    # create an instance of the measure
    measure = NetZeroK12PlantComponentTemperatureSourceEMS.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the last model
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new("#{File.dirname(__FILE__)}/test_model.osm"))

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test_model.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal("Success", result.value.valueName)
    
    # save the workspace to output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_output.idf")
    workspace.save(output_file_path,true)
  end

end
