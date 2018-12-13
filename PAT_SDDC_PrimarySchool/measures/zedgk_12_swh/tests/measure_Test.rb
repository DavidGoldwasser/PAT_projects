require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class ZEDGK12SWH_Test < MiniTest::Unit::TestCase

  
  def test_ZEDGK12SWH
     
    # create an instance of the measure
    measure = ZEDGK12SWH.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/AEDG_HVAC_GenericTestModel_0225_a.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    puts arguments
    assert_equal(2, arguments.size)
    assert_equal("costTotalSwhSystem", arguments[0].name)
    assert_equal("numberOfStudents", arguments[1].name)
       
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    costTotalSwhSystem = arguments[0].clone
    assert(costTotalSwhSystem.setValue(10000.0))
    argument_map["costTotalSwhSystem"] = costTotalSwhSystem

    numberOfStudents = arguments[1].clone
    assert(numberOfStudents.hasDefaultValue)
    assert(numberOfStudents.setValue(numberOfStudents.defaultValueAsInteger))
    #assert(numberOfStudents.setValue(123))
    argument_map["numberOfStudents"] = numberOfStudents

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 1)
    #assert(result.info.size == 2)

    #save the model for testing purposes
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test.osm")
    model.save(output_file_path,true)
    
  end  

end
