# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
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

class NzeHvac < OpenStudio::Measure::ModelMeasure

  require 'openstudio-standards'

  def name
    return "NZEHVAC"
  end

  # human readable description
  def description
    return "This measure replaces the existing HVAC system if any with the user selected HVAC system.  The user can select how to partition the system, applying it to the whole building, a system per building type, a system per building story, or automatically partition based on residential/non-residential occupany types and space loads."
  end

  # human readable description of modeling approach
  def modeler_description
    return "HVAC system creation logic uses [openstudio-standards](https://github.com/NREL/openstudio-standards) and efficiency values are defined in the openstudio-standards Standards spreadsheet under the *NREL ZNE Ready 2017* template."
  end

  def report_pump_variables(model, runner, std)
    model.getPumpVariableSpeeds.each do |pump|
      pump_bhp = std.pump_brake_horsepower(pump)
      pump_mhp = std.pump_motor_horsepower(pump)
      pump_w_per_gpm = std.pump_rated_w_per_gpm(pump)
      runner.registerInfo("#{pump.name.to_s} has brake horsepower: #{pump_bhp.round(2)}, motor_horsepower: #{pump_mhp.round(2)}, rated watts per gpm: #{pump_w_per_gpm.round(2)}")
    end
  end

  def report_fan_variables(model, runner, std)
    model.getFanVariableVolumes.each do |fan|
      fan_bhp = std.fan_brake_horsepower(fan)
      fan_mhp = std.fan_motor_horsepower(fan)
      fan_w_per_cfm = std.fan_rated_w_per_cfm(fan)
      runner.registerInfo("#{fan.name.to_s} has brake horsepower: #{fan_bhp.round(2)}, motor_horsepower: #{fan_mhp.round(2)}, rated watts per cfm: #{fan_w_per_cfm.round(2)}")
    end
  end

  def add_system_to_zones(model, runner, hvac_system_type, zones, std)
    # create HVAC system
    # use methods in openstudio-standards
    # Standard.model_add_hvac_system(model, system_type, main_heat_fuel, zone_heat_fuel, cool_fuel, zones)
    # can be combination systems or individual objects - depends on the type of system
    case hvac_system_type.to_s
    when "VAV Reheat"
      std.model_add_hvac_system(model, 'VAV Reheat', 'NaturalGas', 'NaturalGas', 'Electricity', zones,
                                hot_water_loop_type: "LowTemperature",
                                chilled_water_loop_cooling_type: "AirCooled",
                                air_loop_cooling_type: "Water")
    when "PVAV Reheat" #NOTE: This system call is temporary until the "PVAV Reheat" bug is fixed in openstudio-standards
      std.model_add_hvac_system(model, 'VAV Reheat', 'NaturalGas', 'NaturalGas', 'Electricity', zones,
                                hot_water_loop_type: "LowTemperature",
                                air_loop_cooling_type: "DX")
    when "VRF with DOAS"
      std.model_add_hvac_system(model, 'VRF with DOAS', 'Electricity', 'nil', 'Electricity', zones)
    when "VRF with DOAS with DCV"
      std.model_add_hvac_system(model, 'VRF with DOAS with DCV', 'Electricity', 'nil', 'Electricity', zones)
    when "Ground Source Heat Pumps with DOAS"
      std.model_add_hvac_system(model, 'Ground Source Heat Pumps with DOAS', 'Electricity', nil, 'Electricity', zones,
                                air_loop_heating_type: "DX",
                                air_loop_cooling_type: "DX")
    when "Ground Source Heat Pumps with DOAS with DCV"
      std.model_add_hvac_system(model, 'Ground Source Heat Pumps with DOAS with DCV', 'Electricity', nil, 'Electricity', zones,
                                air_loop_heating_type: "DX",
                                air_loop_cooling_type: "DX")
    when "Fan Coils with DOAS"
      std.model_add_hvac_system(model, 'Fan Coil with DOAS', 'NaturalGas', nil, 'Electricity', zones,
                                hot_water_loop_type: "LowTemperature")
    when "Fan Coils with DOAS with DCV"
      std.model_add_hvac_system(model, 'Fan Coil with DOAS with DCV', 'NaturalGas', nil, 'Electricity', zones,
                                hot_water_loop_type: "LowTemperature")
    when "Fan Coils with ERVs"
      std.model_add_hvac_system(model, 'Fan Coil with ERVs', 'NaturalGas', nil, 'Electricity', zones,
                                hot_water_loop_type: "LowTemperature")
    when "PSZ-HP"
      std.model_add_hvac_system(model, 'PSZ-HP', 'Electricity', 'Electricity', 'Electricity', zones)
    else
      runner.registerError("HVAC System #{hvac_system_type} not recognized")
      return false
    end
    runner.registerInfo("Added HVAC System type #{hvac_system_type} to the model for #{zones.size} zones")
  end

  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # argument to remove existing hvac system
    remove_existing_hvac = OpenStudio::Measure::OSArgument::makeBoolArgument("remove_existing_hvac",true)
    remove_existing_hvac.setDisplayName("Remove existing HVAC?")
    remove_existing_hvac.setDefaultValue(false)
    args << remove_existing_hvac

    # argument for HVAC system type
    hvac_system_type_choices = OpenStudio::StringVector.new

    # VAV system with air-side economizer, served by a condensing boiler and air-cooled chiller
    hvac_system_type_choices << "VAV Reheat"

    # Packaged RTU VAV system with air-side economizer, served by a condensing boiler and DX cooling
    hvac_system_type_choices << "PVAV Reheat"

    # DOAS system served by DX coils and VRF terminals served by air-cooled VRF outdoor unit
    hvac_system_type_choices << "VRF with DOAS"

    # DOAS system with DCV served by DX Coils and VRF terminals served by air-cooled VRF outdoor unit
    hvac_system_type_choices << "VRF with DOAS with DCV"

    # DOAS system served by DX coils with zone heat pumps served by a ground-source heat pump loop
    hvac_system_type_choices << "Ground Source Heat Pumps with DOAS"

    # DOAS system with DCV served by DX coils and zone heat pumps served by a ground-source heat pump loop
    hvac_system_type_choices << "Ground Source Heat Pumps with DOAS with DCV"

    # DOAS system with zone fan coils both served by a condensing boiler and water-cooled chiller with water-side economizer
    hvac_system_type_choices << "Fan Coils with DOAS"

    # DOAS system with DCV and zone fan coils both served by a condensing boiler and water-cooled chiller with water-side economizer
    hvac_system_type_choices << "Fan Coils with DOAS with DCV"

    # Zone ERVs and zone fan coils both served by a condensing boiler and water-cooled chiller with water-side economizer
    hvac_system_type_choices << "Fan Coils with ERVs"

    # FUTURE OPTIONS TO INCLUDE
    # DOAS system with zone fan coils served by a air-source heat pump
    #hvac_system_type_choices << "Fan Coils with DOAS, ASHP"

    # DOAS system with thermally active slab served by a condensing boiler and water-cooled chiller with water-side economizer
    #hvac_system_type_choices << "Radiant Slab with DOAS"

    # DOAS system with thermally active slab served by an air-source heat pump
    #hvac_system_type_choices << "Radiant Slab with DOAS, ASHP"

    # DOAS system with chilled beams served by a condensing boiler and water-cooled chiller with water-side economizer
    #hvac_system_type_choices << "Chilled Beams with DOAS"

    hvac_system_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("hvac_system_type", hvac_system_type_choices, true)
    hvac_system_type.setDisplayName("HVAC System Type:")
    hvac_system_type.setDescription("Details on HVAC system type in measure documentation.")
    hvac_system_type.setDefaultValue("Fan Coils with DOAS")
    args << hvac_system_type

    # argument for how to partition HVAC system
    hvac_system_partition_choices = OpenStudio::StringVector.new
    hvac_system_partition_choices << "Automatic Partition"
    hvac_system_partition_choices << "Whole Building"
    hvac_system_partition_choices << "One System Per Building Story"
    hvac_system_partition_choices << "One System Per Building Type"

    hvac_system_partition = OpenStudio::Measure::OSArgument::makeChoiceArgument("hvac_system_partition", hvac_system_partition_choices, true)
    hvac_system_partition.setDisplayName("HVAC System Partition:")
    hvac_system_partition.setDescription("Automatic Partition will separate the HVAC system by residential/non-residential and if loads and schedules are substantially different.")
    hvac_system_partition.setDefaultValue("Automatic Partition")
    args << hvac_system_partition

    # add an argument for ventilation schedule

    return args
  end # end the arguments method

  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign user inputs
    remove_existing_hvac = runner.getBoolArgumentValue("remove_existing_hvac", user_arguments)
    hvac_system_type = runner.getOptionalStringArgumentValue("hvac_system_type", user_arguments)
    hvac_system_partition = runner.getOptionalStringArgumentValue("hvac_system_partition", user_arguments)
    hvac_system_partition = hvac_system_partition.to_s

    # standard to access methods in openstudio-standards
    std = Standard.build("NREL ZNE Ready 2017")

    # ensure standards building type is set
    unless model.getBuilding.standardsBuildingType.is_initialized
      dominant_building_type = std.model_get_standards_building_type(model)
      if dominant_building_type.nil?
        # use office building type if none in model
        model.getBuilding.setStandardsBuildingType("Office")
      else
        model.getBuilding.setStandardsBuildingType(dominant_building_type)
      end
    end

    # get the climate zone
    climate_zone_obj = model.getClimateZones.getClimateZone("ASHRAE", 2006)
    if climate_zone_obj.empty()
      runner.registerError("Please assign an ASHRAE climate zone to the model before running the measure.")
      return false
    else
      climate_zone = "ASHRAE 169-2006-#{climate_zone_obj.value}"
    end

    # remove existing hvac system from model
    if remove_existing_hvac
      runner.registerInfo("Removing existing HVAC systems from the model")
      std.remove_HVAC(model)
    end

    # exclude plenum zones, zones without thermostats, and zones with no floor area
    conditioned_zones = []
    model.getThermalZones.each do |zone|
      next if std.thermal_zone_plenum?(zone)
      next if !std.thermal_zone_heated?(zone) && !std.thermal_zone_cooled?(zone)
      conditioned_zones << zone
    end

    # logic to partition thermal zones to be served by different HVAC systems
    case hvac_system_partition

      when "Automatic Partition"
        # group zones by occupancy type (residential/nonresidential)
        # split non-dominant groups if their total area exceeds 20,000 ft2.
        sys_groups = std.model_group_zones_by_type(model, OpenStudio.convert(20000, 'ft^2', 'm^2').get)

        # assume secondary system type is PSZ-AC for VAV Reheat otherwise assume same hvac system type
        sec_sys_type = hvac_system_type # same as primary system type
        sec_sys_type = 'PSZ-HP' if (hvac_system_type.to_s == 'VAV Reheat') || (hvac_system_type.to_s == 'PVAV Reheat')

        sys_groups.each do |sys_group|
          # add the primary system to the primary zones and the secondary system to any zones that are different
          # differentiate primary and secondary zones based on operating hours and internal loads (same as 90.1 PRM)
          pri_sec_zone_lists = std.model_differentiate_primary_secondary_thermal_zones(model, sys_group['zones'])

          # add the primary system to the primary zones
          add_system_to_zones(model, runner, hvac_system_type, pri_sec_zone_lists['primary'], std)

          # add the secondary system to the secondary zones (if any)
          if !pri_sec_zone_lists['secondary'].empty?
            runner.registerInfo("Secondary system type is #{sec_sys_type}")
            add_system_to_zones(model, runner, sec_sys_type, pri_sec_zone_lists['secondary'], std)
          end
        end

      when "Whole Building"
        add_system_to_zones(model, runner, hvac_system_type, conditioned_zones, std)

      when "One System Per Building Story"
        story_groups = std.model_group_zones_by_story(model, conditioned_zones)
        story_groups.each do |story_zones|
          add_system_to_zones(model, runner, hvac_system_type, story_zones, std)
        end

      when "One System Per Building Type"
        system_groups = std.model_group_zones_by_building_type(model, 0.0)
        system_groups.each do |system_group|
          add_system_to_zones(model, runner, hvac_system_type, system_group['zones'], std)
        end

      else
        runner.registerError("Invalid HVAC system partition choice")
        return false
    end

    # check that the directory name isn't too long for a sizing run; sometimes this isn't necessary
    # if "#{Dir.pwd} }/SizingRun".length > 90
    #   runner.registerError("Directory path #{Dir.pwd}/SizingRun is greater than 90 characters and too long perform a sizing run.")
    #   return false
    # end

    # check that weather file exists for a sizing run
    if !model.weatherFile.is_initialized
      runner.registerError("Weather file not set. Cannot perform sizing run.")
      return false
    end

    # log the build messages and errors to a file before sizing run in case of failure
    log_messages_to_file("#{Dir.pwd}/openstudio-standards.log", debug = true)

    # perform a sizing run to get equipment sizes for efficiency standards
    if std.model_run_sizing_run(model, "#{Dir.pwd}/SizingRun") == false
      runner.registerError("Unable to perform sizing run for hvac system #{hvac_system_type} for this model.  Check the openstudio-standards.log in this measure for more details.")
      log_messages_to_file("#{Dir.pwd}/openstudio-standards.log", debug = true)
      return false
    end

    # report fan and pump power ratings
    runner.registerInfo("Initial default equipment efficiencies:")
    report_pump_variables(model, runner, std)
    report_fan_variables(model, runner, std)

    # apply hvac setting and standards from Prototype.Model.rb
    model.getYearDescription.setDayofWeekforStartDay('Sunday')

    # add economizers if multizone VAV reheat system
    std.apply_economizers(climate_zone, model)

    # apply the HVAC efficiency standards
    std.model_apply_hvac_efficiency_standard(model, climate_zone)

    # log the build messages and errors to a file
    log_messages_to_file("#{Dir.pwd}/openstudio-standards.log", debug = true)
    reset_log()

    # report fan and pump power ratings
    runner.registerInfo("Final equipment efficiencies:")
    report_pump_variables(model, runner, std)
    report_fan_variables(model, runner, std)

    runner.registerFinalCondition("Added system type #{hvac_system_type} to model.")

    return true

  end # end the run method
end # end the measure

# this allows the measure to be used by the application
NzeHvac.new.registerWithApplication