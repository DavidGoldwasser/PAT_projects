module OsLib_QAQC

  # include any general notes about QAQC method here

  #checks the number of unmet hours in the model
  def check_mech_sys_type(category,target_standard, name_only = false)

    #summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new("name", "Mechanical System Type")
    check_elems << OpenStudio::Attribute.new("category", category)

    # add ASHRAE to display of target standard if includes with 90.1
    if target_standard.include?('90.1 2013')
      check_elems << OpenStudio::Attribute.new("description", "Check against ASHRAE 90.1 2013 Tables G3.1.1 A-B. Infers the baseline system type based on the equipment serving the zone and their heating/cooling fuels. Only does a high-level inference; does not look for the presence/absence of required controls, etc.")
    else
      check_elems << OpenStudio::Attribute.new("description", "Check against ASHRAE 90.1. Infers the baseline system type based on the equipment serving the zone and their heating/cooling fuels. Only does a high-level inference; does not look for the presence/absence of required controls, etc.")
    end

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      results = []
      check_elems.each do |elem|
        results << elem.valueAsString
      end
      return results
    end

    begin

      # Get the actual system type for all zones in the model
      act_zone_to_sys_type = {}
      @model.getThermalZones.each do |zone|
        act_zone_to_sys_type[zone] = zone.infer_system_type
      end

      # Get the baseline system type for all zones in the model
      climate_zone = @model.get_building_climate_zone_and_building_type['climate_zone']
      req_zone_to_sys_type = @model.get_baseline_system_type_by_zone(target_standard, climate_zone)

      # Compare the actual to the correct
      @model.getThermalZones.each do |zone|

        # todo - skip if plenum
        is_plenum = false
        zone.spaces.each do |space|
          if space.plenum?
            is_plenum = true
          end
        end
        next if is_plenum

        req_sys_type = req_zone_to_sys_type[zone]
        act_sys_type = act_zone_to_sys_type[zone]

        if act_sys_type == req_sys_type
          puts "#{zone.name} system type = #{act_sys_type}"
        else
          if req_sys_type == "" then req_sys_type = "Unknown" end
          puts "#{zone.name} baseline system type is incorrect. Supposed to be #{req_sys_type}, but was #{act_sys_type} instead."
          check_elems << OpenStudio::Attribute.new("flag", "#{zone.name} baseline system type is incorrect. Supposed to be #{req_sys_type}, but was #{act_sys_type} instead.")
        end

      end

    rescue => e
      # brief description of ruby error
      check_elems << OpenStudio::Attribute.new("flag", "Error prevented QAQC check from running (#{e}).")

      # backtrace of ruby error for diagnostic use
      if @error_backtrace then check_elems << OpenStudio::Attribute.new("flag", "#{e.backtrace.join("\n")}") end
    end

    # add check_elms to new attribute
    check_elem = OpenStudio::Attribute.new("check", check_elems)

    return check_elem
    # note: registerWarning and registerValue will be added for checks downstream using os_lib_reporting_qaqc.rb

  end

end  