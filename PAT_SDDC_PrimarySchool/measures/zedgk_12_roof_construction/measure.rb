# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_hash/cpp_documentation_it/model/html/namespaces.html

# load OpenStudio measure libraries from openstudio-extension gem
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_constructions'

# load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"

# start the measure
class ZEDGK12RoofConstruction < OpenStudio::Measure::ModelMeasure
  include OsLib_AedgMeasures
  include OsLib_Constructions

  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'ZEDG K12 RoofConstruction'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for material and installation cost
    material_cost_insulation_increase_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost_insulation_increase_ip', true)
    material_cost_insulation_increase_ip.setDisplayName('Increase Cost per Area of Construction Where Insulation was Improved ($/ft^2).')
    material_cost_insulation_increase_ip.setDefaultValue(0.0)
    args << material_cost_insulation_increase_ip

    # make an argument for material and installation cost
    material_cost_sri_increase_ip = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost_sri_increase_ip', true)
    material_cost_sri_increase_ip.setDisplayName('Increase Cost per Area of Construction Where Solar Reflectance Index (SRI) was Improved. ($/ft^2).')
    material_cost_sri_increase_ip.setDefaultValue(0.0)
    args << material_cost_sri_increase_ip

    # make an argument to alter_sri
    alter_sri = OpenStudio::Measure::OSArgument.makeBoolArgument('alter_sri', true)
    alter_sri.setDisplayName('Alter SRI?')
    alter_sri.setDefaultValue(true)
    args << alter_sri

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    material_cost_insulation_increase_ip = runner.getDoubleArgumentValue('material_cost_insulation_increase_ip', user_arguments)
    material_cost_sri_increase_ip = runner.getDoubleArgumentValue('material_cost_sri_increase_ip', user_arguments)
    alter_sri = runner.getBoolArgumentValue('alter_sri', user_arguments)

    # no validation needed for cost inputs, negative values are fine, however negative would be odd choice since this measure only improves vs. decreases insulation and SRI performance

    # global variables for costs
    expected_life = 25
    years_until_costs_start = 0
    material_cost_insulation_increase_si = OpenStudio.convert(material_cost_insulation_increase_ip, '1/ft^2', '1/m^2').get
    material_cost_sri_increase_si = OpenStudio.convert(material_cost_sri_increase_ip, '1/ft^2', '1/m^2').get
    running_cost_insulation = 0
    running_cost_sri = 0

    # prepare rule hash
    rules = [] # climate zone, roof type, thermal transmittance (Btu/h·ft2·°F), SRI

    # zedg doesn't have wall type lookup like aedg, altert user of this
    runner.registerInfo('Roof insulation values based on IEAD roof.')

    rules << ['0', 'IEAD', 0.039, 78.0] # measure setup to use only for this target and roof type
    rules << ['1', 'IEAD', 0.048, 78.0]
    rules << ['2', 'IEAD', 0.039, 78.0]
    rules << ['3', 'IEAD', 0.039, 78.0]
    rules << ['4', 'IEAD', 0.030, 0]
    rules << ['5', 'IEAD', 0.030, 0]
    rules << ['6', 'IEAD', 0.030, 0]
    rules << ['7', 'IEAD', 0.027, 0]
    rules << ['8', 'IEAD', 0.027, 0]

    # make rule hash for cleaner code
    rulesHash = {}
    rules.each do |rule|
      rulesHash["#{rule[0]} #{rule[1]}"] = { 'conductivity_ip' => rule[2], 'sri' => rule[3] }
    end

    # get climate zone
    climateZoneNumber = OsLib_AedgMeasures.getClimateZoneNumber(model, runner)
    # climateZoneNumber = "4" # this is just in for quick testing of different climate zones

    # add message for climate zones 4-8 about SRI
    if climateZoneNumber == false
      return false
    elsif climateZoneNumber.to_f > 3
      runner.registerInfo("For Climate Zone #{climateZoneNumber} Solar Reflectance Index (SRI) should comply with Standard 90.1.")
    end

    # get starting r-value and SRI ranges
    startingRvaluesExtRoof = []
    startingRvaluesAtticInterior = []
    startingSriExtRoof = []

    # flag for roof surface type for tips
    ieadFlag = false
    metalFlag = false
    atticFlag = false

    # affected area counter
    insulation_affected_area = 0
    sri_affected_area = 0

    # construction hashes  (construction is key, value is array [thermal transmittance (Btu/h·ft2·°F), SRI,rule thermal transmittance (Btu/h·ft2·°F), rule SRI,classification string)
    ieadConstructions = {}
    metalConstructions = {}
    atticConstructions = {} # will initially load all constructions used in model, and will delete later if passes test

    # this contains constructions that should not have exterior roofs assigned
    otherConstructions = []

    # make array for spaces that have a surface with at least one exterior attic surface
    atticSpaces = []

    # loop through constructions
    constructions = model.getConstructions
    constructions.each do |construction|
      # skip if not used
      next if construction.getNetArea <= 0

      # skip if not opaque
      next if !construction.isOpaque

      # get construction and standard
      constructionStandard = construction.standardsInformation

      # get roof type
      intendedSurfaceType = constructionStandard.intendedSurfaceType

      # because it is assumed to be IEAD, hard code vs. inspecting construction
      # constructionType = constructionStandard.standardsConstructionType
      constructionType = 'IEAD'

      # get conductivity
      conductivity_si = construction.thermalConductance.get
      r_value_ip = OpenStudio.convert(1 / conductivity_si, 'm^2*K/W', 'ft^2*h*R/Btu').get

      # get SRI (only need of climate zones 1-3)
      sri = OsLib_Constructions.getConstructionSRI(construction)

      # flags for construction loop
      ruleRvalueFlag = true
      ruleSriFlag = true

      # IEAD and Metal roofs should have intendedSurfaceType of ExteriorRoof
      if intendedSurfaceType.to_s == 'ExteriorRoof'

        if constructionType.to_s == 'IEAD'

          # store starting values
          startingRvaluesExtRoof << r_value_ip
          startingSriExtRoof << sri
          ieadFlag = true

          # test construction against rules
          ruleSet = rulesHash["#{climateZoneNumber} IEAD"]
          if 1 / r_value_ip > ruleSet['conductivity_ip']
            ruleRvalueFlag = false
          end
          if sri < ruleSet['sri']
            ruleSriFlag = false
          end
          if !ruleRvalueFlag || !ruleSriFlag
            ieadConstructions[construction] = { 'conductivity_ip' => 1 / r_value_ip, 'sri' => sri, 'transmittance_ip_rule' => ruleSet['conductivity_ip'], 'sri_rule' => ruleSet['sri'], 'classification' => 'ieadConstructions' }
          end

        elsif constructionType.to_s == 'Metal'

          # store starting values
          startingRvaluesExtRoof << r_value_ip
          startingSriExtRoof << sri
          metalFlag = true

          # test construction against rules
          ruleSet = rulesHash["#{climateZoneNumber} Metal"]
          if 1 / r_value_ip > ruleSet['conductivity_ip']
            ruleRvalueFlag = false
          end
          if sri < ruleSet['sri']
            ruleSriFlag = false
          end
          if !ruleRvalueFlag || !ruleSriFlag
            metalConstructions[construction] = { 'conductivity_ip' => 1 / r_value_ip, 'sri' => sri, 'transmittance_ip_rule' => ruleSet['conductivity_ip'], 'sri_rule' => ruleSet['sri'], 'classification' => 'metalConstructions' }
          end

        else
          # create warning if a construction passing through here is used on a roofCeiling surface with a boundary condition of "Outdoors"
          otherConstructions << construction
        end

      elsif (intendedSurfaceType.to_s == 'AtticRoof') || (intendedSurfaceType.to_s == 'AtticWall') || (intendedSurfaceType.to_s == 'AtticFloor')

        # store starting values
        atticFlag = true

        atticConstructions[construction] = { 'conductivity_ip' => 1 / r_value_ip, 'sri' => sri } # will extend this hash later

      else
        # create warning if a construction passing through here is used on a roofCeiling surface with a boundary condition of "Outdoors"
        otherConstructions << construction

      end
    end

    # create warning if construction used on exterior roof doesn't have a surface type of "ExteriorRoof", or if constructions tagged to be used as roof, are used on other surface types
    otherConstructionsWarned = []
    atticSurfaces = [] # to test against attic spaces later on
    surfaces = model.getSurfaces
    surfaces.each do |surface|
      if !surface.construction.empty?
        construction = surface.construction.get

        # populate attic spaces
        if (surface.outsideBoundaryCondition == 'Outdoors') && atticConstructions.include?(construction)
          if !surface.space.empty?
            if !atticSpaces.include? surface.space.get
              atticSpaces << surface.space.get
            end
          end
        elsif atticConstructions.include? construction
          atticSurfaces << surface
        end

        if (surface.outsideBoundaryCondition == 'Outdoors') && (surface.surfaceType == 'RoofCeiling')

          if otherConstructions.include?(construction) && (!otherConstructionsWarned.include? construction)
            runner.registerWarning("#{construction.name} is used on one or more exterior roof surfaces but has an intended surface type or construction type not recognized by this measure. As we can not infer the proper performance target, this construction will not be altered.")
            otherConstructionsWarned << construction
          end

        else

          if ieadConstructions.include?(construction) || metalConstructions.include?(construction)
            runner.registerWarning("#{surface.name} uses #{construction.name} as a construction that this measure expects to be used for exterior roofs. This surface has a type of #{surface.surfaceType} and a a boundary condition of #{surface.outsideBoundaryCondition}. This may result in unexpected changes to your model.")
          end

        end

      end
    end

    # hashes to hold classification of attic surfaces
    atticSurfacesInterior = {} # this will include paris of matched surfaces
    atticSurfacesExteriorExposed = {}
    atticSurfacesExteriorExposedNonRoof = {}
    atticSurfacesOtherAtticDemising = {}

    # look for attic surfaces that are not in attic space or matched to them.
    atticSpaceWarning = false
    atticSurfaces.each do |surface|
      if !surface.space.empty?
        space = surface.space.get
        if !atticSpaces.include? space
          if surface.outsideBoundaryCondition == 'Surface'
            # get space of matched surface and see if it is also an attic
            next if surface.adjacentSurface.empty?
            adjacentSurface = surface.adjacentSurface.get
            next if adjacentSurface.space.empty?
            adjacentSurfaceSpace = adjacentSurface.space.get
            if !atticSpaces.include? adjacentSurfaceSpace
              atticSpaceWarning = true
            end
          else
            atticSpaceWarning = true
          end
        end
      end
    end
    if atticSpaceWarning
      runner.registerWarning("#{surface.name} uses #{construction.name} as a construction that this measure expects to be used for attics. This surface has a type of #{surface.surfaceType} and a a boundary condition of #{surface.outsideBoundaryCondition}. This may result in unexpected changes to your model.")
    end

    # flag for testing
    interiorAtticSurfaceInSpace = false

    # loop through attic spaces to classify surfaces with attic intended surface type
    atticSpaces.each do |atticSpace|
      atticSurfaces = atticSpace.surfaces

      # array for surfaces that don't use an attic construction
      surfacesWithNonAtticConstructions = []

      # loop through attic surfaces
      atticSurfaces.each do |atticSurface|
        next if atticSurface.construction.empty?
        construction = atticSurface.construction.get
        if atticConstructions.include? construction
          conductivity_ip = atticConstructions[construction]['conductivity_ip']
          r_value_ip = 1 / conductivity_ip
          sri = atticConstructions[construction]['sri']
        else
          surfacesWithNonAtticConstructions << atticSurface.name
          next
        end

        # warn if any exterior exposed roof surfaces are not attic.
        if atticSurface.outsideBoundaryCondition == 'Outdoors'

          # only want to change SRI if it is a roof
          if atticSurface.surfaceType == 'RoofCeiling'

            # store starting value for SRI
            startingSriExtRoof << sri
            atticSurfacesExteriorExposed[atticSurface] = construction
          else
            atticSurfacesExteriorExposedNonRoof[atticSurface] = construction
          end

        elsif atticSurface.outsideBoundaryCondition == 'Surface'

          # get space of matched surface and see if it is also an attic
          next if atticSurface.adjacentSurface.empty?
          adjacentSurface = atticSurface.adjacentSurface.get
          next if adjacentSurface.space.empty?
          adjacentSurfaceSpace =  adjacentSurface.space.get

          if atticSpaces.include?(adjacentSurfaceSpace) && atticSpaces.include?(atticSpace)
            atticSurfacesOtherAtticDemising[atticSurface] = construction
          else
            # store starting values
            startingRvaluesAtticInterior << r_value_ip
            atticSurfacesInterior[atticSurface] = construction
            interiorAtticSurfaceInSpace = true # this is to confirm that space has at least one interior surface flagged as an attic
          end

        else
          runner.registerWarning("Can't infer use case for attic surface with an outside boundary condition of #{atticSurface.outsideBoundaryCondition}.")
        end
      end

      # warning message for each space that has mix of attic and non attic constructions
      runner.registerWarning("#{atticSpace.name} has surfaces with a mix of attic and non attic constructions which may produce unexpected results. The following surfaces use constructions not tagged as attic and will not be altered: #{surfacesWithNonAtticConstructions.sort.join(',')}.")

      # confirm that all spaces have at least one or more surface of both exterior attic and interior attic
      if !interiorAtticSurfaceInSpace
        runner.registerWarning("#{atticSpace.name} has at least one exterior attic surface but does not have an interior attic surface. Please confirm that this space is intended to be an attic and update the constructions used.")
      end

      # see if attic is part of floor area and/or if it has people in it
      if atticSpace.partofTotalFloorArea
        runner.registerWarning("#{atticSpace.name} is part of the floor area. That is not typical for an attic.")
      end
      if !atticSpace.people.empty?
        runner.registerWarning("#{atticSpace.name} has people. That is not typical for an attic.")
      end
    end

    # removed aedg code that looks for classification conflicts in attic constructions

    # alter constructions and add lcc
    constructionsToChange = ieadConstructions.sort + metalConstructions.sort + atticConstructions.sort
    constructionsToChange.each do |construction, hash|
      # gather insulation inputs
      if hash['transmittance_ip_rule'] != 'NA'

        # gather target decrease in conductivity
        conductivity_ip_starting = hash['conductivity_ip']
        conductivity_si_starting = OpenStudio.convert(conductivity_ip_starting, 'Btu/ft^2*h*R', 'W/m^2*K').get
        r_value_ip_starting = 1 / conductivity_ip_starting # ft^2*h*R/Btu
        r_value_si_starting = 1 / conductivity_si_starting # m^2*K/W
        conductivity_ip_target = hash['transmittance_ip_rule'].to_f
        conductivity_si_target = OpenStudio.convert(conductivity_ip_target, 'Btu/ft^2*h*R', 'W/m^2*K').get
        r_value_ip_target = 1 / conductivity_ip_target # ft^2*h*R/Btu
        r_value_si_target = 1 / conductivity_si_target # m^2*K/W

        # infer insulation material to get input for target thickness
        minThermalResistance = OpenStudio.convert(1, 'ft^2*h*R/Btu', 'm^2*K/W').get
        inferredInsulationLayer = OsLib_Constructions.inferInsulationLayer(construction, minThermalResistance)
        rvalue_si_deficiency = r_value_si_target - r_value_si_starting

        # add lcc for insulation
        lcc_mat_insulation = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat_Insulation - #{construction.name}", construction, material_cost_insulation_increase_si, 'CostPerArea', 'Construction', expected_life, years_until_costs_start)
        lcc_mat_insulation_value = lcc_mat_insulation.get.totalCost
        running_cost_insulation += lcc_mat_insulation_value

        # adjust existing material or add new one
        if inferredInsulationLayer['insulationFound'] # if insulation layer was found

          # gather inputs for method
          target_material_rvalue_si = inferredInsulationLayer['construction_thermal_resistance'] + rvalue_si_deficiency

          # run method to change insulation layer thickness in cloned material (material,starting_r_value_si,target_r_value_si, model)
          new_material = OsLib_Constructions.setMaterialThermalResistance(inferredInsulationLayer['construction_layer'], target_material_rvalue_si)

          # connect new material to original construction
          construction.eraseLayer(inferredInsulationLayer['layer_index'])
          construction.insertLayer(inferredInsulationLayer['layer_index'], new_material)

          # get conductivity
          final_conductivity_si = construction.thermalConductance.get
          final_r_value_ip = OpenStudio.convert(1 / final_conductivity_si, 'm^2*K/W', 'ft^2*h*R/Btu').get

          # report on edited material
          runner.registerInfo("The R-value of #{construction.name} has been increased from #{OpenStudio.toNeatString(r_value_ip_starting, 2, true)} to #{OpenStudio.toNeatString(final_r_value_ip, 2, true)}(ft^2*h*R/Btu) at a cost of $#{OpenStudio.toNeatString(lcc_mat_insulation_value, 2, true)}. Increased performance was accomplished by adjusting thermal resistance of #{new_material.name}.")

        else

          # inputs to pass to method
          conductivity = 0.045 # W/m*K
          thickness = rvalue_si_deficiency * conductivity # meters

          addNewLayerToConstruction_Inputs = {
            'roughness' => 'MediumRough',
            'thickness' => thickness, # meters,
            'conductivity' => conductivity, # W/m*K
            'density' => 265.0,
            'specificHeat' => 836.8,
            'thermalAbsorptance' => 0.9,
            'solarAbsorptance' => 0.7,
            'visibleAbsorptance' => 0.7
          }

          # create new material if can't infer insulation material (construction,thickness, conductivity, density, specificHeat, roughness,thermalAbsorptance, solarAbsorptance,visibleAbsorptance,model)
          newMaterialLayer = OsLib_Constructions.addNewLayerToConstruction(construction, addNewLayerToConstruction_Inputs)

          # get conductivity
          final_conductivity_si = construction.thermalConductance.get
          final_r_value_ip = OpenStudio.convert(1 / final_conductivity_si, 'm^2*K/W', 'ft^2*h*R/Btu').get

          # report on edited material
          runner.registerInfo("The R-value of #{construction.name} has been increased from #{OpenStudio.toNeatString(r_value_ip_starting, 2, true)} to #{OpenStudio.toNeatString(final_r_value_ip, 2, true)}(ft^2*h*R/Btu) at a cost of $#{OpenStudio.toNeatString(lcc_mat_insulation_value, 2, true)}. Increased performance was accomplished by adding a new material layer to the outside of #{construction.name}.")

        end

        # add to area counter
        insulation_affected_area += construction.getNetArea # OpenStudio handles matched surfaces so they are not counted twice.

      end

      # gather sri inputs
      if (hash['sri_rule'] == 78.0) && (hash['sri_rule'] > hash['sri']) && alter_sri

        # hard assign material properies that will result in an SRI of 78
        setConstructionSurfaceProperties_Inputs = {
          'thermalAbsorptance' => 0.86,
          'solarAbsorptance' => 1 - 0.65
        }

        # alter surface properties (construction,roughness,thermalAbsorptance, solarAbsorptance,visibleAbsorptance)
        surfaceProperties = OsLib_Constructions.setConstructionSurfaceProperties(construction, setConstructionSurfaceProperties_Inputs)
        sri = OsLib_Constructions.getConstructionSRI(construction)

        # add lcc for SRI
        lcc_mat_sri = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat_SRI - #{construction.name}", construction, material_cost_sri_increase_si, 'CostPerArea', 'Construction', expected_life, years_until_costs_start)
        lcc_mat_sri_value = lcc_mat_sri.get.totalCost
        running_cost_sri += lcc_mat_sri_value

        # add to area counter
        sri_affected_area += construction.getNetArea

        # report performance and cost change for material, or area
        runner.registerInfo("The Solar Reflectance Index (SRI) of #{construction.name} has been increased from #{OpenStudio.toNeatString(hash['sri'], 0, true)} to #{OpenStudio.toNeatString(sri, 0, true)} for a cost of $#{OpenStudio.toNeatString(lcc_mat_sri_value, 0, true)}. Affected area is #{OpenStudio.toNeatString(OpenStudio.convert(construction.getNetArea, 'm^2', 'ft^2').get, 0, true)} (ft^2)")

      end
    end

    # reporting initial condition of model
    startingRvalue = startingRvaluesExtRoof + startingRvaluesAtticInterior # adding non attic and attic values together

    runner.registerInitialCondition("Starting R-values for constructions intended for insulated roof surfaces range from #{OpenStudio.toNeatString(startingRvalue.min, 2, true)} to #{OpenStudio.toNeatString(startingRvalue.max, 2, true)}(ft^2*h*R/Btu). Starting Solar Reflectance Index (SRI) for constructions intended for exterior roof surfaces range from #{OpenStudio.toNeatString(startingSriExtRoof.min, 0, true)} to #{OpenStudio.toNeatString(startingSriExtRoof.max, 0, true)}.")

    # reporting final condition of model
    insulation_affected_area_ip = OpenStudio.convert(insulation_affected_area, 'm^2', 'ft^2').get
    sri_affected_area_ip = OpenStudio.convert(sri_affected_area, 'm^2', 'ft^2').get
    runner.registerFinalCondition("#{OpenStudio.toNeatString(insulation_affected_area_ip, 0, true)}(ft^2) of constructions intended for roof surfaces had insulation enhanced at a cost of $#{OpenStudio.toNeatString(running_cost_insulation, 0, true)}. #{OpenStudio.toNeatString(sri_affected_area_ip, 0, true)}(ft^2) of constructions intended for roof surfaces had the Solar Reflectance Index (SRI) enhanced at a cost of $#{OpenStudio.toNeatString(running_cost_sri, 0, true)}.")

    return true
  end
end

# this allows the measure to be use by the application
ZEDGK12RoofConstruction.new.registerWithApplication
