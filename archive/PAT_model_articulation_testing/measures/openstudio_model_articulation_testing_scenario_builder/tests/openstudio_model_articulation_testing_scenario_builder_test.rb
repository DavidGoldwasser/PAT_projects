require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class OpenStudioModelArticulationTestingScenarioBuilder_Test < MiniTest::Test


  def run_dir(test_name)

    # will make directory if it doesn't exist
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir

    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  # method for running the test simulation using OpenStudio 2.x API
  def setup_test_2(test_name,model_path)
    osw_path = File.join(run_dir(test_name), 'in.osw')
    osw_path = File.absolute_path(osw_path)

    workflow = OpenStudio::WorkflowJSON.new
    workflow.setSeedFile(File.absolute_path(model_path))
    workflow.saveAs(osw_path)

    cli_path = OpenStudio.getOpenStudioCLI
    cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
    puts cmd
    system(cmd)
  end

  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)

    # create an instance of the measure
    measure = OpenStudioModelArticulationTestingScenarioBuilder.new

    # copy osw into output dir
    base_osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osw")
    new_osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}/data_point.osw")
    unless Dir.exists?(File.dirname(__FILE__) + "/output")
      Dir.mkdir(File.dirname(__FILE__) + "/output")
    end
    unless Dir.exists?(File.dirname(__FILE__) + "/output/#{test_name}")
      Dir.mkdir(File.dirname(__FILE__) + "/output/#{test_name}")
    end

    # modify measure and file paths for test
    new_osw = nil
    File.open(base_osw_path.to_s, 'r') do |f|
      new_osw = JSON::parse(f.read, :symbolize_names => true)
    end
    new_osw[:measure_paths] = ["../../../nrel_published","../../../nrel_dev"]
    new_osw[:file_paths] = [""]
    File.open(new_osw_path.to_s, 'w') do |f|
      f << JSON.pretty_generate(new_osw)
    end

    # create an instance of a runner with OSW
    osw = OpenStudio::WorkflowJSON.load(new_osw_path).get
    runner = OpenStudio::Ruleset::OSRunner.new(osw)

    if model_name.nil?
      # make an empty model
      model = OpenStudio::Model::Model.new
    else
      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      path = OpenStudio::Path.new(File.dirname(__FILE__) + "/" + model_name)
      model = translator.loadModel(path)
      assert((not model.empty?))
      model = model.get
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Ruleset.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args.has_key?(arg.name)
        assert(temp_arg_var.setValue(args[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # temporarily change directory to the run directory and run the measure (because of sizing run)
    start_dir = Dir.pwd
    begin
      unless Dir.exists?(run_dir(test_name))
        Dir.mkdir(run_dir(test_name))
      end
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(model, runner, argument_map)
      result = runner.result

    ensure
      Dir.chdir(start_dir)

      # delete sizing run dir
      #FileUtils.rm_rf(run_dir(test_name))
    end

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    # check count of warning and info messages
    unless info_count.nil? then assert(result.info.size == info_count) end
    unless warnings_count.nil? then assert(result.warnings.size == warnings_count) end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}/test_output.osm")
    model.save(output_file_path,true)

    # optionally run simulation of resulting model
    #epw_path = model.weatherFile.get.url
    setup_test_2(test_name,output_file_path.to_s)

    # make sure the report file exists
    output_html_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}/reports/eplustbl.html")
    assert(File.exist?(output_html_path.to_s))

  end

  def test_fsr_0
    args = {}
    args["building_type"] = "FullServiceRestaurant"
    # using defaults values from measure.rb for other arguments

    apply_measure_to_model(__method__.to_s.gsub('test_',''), args, 'example_model.osm',nil,nil)
  end

  def test_fsr_1

    args = {}
    args["building_type"] = "FullServiceRestaurant"
    args["scenario"] = "s1 Prototype - const"
    # using defaults values from measure.rb for other arguments

    apply_measure_to_model(__method__.to_s.gsub('test_',''), args, 'example_model.osm',nil,nil)
  end

  def test_fsr_2

    args = {}
    args["building_type"] = "FullServiceRestaurant"
    args["scenario"] = "s2 Prototype - loads"
    # using defaults values from measure.rb for other arguments

    apply_measure_to_model(__method__.to_s.gsub('test_',''), args, 'example_model.osm',nil,nil)
  end

  def test_fsr_3

    args = {}
    args["building_type"] = "FullServiceRestaurant"
    args["scenario"] = "s3 Prototype - swh exhaust"
    # using defaults values from measure.rb for other arguments

    apply_measure_to_model(__method__.to_s.gsub('test_',''), args, 'example_model.osm',nil,nil)
  end

  def test_fsr_4

    args = {}
    args["building_type"] = "FullServiceRestaurant"
    args["scenario"] = "s4 Prototype - setpoints"
    # using defaults values from measure.rb for other arguments

    apply_measure_to_model(__method__.to_s.gsub('test_',''), args, 'example_model.osm',nil,nil)
  end

  def test_fsr_5

    args = {}
    args["building_type"] = "FullServiceRestaurant"
    args["scenario"] = "s5 Prototype - hvac"
    # using defaults values from measure.rb for other arguments

    apply_measure_to_model(__method__.to_s.gsub('test_',''), args, 'example_model.osm',nil,nil)
  end

end
