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
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class ZEDGK12InsertGroundDomainEKusdua < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    return 'ZEDG K12 Insert Ground Domain E+ Kusdua'
  end

  # human readable description
  def description
    return 'Measure to insert the EnergyPlus Site:GroundDomain:Slab object into the model and, when recommended, horizontal and vertical insulation.'
  end

  # human readable description of modeling approach
  # In EnergyPlus 8.3 hitting issues with time series data when using finite difference
  def modeler_description
    return 'This will add code to lookup pre-calculated inputs for specific cities'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make argument for multiplier
    min_warmup_days = OpenStudio::Measure::OSArgument.makeDoubleArgument('min_warmup_days', true)
    min_warmup_days.setDisplayName('Set Minimum Number of Warmup Days')
    min_warmup_days.setDescription('Longer warmup period with this measure will provide more consistent ground modeling.')
    min_warmup_days.setDefaultValue(120)
    args << min_warmup_days

    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # get arguments
    insul_target = 'ClimateZone Specific'
    min_warmup_days = runner.getDoubleArgumentValue('min_warmup_days', user_arguments)

    # set minimum warmup period, and extend maximum warmup if neeed so it doesn't conflict with minimum.
    building = workspace.getObjectsByType('Building'.to_IddObjectType).first
    building.setString(6, min_warmup_days.to_i.to_s)
    if building.getString(7).get.to_i < min_warmup_days
      building.setString(7, min_warmup_days.to_i.to_s)
    end

    # hash for inputs for kusuda
    # ran CalcSoilSurfTemp to generate these. Would be nice to do on the fly in measure

    kusuda_input = {} # weather,soil_int, ground_int, ann_avg_soil_surf_temp, amplitude, phase_constant
    kusuda_input['Fairbanks'] = [2, 2, -1.1, 20.5, 20]
    kusuda_input['Phoenix'] = [2, 2, 19.8, 6.0, 356]
    kusuda_input['San Francisco'] = [2, 2, 13.9, 3.2, 29]
    kusuda_input['Denver'] = [2, 2, 9.7, 11.5, 2]
    kusuda_input['Miami'] = [2, 2, 23.5, 4.8, 38]
    kusuda_input['Boise'] = [2, 2, 10.5, 14.2, 28]
    kusuda_input['Chicago'] = [2, 2, 9.6, 18.8, 36]
    kusuda_input['Boston'] = [2, 2, 9.6, 17.1, 30]
    kusuda_input['Baltimore'] = [2, 2, 12.3, 13.6, 358]
    kusuda_input['Duluth'] = [2, 2, 4.3, 20.1, 14]
    kusuda_input['Helena'] = [2, 2, 7.0, 20.3, 67]
    kusuda_input['Albuquerque'] = [2, 2, 12.1, 10.2, 339]
    kusuda_input['Salem'] = [2, 2, 11.7, 10.8, 355]
    kusuda_input['Memphis'] = [2, 2, 16.2, 12.7, 10]
    kusuda_input['El Paso'] = [2, 2, 15.5, 8.2, 354]
    kusuda_input['Houston'] = [2, 2, 19.9, 12.9, 56]
    kusuda_input['Burlington'] = [2, 2, 7.5, 17.9, 33]

    # new epws added in 2017
    kusuda_input['Davis Monthan'] = [2, 2, 17.6, 9.1, 319]
    kusuda_input['Chula Vista'] = [2, 2, 17.5, 5.9, 122]
    kusuda_input['Honolulu'] = [2, 2, 23.4, 1.8, 65]
    kusuda_input['Buffalo'] = [2, 2, 8.6, 17.0, 47]
    kusuda_input['New York'] = [2, 2, 11.6, 14.5, 45]
    kusuda_input['International Falls'] = [2, 2, 3.7, 22.3, 13]
    kusuda_input['Great Falls'] = [2, 2, 6.0, 18.7, 8]
    kusuda_input['Seattle'] = [2, 2, 10.8, 9.3, 71]
    kusuda_input['Atlanta'] = [2, 2, 15.8, 11.1, 46]
    kusuda_input['Macdill'] = [2, 2, 21.9, 9.7, 51]
    kusuda_input['Rochester'] = [2, 2, 6.4, 24.1, 38]
    kusuda_input['Aurora'] = [2, 2, 9.4, 15.6, 364]
    kusuda_input['William R Fairchild'] = [2, 2, 10.2, 7.5, 28]
    kusuda_input['New Delhi'] = [2, 2, 25.0, 4.5, 25]
    kusuda_input['ABU DHABI'] = [2, 2, 25.5, 7.3, 18]
    kusuda_input['HANOI'] = [2, 2, 24.9, 6.9, 60]

    # Get the last openstudio model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Could not load last OpenStudio model, cannot apply measure.')
      return false
    end
    model = model.get

    # register climate zone
    climateZones = model.getClimateZones
    ashraeClimateZone = nil
    climateZones.climateZones.each do |climateZone|
      if climateZone.institution == 'ASHRAE'
        ashraeClimateZone = climateZone.value
        runner.registerValue('ashrae_climate_zone', ashraeClimateZone.to_s)
      end
    end

    # Add Site:GroundTemperature:Undisturbed:FiniteDifference
    # not used until bug in 8.4 is fixed
    string_fd = "
    Site:GroundTemperature:Undisturbed:FiniteDifference,
      FDTemps,     !- Name of object
      1.08,        !- Soil Thermal Conductivity {W/m-K}
      962,         !- Soil Density {kg/m3}
      2576,        !- Soil Specific Heat {J/kg-K}
      30,          !- Soil Moisture Content Volume Fraction {percent}
      50,          !- Soil Moisture Content Volume Fraction at Saturation {percent}
      0.408;       !- Evapotranspiration Ground Cover Parameter
    	"

    city = model.getWeatherFile.city
    runner.registerValue('city', city)

    kusuda_values = nil
    kusuda_input.each do |k, v|
      if city.to_s.include?(k)
        kusuda_values = v
        next
      end
    end

    if kusuda_values.nil?
      runner.registerError("Didn't find match for #{city}")
    end

    sting_kusuda = "
    Site:GroundTemperature:Undisturbed:KusudaAchenbach,
      KATemps,    !- Name of object
      1.08,       !- Soil Thermal Conductivity {W/m-K}
      962,        !- Soil Density {kg/m3}
      2576,       !- Soil Specific Heat {J/kg-K}
      #{kusuda_values[2]},       !- Average Soil Surface Temperature {C}
      #{kusuda_values[3]},       !- Average Amplitude of Surface Temperature {deltaC}
      #{kusuda_values[4]};         !- Phase Shift of Minimum Surface Temperature {days}
      "

    runner.registerInfo('Added Site:GroundTemperature:Undisturbed:KusudaAchenbach')
    idfObject = OpenStudio::IdfObject.load(sting_kusuda)
    object = workspace.addObject(idfObject.get).get

    # Add SurfaceProperty:OtherSideConditionsModel
    string = "
    SurfaceProperty:OtherSideConditionsModel,
      GroundCoupledOSCM,       !- Name
      GroundCoupledSurface;    !- Type of Modeling
      "

    runner.registerInfo('Added SurfaceProperty:OtherSideConditionsModel')
    idfObject = OpenStudio::IdfObject.load(string)
    object = workspace.addObject(idfObject.get).get

    # populate lookup_table for vertical insulation r value and height
    rule_hash = {}
    # no vertical insulation for cz 1-3
    rule_hash['0'] = [nil, nil, false] # R value , height, hor_insul
    rule_hash['1'] = [nil, nil, false] # R value , height, hor_insul
    rule_hash['2'] = [nil, nil, false] # R value , height, hor_insul
    rule_hash['3'] = [nil, nil, false] # R value , height, hor_insul
    rule_hash['4'] = [25.0, 36.0, false] # R value , height, hor_insul
    rule_hash['5'] = [25.0, 36.0, false] # R value , height, hor_insul
    rule_hash['6'] = [20.0, 48.0, true] # R value , height, hor_insul
    rule_hash['7'] = [30.0, 54.0, true] # R value , height, hor_insul
    rule_hash['8'] = [30.0, 54.0, true] # R value , height, hor_insul

    climate_zone_number = ashraeClimateZone[0]
    puts "target values are #{rule_hash[climate_zone_number.to_s]}"

    # use old static values if requested
    if insul_target == 'Static 2016'
      # before lookup table values were
      ins_hgt = 0.61
      insul_conduct = 0.025
      insul_thickness = 0.1
    elsif !rule_hash[climate_zone_number.to_s][0].nil?
      # value for vertical insulation
      target_r_value_ip = rule_hash[climate_zone_number.to_s][0]
      rvins = OpenStudio.convert(target_r_value_ip, 'ft^2*h*R/Btu', 'm^2*K/W').get # R value of vertical insulation
      puts "target resistance is #{rvins}"
      target_height_ip = rule_hash[climate_zone_number.to_s][1] / 12 # in
      ins_hgt = OpenStudio.convert(target_height_ip, 'ft', 'm').get # m
      puts "target height is #{ins_hgt}"
      insul_conduct = 0.025 # W/m-K

      # calculate thickness
      target_conduct = 1 / rvins # W/m^2*k
      puts "target conductivity is #{target_conduct}"
      insul_thickness = insul_conduct / target_conduct
      puts "thickness is #{insul_thickness}"
      puts "test ip R value is   #{OpenStudio.convert(1 / (insul_conduct / insul_thickness), 'm^2*K/W', 'ft^2*h*R/Btu').get}"
    end

    # Adding slab insulation
    vert_insul = 'No'
    if !((insul_target == 'No Vertical Insulation') || rule_hash[climate_zone_number.to_s][0].nil?)
      string = "
    Material,
      VERTICAL SLAB INSULATION,         !- Name
      Smooth,                  !- Roughness
      #{insul_thickness},      !- Thickness {m}
      #{insul_conduct},          !- Conductivity {W/m-K}
      50,                      !- Density {kg/m3}
      1300,                    !- Specific Heat {J/kg-K}
      0.9,                     !- Thermal Absorptance
      0.65,                    !- Solar Absorptance
      0.65;                    !- Visible Absorptance
      "
      runner.registerInfo('Added Slab Insulation material')
      idfObject = OpenStudio::IdfObject.load(string)
      object = workspace.addObject(idfObject.get).get
      vert_insul = 'Yes'
    end

    # Adding slab material in grade
    string = "
    Material,
      SLAB 8 HW CONCRETE,                     !- Name
      Rough,                                  !- Roughness
      0.2032,                                 !- Thickness {m}
      1.311,                                  !- Conductivity {W/m-K}
      2240,                                   !- Density {kg/m3}
      836.8,                                  !- Specific Heat {J/kg-K}
      0.9,                                    !- Thermal Absorptance
      0.7,                                    !- Solar Absorptance
      0.7;                                    !- Visible Absorptance
    "

    runner.registerInfo('Added Slab Material-In-grade material')
    idfObject = OpenStudio::IdfObject.load(string)
    object = workspace.addObject(idfObject.get).get

    # add variable for fields affected by horizontal insulation
    if rule_hash[climate_zone_number.to_s][2]
      runner.registerInfo('Adding full horizontal slab insulation at same R value as vertical slab insulation')
      slab_location = 'InGrade'
      hor_insul = 'Yes'
      full_or_perim = 'Full'
      hor_slab_insul = 'VERTICAL SLAB INSULATION'
    else
      slab_location = 'OnGrade'
      hor_insul = 'No'
      full_or_perim = ''
      hor_slab_insul = ''
    end

    # Add the Site:GroundDomain object to the model
    string = "
    Site:GroundDomain:Slab,
      CoupledSlab,      !- Name
      5,                       !- Ground Domain Depth {m}
      1,                       !- Aspect Ratio
      5,                       !- Domain Perimeter Offset {m}
      1.08,                    !- Soil Thermal Conductivity {W/m-K}
      962,                     !- Soil Density {kg/m3}
      2576,                    !- Soil Specific Heat {J/kg-K}
      30,                      !- Soil Moisture Content Volume Fraction {percent}
      50,                      !- Soil Moisture Content Volume Fraction at Saturation {percent}
      Site:GroundTemperature:Undisturbed:KusudaAchenbach,    !- Type of Undisturbed Ground Temperature Model
      KATemps,                 !- Name of Undisturbed Ground Temperature Model
      1,                       !- Evapotranspiration Ground Cover Parameter
      GroundCoupledOSCM,       !- Name of Floor Boundary Condition Model
      #{slab_location},        !- Slab Location (InGrade/OnGrade)
      SLAB 8 HW CONCRETE,      !- Slab Material Name
      #{hor_insul},            !- Horizontal Insulation (Yes/No)
      #{hor_slab_insul},       !- Horizontal Insulation Material Name
      #{full_or_perim},        !- Full Horizontal or Perimeter Only (Full/Perimeter)
      ,                        !- Perimeter insulation width (m)
      #{vert_insul},           !- Vertical Insulation (Yes/No)
      VERTICAL SLAB INSULATION,!- Vertical Insulation Name
      #{ins_hgt},              !- Vertical perimeter insulation depth from surface (m)
      Timestep;                !- Domain Simulation Interval. (Timestep/Hourly)
      "

    # Add the slabdomain string to the workspace to create IDF objects
    idfObject = OpenStudio::IdfObject.load(string)
    object = workspace.addObject(idfObject.get).get

    runner.registerInfo('Added Site:GroundDomain object to the model.')

    # loop over all surfaces in the model
    num_changed = 0
    workspace.getObjectsByType('BuildingSurface:Detailed'.to_IddObjectType).each do |surface|
      if surface.getString(1, true).get == 'Floor' && surface.getString(4, true).get == 'Ground'
        surface.setString(4, 'OtherSideConditionsModel')
        surface.setString(5, 'GroundCoupledOSCM')
        num_changed += 1
      end
    end

    runner.registerInfo('Looped over all the surfaces in the model to assign floors to GroundDomain objects.')

    runner.registerFinalCondition("Changed #{num_changed} surfaces")

    return true
  end
end

# register the measure to be used by the application
ZEDGK12InsertGroundDomainEKusdua.new.registerWithApplication
