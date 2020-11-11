# frozen_string_literal: true

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
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# load OpenStudio measure libraries from openstudio-extension gem
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'
require 'openstudio/extension/core/os_lib_constructions'

# load OpenStudio measure libraries
require "#{File.dirname(__FILE__)}/resources/OsLib_AedgMeasures"

# start the measure
class AedgK12InteriorFinishes < OpenStudio::Measure::ModelMeasure
  # include OpenStudio measure libraries
  include OsLib_AedgMeasures
  include OsLib_Constructions
  include OsLib_HelperMethods

  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'AedgK12InteriorFinishes'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # filter constructions before populating choice argument
    construction_args_hash = {}
    interiorPartitionSurfaces = model.getInteriorPartitionSurfaces
    interiorPartitionSurfaces.each do |surface|
      if !surface.construction.empty?
        construction_arg = surface.construction.get
        construction_args_hash[construction_arg.name.to_s] = construction_arg
      end
    end

    # call method to make argument handles and display names from hash of model objects
    constructionChoiceArgument = OsLib_HelperMethods.populateChoiceArgFromModelObjects(model, construction_args_hash, includeBuilding = '*All Interior Partition Surfaces*')

    # make an argument for construction
    object = OpenStudio::Measure::OSArgument.makeChoiceArgument('object', constructionChoiceArgument['modelObject_handles'], constructionChoiceArgument['modelObject_display_names'], true)
    object.setDisplayName('Only Check/Alter Interior Partition Surfaces To Meet Furniture Target When They Use This Construction.')
    object.setDefaultValue('*All Interior Partition Surfaces*')
    args << object

    # TODO: - add bools for each surface type

    # TODO: - add logic to include adiabatic surfaces as well

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
    object = runner.getOptionalWorkspaceObjectChoiceValue('object', user_arguments, model) # model is passed in because of argument type

    # check that construction exists in model
    modelObjectCheck = OsLib_HelperMethods.checkChoiceArgFromModelObjects(object, 'object', 'to_Construction', runner, user_arguments)

    if modelObjectCheck == false
      return false
    else
      modelObject = modelObjectCheck['modelObject']
      apply_to_building = modelObjectCheck['apply_to_building']
    end

    # create an hash of hashes for surfaces
    surfacesHashCeilings = {}
    surfacesHashWalls = {}
    surfacesHashFurniture = {}
    surfacesHashFloors = {}

    # arrays for initial condition by surface type
    surfacesCeilings = []
    surfacesWalls = []
    surfacesFurniture = []
    surfacesFloors = []

    # TODO: - allow user to pick spaces or space types or look for daylighting controls, but that creates some issues in run order
    # todo - if this will be applied selectively then will want to clone material and constructions vs. editing in place.

    # loop through surfaces to populate hash
    surfaces = model.getSurfaces
    surfaces.each do |surface|
      surfaceType = surface.surfaceType
      if !surface.construction.empty?
        construction = surface.construction.get
        numLayers = construction.to_LayeredConstruction.get.layers
        insideMaterial = construction.to_LayeredConstruction.get.getLayer(numLayers.size - 1)
        visibleAbsorptance = insideMaterial.to_OpaqueMaterial.get.visibleAbsorptance
        if surfaceType == 'RoofCeiling'
          surfacesCeilings << visibleAbsorptance
          surfacesHashCeilings["#{surface.name} - inside"] = { 'surfaceType' => surfaceType, 'construction' => construction, 'material' => insideMaterial, 'visibleAbsorptance' => visibleAbsorptance }
        elsif surfaceType == 'Wall'
          surfacesWalls << visibleAbsorptance
          surfacesHashWalls["#{surface.name} - inside"] = { 'surfaceType' => surfaceType, 'construction' => construction, 'material' => insideMaterial, 'visibleAbsorptance' => visibleAbsorptance }
        elsif surfaceType == 'Floor'
          surfacesFloors << visibleAbsorptance
          surfacesHashFloors["#{surface.name} - inside"] = { 'surfaceType' => surfaceType, 'construction' => construction, 'material' => insideMaterial, 'visibleAbsorptance' => visibleAbsorptance }
        else
          runner.registerWarning("Can't evaluate #{surface.name}, it has an unexpected surface type.")
        end
      else
        # warning
        runner.registerWarning("Can't evaluate #{surface.name}, it doesn't have a construction.")
      end
    end

    # loop through interior partition surfaces to populate hash
    partitionSurfaces = model.getInteriorPartitionSurfaces
    partitionSurfaces.each do |surface|
      surfaceType = 'Partition'
      if !surface.construction.empty?
        if !apply_to_building
          if surface.construction.get != modelObject
            next
          end
        end
        construction = surface.construction.get
        numLayers = construction.to_LayeredConstruction.get.layers
        insideMaterial = construction.to_LayeredConstruction.get.getLayer(numLayers.size - 1)
        exposedMaterial = construction.to_LayeredConstruction.get.getLayer(0)
        visibleAbsorptanceInside = insideMaterial.to_OpaqueMaterial.get.visibleAbsorptance
        visibleAbsorptance = exposedMaterial.to_OpaqueMaterial.get.visibleAbsorptance
        surfacesFurniture << visibleAbsorptanceInside
        surfacesFurniture << visibleAbsorptance
        surfacesHashFurniture["#{surface.name} - inside"] = { 'surfaceType' => surfaceType, 'construction' => construction, 'material' => insideMaterial, 'visibleAbsorptance' => visibleAbsorptanceInside }
        surfacesHashFurniture["#{surface.name} - outside"] = { 'surfaceType' => surfaceType, 'construction' => construction, 'material' => exposedMaterial, 'visibleAbsorptance' => visibleAbsorptance }
      else
        # warning
        runner.registerWarning("Can't evaluate #{surface.name}, it doesn't have a construction.")
      end
    end

    editMaterialsCeilings = []
    editMaterialsWalls = []
    editMaterialsFurniture = []
    editMaterialsFloors = []

    # loop through Ceilings first (most reflective at min 80%)
    minValue = 0.2
    surfacesHashCeilings.each do |k, hash|
      if (hash['visibleAbsorptance'] > minValue) && (!editMaterialsCeilings.include? hash['material'])
        editMaterialsCeilings << hash['material']
        editedMaterial = OsLib_Constructions.setMaterialSurfaceProperties(hash['material'], 'cloneMaterial' => false, 'visibleAbsorptance' => minValue)
        runner.registerInfo("Increasing reflectance of #{hash['material'].name} to AEDG ceiling target reflectance of 80%.")
      end
    end

    # loop through interior walls (min 70% reflective)
    minValue = 0.3
    surfacesHashWalls.each do |k, hash|
      if (hash['visibleAbsorptance'] > minValue) && (!editMaterialsWalls.include? hash['material'])
        editMaterialsWalls << hash['material']
        if editMaterialsCeilings.include? hash['material']
          runner.registerWarning("#{hash['material'].name} is used on one or more interior wall surfaces. It is using a higher reflectance target from another surface type.")
          next
        end
        editedMaterial = OsLib_Constructions.setMaterialSurfaceProperties(hash['material'], 'cloneMaterial' => false, 'visibleAbsorptance' => minValue)
        runner.registerInfo("Increasing reflectance of #{hash['material'].name} to AEDG wall target reflectance of 70%.")
      end
    end

    # loop through interior partition surfaces (min 50% reflective)
    minValue = 0.5
    surfacesHashFurniture.each do |k, hash|
      if (hash['visibleAbsorptance'] > minValue) && (!editMaterialsFurniture.include? hash['material'])
        editMaterialsFurniture << hash['material']
        if editMaterialsCeilings.include?(hash['material']) || editMaterialsWalls.include?(hash['material'])
          runner.registerWarning("#{hash['material'].name} is used on one or more interior partition surfaces. It is using a higher reflectance target from another surface type.")
          next
        end
        editedMaterial = OsLib_Constructions.setMaterialSurfaceProperties(hash['material'], 'cloneMaterial' => false, 'visibleAbsorptance' => minValue)
        runner.registerInfo("Increasing reflectance of #{hash['material'].name} to AEDG furniture target reflectance of 50%.")
      end
    end

    # loop through floors (min 20% reflective)
    minValue = 0.8
    surfacesHashFloors.each do |k, hash|
      if (hash['visibleAbsorptance'] > minValue) && (!editMaterialsFloors.include? hash['material'])
        editMaterialsFloors << hash['material']
        if editMaterialsCeilings.include?(hash['material']) || editMaterialsWalls.include?(hash['material']) || editMaterialsFurniture.include?(hash['material'])
          runner.registerWarning("#{hash['material'].name} is used on one or more interior floor surfaces. It is using a higher reflectance target from another surface type.")
          next
        end
        editedMaterial = OsLib_Constructions.setMaterialSurfaceProperties(hash['material'], 'cloneMaterial' => false, 'visibleAbsorptance' => minValue)
        runner.registerInfo("Increasing reflectance of #{hash['material'].name} to AEDG floor target reflectance of 20%.")
      end
    end

    # add AEDG tips
    if surfaces.size + partitionSurfaces.size > 0
      aedgTips = ['DL14']
    else
      runner.registerAsNotApplicable("This model doesn't appear to have any surfaces to change.")
      return true
    end

    # populate how to tip messages
    aedgTipsLong = OsLib_AedgMeasures.getLongHowToTips('K12', aedgTips.uniq.sort, runner)
    if !aedgTipsLong
      return false # this should only happen if measure writer passes bad values to getLongHowToTips
    end

    # string for final condition.
    string = []
    if !surfacesCeilings.empty?
      string << "Initial ceiling reflectance values ranged from #{100 * (1.0 - surfacesCeilings.max)} to #{100 * (1.0 - surfacesCeilings.min)} percent. "
    end
    if !surfacesWalls.empty?
      string << "Initial wall reflectance values ranged from #{100 * (1.0 - surfacesWalls.max)} to #{100 * (1.0 - surfacesWalls.min)} percent. "
    end
    if !surfacesFurniture.empty?
      string << "Initial furniture reflectance values ranged from #{100 * (1.0 - surfacesFurniture.max)} to #{100 * (1.0 - surfacesFurniture.min)} percent. "
    end
    if !surfacesFloors.empty?
      string << "Initial floor reflectance values ranged from #{100 * (1.0 - surfacesFloors.max)} to #{100 * (1.0 - surfacesFloors.min)} percent. "
    end

    # reporting initial condition of model
    runner.registerInitialCondition(string.to_s)

    # string for final condition.
    string = []
    if !editMaterialsCeilings.empty?
      string << "Increased reflectance to #{editMaterialsCeilings.size} ceiling materials. "
    end
    if !editMaterialsWalls.empty?
      string << "Increased reflectance to #{editMaterialsWalls.size} wall materials. "
    end
    if !editMaterialsFurniture.empty?
      string << "Increased reflectance to #{editMaterialsFurniture.size} furniture materials. "
    end
    if !editMaterialsFloors.empty?
      string << "Increased reflectance to #{editMaterialsFloors.size} floors materials. "
    end

    # reporting final condition of model
    runner.registerFinalCondition("#{string} #{aedgTipsLong}")

    return true
  end
end

# this allows the measure to be use by the application
AedgK12InteriorFinishes.new.registerWithApplication
