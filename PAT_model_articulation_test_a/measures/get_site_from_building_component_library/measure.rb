# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class GetSiteFromBuildingComponentLibrary < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Get Site from Building Component Library"
  end

  # human readable description
  def description
    return "Populate choice list from BCL, then selected site will be brought into model. This will include the weather file, design days, and water main temperatures."
  end

  # human readable description of modeling approach
  def modeler_description
    return "To start with measure will hard code a string to narrow the search. Then a shorter list than all weather files on BCL will be shown. In the future woudl be nice to select region based on climate zone set in building object."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Make argument for zipcode
    zipcode = OpenStudio::Ruleset::OSArgument.makeIntegerArgument("zipcode", true)
    zipcode.setDisplayName("Zip Code for project")
    zipcode.setDescription("Enter valid us 8 digit zipcode")
    zipcode.setDefaultValue(80401)
    args << zipcode

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    zipcode = runner.getIntegerArgumentValue("zipcode",user_arguments)
    # todo - validate that argument 5 digit number, but that doesn't mean it is valid zip code
    # todo - some site objects don't have design days or stat files, those should trigger warning

    # zipcode site lookup and download
    remote = OpenStudio::RemoteBCL.new
    responses = remote.searchComponentLibrary("location:#{zipcode}", "Site")

    # look for TMY3 if in responses
    uid = nil
    responses.each_with_index do |response,i|
      # list results for diagnostic purposes
      runner.registerInfo("Response #{i} is #{response.name}")
      next if not response.name.include?("TMY3")
      next if not uid.nil?
      uid = response.uid
    end
    if uid.nil? then uid = responses.first.uid end

    runner.registerInfo("uid is #{uid}")
    remote.downloadComponent(uid)
    component = remote.waitForComponentDownload()

    if component.empty?
      runner.registerError("Cannot find local component")
      return false
    end
    component = component.get

    # get epw file
    files = component.files("epw")
    if files.empty?
      runner.registerError("No epw file found")
      return false
    end
    epw_path = component.files("epw")[0]

    # parse epw file
    epw_file = OpenStudio::EpwFile.new(OpenStudio::Path.new(epw_path))
    puts "hello"
    puts epw_file

    # report initial condition of model
    if model.weatherFile.is_initialized and model.weatherFile.get.path.is_initialized
      runner.registerInitialCondition("Current weather file is #{model.weatherFile.get.path.get}")
    else
      runner.registerInitialCondition("The model doesn't have a weather file assigned.")
    end

    # OpenStudio is letting multiple site, waterMain and weatherFile objects in model, delete those if they exist along with design days
    # todo - add in test of model with site shading srufaces, and see if they are orphaned or associated with new site.
    model.getSite.remove
    model.getSiteWaterMainsTemperature.remove
    if model.weatherFile.is_initialized
      model.weatherFile.remove
    end
    model.getDesignDays.each(&:remove)

    # get osc file
    osc_files = component.files("osc")
    if osc_files.empty?
      runner.registerError("No osc file found")
      return false
    end
    osc_path = component.files("osc")[0]
    osc_file = OpenStudio::IdfFile::load(osc_path)
    vt = OpenStudio::OSVersion::VersionTranslator.new
    component_object = vt.loadComponent(OpenStudio::Path.new(osc_path))

    # load os file
    if component_object.empty?
      runner.registerError("Cannot load construction component '#{osc_file}'")
      return false
    else
      object = component_object.get.primaryObject
      if object.to_Site.empty?
        runner.registerError("Component '#{osc_file}' does not include a site object")
        return false
      else
        componentData = model.insertComponent(component_object.get)
        if componentData.empty?
          runner.registerError("Failed to insert component '#{osc_file}' into model")
          return false
        else
          new_site_object = componentData.get.primaryComponentObject.to_Site.get
          runner.registerInfo("added site object named #{new_site_object.name}")
          site_water_main_temp = model.getSiteWaterMainsTemperature
          if site_water_main_temp.annualAverageOutdoorAirTemperature.is_initialized and site_water_main_temp.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.is_initialized
            avg_temp = site_water_main_temp.annualAverageOutdoorAirTemperature.get
            max_diff_monthly_avg_temp = site_water_main_temp.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.get
            avg_temp_ip = OpenStudio::convert(avg_temp,"C","F").get
            max_diff_monthly_avg_temp_ip = OpenStudio::convert(max_diff_monthly_avg_temp,"C","F").get
            runner.registerInfo("SiteWaterMainsTemperature object has Annual Avg. Outdoor Air Temp. of #{avg_temp_ip.round(2)} and Max. Diff. in Monthly Avg. Outdoor Air Temp. of #{max_diff_monthly_avg_temp_ip.round(2)}.")
          else
            runner.registerWarning("SiteWaterMainsTemperature object is missing Annual Avg. Outdoor Air Temp. or Max. Diff.in Monthly Avg. Outdoor Air Temp. set.")
          end
          if model.getDesignDays.size > 0
            runner.registerInfo("The model has #{model.getDesignDays.size} DesignDay objects")
          else
            runner.registerWarning("The model has #{model.getDesignDays.size} DesignDay objects")
          end

        end
      end
    end

    # get epw file
    epw_files = component.files("epw")
    if files.empty?
      runner.registerError("No epw file found")
      return false
    end
    epw_path = component.files("epw")[0]

    # parse epw file
    epw_file = OpenStudio::EpwFile.new(OpenStudio::Path.new(epw_path))

    # set weather file (this sets path to BCL diretory vs. temp zip file without this)
    OpenStudio::Model::WeatherFile::setWeatherFile(model, epw_file)

    # get stat file
    stat_path = OpenStudio::Path.new(component.files("stat")[0])
    text = nil
    File.open(component.files("stat")[0]) do |f|
      text = f.read.force_encoding('iso-8859-1')
    end

    # Get Climate zone.
    # - Climate type "3B" (ASHRAE Standard 196-2006 Climate Zone)**
    # - Climate type "6A" (ASHRAE Standards 90.1-2004 and 90.2-2004 Climate Zone)**
    regex = /Climate type \"(.*?)\" \(ASHRAE Standards?(.*)\)\*\*/
    match_data = text.match(regex)
    if match_data.nil?
      runner.registerWarning("Can't find ASHRAE climate zone in stat file.")
    else
      climate_zone = match_data[1].to_s.strip
      standard = match_data[2].to_s.strip # could confirm it is 196-2006 Climate Zone
      model.getClimateZones.setClimateZone("ASHRAE",climate_zone)
      runner.registerInfo("Setting ASHRAE Climate Zone to #{climate_zone}")
    end

    # report final condition of model
    if model.weatherFile.is_initialized and model.weatherFile.get.path.is_initialized
      runner.registerFinalCondition("Current weather file is #{model.weatherFile.get.path.get}")
    else
      runner.registerFinalCondition("The model doesn't have a weather file assigned.")
    end

    return true

  end
  
end

# register the measure to be used by the application
GetSiteFromBuildingComponentLibrary.new.registerWithApplication
