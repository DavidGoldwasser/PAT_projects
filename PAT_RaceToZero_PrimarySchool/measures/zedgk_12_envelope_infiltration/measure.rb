#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"
require "#{File.dirname(__FILE__)}/resources/os_lib_outdoorair_and_infiltration"
require "#{File.dirname(__FILE__)}/resources/os_lib_schedules"

#start the measure
class ZEDGK12EnvelopeInfiltration < OpenStudio::Ruleset::ModelUserScript

  # include measure libraries
  include OsLib_AedgMeasures
  include OsLib_HelperMethods
  include OsLib_OutdoorAirAndInfiltration
  include OsLib_Schedules

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ZEDG K12 Envelope Infiltration"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make an argument for material and installation cost
    costTotalEnvelopeInfiltration = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("costTotalEnvelopeInfiltration",true)
    costTotalEnvelopeInfiltration.setDisplayName("Total cost for all Envelope Improvements ($).")
    costTotalEnvelopeInfiltration.setDefaultValue(0.0)
    args << costTotalEnvelopeInfiltration

    return args
  end

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    costTotalEnvelopeInfiltration = runner.getDoubleArgumentValue("costTotalEnvelopeInfiltration",user_arguments)

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0

    #reporting initial condition of model
    space_infiltration_objects = model.getSpaceInfiltrationDesignFlowRates
    if space_infiltration_objects.size > 0
      runner.registerInitialCondition("The initial model contained #{space_infiltration_objects.size} space infiltration objects.")
    else
      runner.registerInitialCondition("The initial model did not contain any space infiltration objects.")
    end

    # erase existing infiltration objects used in the model, but save most commonly used schedule
    # todo - would be nice to preserve attic space infiltration. There are a number of possible solutions for this
    removedInfiltration = OsLib_OutdoorAirAndInfiltration.eraseInfiltrationUsedInModel(model,runner)

    # find most common hard assigned from removed infiltration objects
    if removedInfiltration.size > 0
      defaultSchedule = removedInfiltration[0][0]  # not sure why this is array vs. hash. I wanted to use removedInfiltration.keys[0]
    else
      defaultSchedule = nil
    end

    # get desired envelope infiltration area
    targetFlowPerExteriorArea = 0.0001905  #0.0375 cfm/ft^2

    # hash to pass into infiltration method
    options_OsLib_OutdoorAirAndInfiltration_envelope = {
        "nameSuffix" => " - envelope infiltration", # add this to object name for infiltration
        "defaultBuildingSchedule" => defaultSchedule, # this will set schedule set for selected object
        "setCalculationMethod" => "setFlowperExteriorWallArea",  # for net zero changing to setFlowperExteriorWallArea instead of setFlowperExteriorSurfaceArea
        "valueForSelectedCalcMethod" => targetFlowPerExteriorArea,
    }
    # add in new envelope infiltration to all spaces in the model
    newInfiltrationPerExteriorSurfaceArea = OsLib_OutdoorAirAndInfiltration.addSpaceInfiltrationDesignFlowRate(model,runner,model.getBuilding, options_OsLib_OutdoorAirAndInfiltration_envelope)
    targetFlowPerExteriorArea_ip =  OpenStudio::convert(targetFlowPerExteriorArea,"m/s","ft/min").get
    runner.registerInfo("Adding infiltration object to all spaces in model with value of #{OpenStudio::toNeatString(targetFlowPerExteriorArea_ip,4,true)} (cfm/ft^2) of exterior surface area.")

    # create lifecycle costs for floors
    envelopeImprovementTotalCost = 0
    totalArea = model.building.get.exteriorSurfaceArea
    newInfiltrationPerExteriorSurfaceArea.each do |infiltrationObject|
      spaceType = infiltrationObject.spaceType.get
      areaForEnvelopeInfiltration_si = OsLib_HelperMethods.getAreaOfSpacesInArray(model,spaceType.spaces,"exteriorArea")["totalArea"]
      fractionOfTotal = areaForEnvelopeInfiltration_si/totalArea
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("#{spaceType.name} - Entry Infiltration Cost", model.getBuilding, fractionOfTotal*costTotalEnvelopeInfiltration, "CostPerEach", "Construction", expected_life, years_until_costs_start)
      envelopeImprovementTotalCost += lcc_mat.get.totalCost
    end

    #reporting final condition of model
    space_infiltration_objects = model.getSpaceInfiltrationDesignFlowRates
    if space_infiltration_objects.size > 0
      runner.registerFinalCondition("The final model contains #{space_infiltration_objects.size} space infiltration objects. Cost was increased by $#{OpenStudio::toNeatString(envelopeImprovementTotalCost,2,true)} for envelope infiltration.")
    else
      runner.registerFinalCondition("The final model does not contain any space infiltration objects. Cost was increased by $#{OpenStudio::toNeatString(envelopeImprovementTotalCost,2,true)} for envelope infiltration.")
    end

    return true
 
  end

end

#this allows the measure to be use by the application
ZEDGK12EnvelopeInfiltration.new.registerWithApplication