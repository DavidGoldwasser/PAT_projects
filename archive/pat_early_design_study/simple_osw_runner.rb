Shoes.app :title => "Simple OSW Runner" do

  require 'json'
  require 'fileutils'

  # select file
  alert "Select an OpenStudio Workflow."
  sel = ask_open_file title: "Select OpenStudio Workflow (OSW) file"

  # openstudio command doesn't work here without the path
  @openstudio_path = "/Applications/OpenStudio-2.8.0/"
  @osw_path = sel
  @osw_file = sel.split("/").last
  @osw_dir = "#{sel.gsub(@osw_file,"/")}"
  @out_path = "#{sel.gsub(@osw_file,"/out.osw")}"

  # checkbox to run measures only
  background lemonchiffon
  tagline "Options"
  flow {@c_m = check; para "Run Measures Only"}  
  flow {@c_r = check; para "Force Re-run"} 

  # parse osw
  in_osw = nil
  File.open(@osw_path, 'r') do |f|
    in_osw = JSON::parse(f.read, :symbolize_names => true)
  end

  @display = stack do 
    # report seed and weather file
    tagline "OSW files"
    para in_osw[:seed_file]
    para in_osw[:weather_file]
    # loop through steps
    tagline "Measures in Workflow"
    in_osw[:steps].each do |step|
      para step[:name]
    end
  end
   
  # button to run workflow
  button "Run Selected OpenStudio Workflow" do
    @display.clear
    @display = stack do

      # run workflow if necessary
      if @c_r.checked? || File.file?(@out_path) == false
        para "Running OSW using the OpenStudio CLI."
        if ! @c_m.checked?
          command_string = "#{@openstudio_path}bin/openstudio run -w #{@osw_path}"
        else
          command_string = "#{@openstudio_path}bin/openstudio run -m -w #{@osw_path}"
        end
        debug(command_string)
        system(command_string)
        systray title: "Simple OSW Runner", message: "OpenStudio Early Desing Workflow Has finished", icon: "#{DIR}/static/shoes-icon.png"
        para "Finished Running Simulation."
      else
        para "Showing results from prior workflow run."
      end

      # buttons for HTML reports
      if ! @c_m.checked?
        stack do 
          tagline "Available Reports"
          # loop throug reports
          Dir["#{@osw_dir}reports/*"].each do |file|
            short_name = file.split("/").last.gsub(".html","")
            next if short_name.include?(".json")
            button short_name do
              system("open #{file}")
            end
          end  
        end
      else
        para "Finished Running Measures Only."
      end

      # show initial and final conditions
      out_osw = nil
      File.open(@out_path, 'r') do |f|
        out_osw = JSON::parse(f.read, :symbolize_names => true)
      end

      # loop through steps
      tagline "Workflow Results Summary"
      out_osw[:steps].each do |step|
        para "#{step[:name]}: #{step[:result][:step_result]}"
        @init = inscription "initial: #{step[:result][:step_initial_condition]}"
        @final = inscription "final: #{step[:result][:step_final_condition]}"
        @init.stroke = darkgreen #darkolivegreen
        @final.stroke = darkred#sienna
      end
    end
    @display.refresh()
  end

  # add core functionality by altering OSW based on user input
  # todo - enable change of seed model
  # todo - enable change of argument for location (better address weather file)
  # make use site from BCL meausre if it seems reliable
  # todo - make bool for each measure in workflow
  # todo - expose arguments from OSW and ability to change them
  # todo - test out packaging with resoruces like measures, seed and weather
  # todo - error checking for failed workflow or failed simulations

end