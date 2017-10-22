  require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class ZEDGK12InteriorLighting_Test < MiniTest::Unit::TestCase

  
  def test_ZEDGK12InteriorLighting
     
    # create an instance of the measure
    measure = ZEDGK12InteriorLighting.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # open model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/SecondarySchoolCustomRef_01_0228.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal("material_cost_ip", arguments[0].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    material_cost_ip = arguments[0].clone
    assert(material_cost_ip.setValue(2.0))
    argument_map["material_cost_ip"] = material_cost_ip

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

end
