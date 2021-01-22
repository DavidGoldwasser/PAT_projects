# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

require 'erb'
require 'csv'

# Method for sig figs, from stackoverflow
class Float
  def signif(signs)
    Float("%.#{signs}g" % self)
  end
end

#start the measure
class DViewExport < OpenStudio::Measure::ReportingMeasure

  # human readable name
  def name
    return "DView Export"
  end

  # human readable description
  def description
    return "Exports all timeseries variables and meters in the sqlfile to DView data format."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Exports all timeseries variables and meters in the sqlfile to DView data format.  Creates separate files for hourly and timestep data.  Variables and meters should be added using other Measures like Add Output Variable."
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    return args
  end
  
  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)
    
    result = OpenStudio::IdfObjectVector.new
    
    return result
  end
  
  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end
    
    # get the last model and sql file
    #puts "#{Time.new} Loading model"
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    #puts "#{Time.new} Loading sql file"
    sql = runner.lastEnergyPlusSqlFile
    if sql.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sql = sql.get
    model.setSqlFile(sql)

    # Get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql.availableEnvPeriods.each do |env_pd|
      env_type = sql.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
        end
      end
    end

    if ann_env_pd.nil?
      runner.registerAsNotApplicable("Can't find a weather runperiod, make sure you ran an annual simulation, not just the design days.")
      return true
    end
    
    # Get the timestep as fraction of an hour
    ts_frac = 1.0/4.0 # E+ default
    sim_ctrl = model.getSimulationControl
    step = sim_ctrl.timestep
    if step.is_initialized
      step = step.get
      steps_per_hr = step.numberOfTimestepsPerHour
      ts_frac = 1.0/steps_per_hr.to_f
    end
    ts_frac = ts_frac.round(5)
    #runner.registerInfo("The timestep is #{ts_frac} of an hour.")
    
    # Determine the number of hours simulated
    hrs_sim = sql.hoursSimulated
    if hrs_sim.is_initialized
      hrs_sim = hrs_sim.get
    else
      runner.registerWarning("Could not determine number of hours simulated, assuming 8760")
      hrs_sim = 8760
    end
    
    # Determine the maximum number of entries, which is minutely
    max_vals = (hrs_sim * 60).round

    # Get all valid timeseries
    #puts "#{Time.new} Getting all valid timeseries"
    kvs = sql.execAndReturnVectorOfString('SELECT KeyValue FROM ReportDataDictionary')
    vars = sql.execAndReturnVectorOfString('SELECT Name FROM ReportDataDictionary')
    freqs = sql.execAndReturnVectorOfString('SELECT ReportingFrequency FROM ReportDataDictionary')
    unitss = sql.execAndReturnVectorOfString('SELECT Units FROM ReportDataDictionary')
    if kvs.empty? || vars.empty? || freqs.empty? || unitss.empty?
      runner.registerError("Could not get timeseries data from sql file.")
    end
    kvs = kvs.get
    vars = vars.get
    freqs = freqs.get
    unitss = unitss.get
    valid = []
    kvs.each_with_index do |kv, i|
      valid << [freqs[i], vars[i], kvs[i], unitss[i]]
    end
    runner.registerInitialCondition("Found #{valid.size} timeseries outputs.")    
    
    # Create an array of columns, one for each series
    cols = []
    valid.each do |freq, var_name, kv, units|

      # For now, skip Runperiod, Monthly, and Daily data
      next unless freq == 'HVAC System Timestep' ||
                  freq == 'Zone Timestep' ||
                  freq == 'Timestep' ||
                  freq == 'Hourly'

      col = []

      #puts ''
      #puts "---- #{Time.new} Starting timeseries"
      
      # Series name
      name = nil
      if kv == ''
        name = "Site|#{var_name}"
      else
        name = "#{var_name}|#{kv}"
      end
      col << name
      
      # Indicated the start time from
      # Midnight Jan 1 of first datapoint.
      col << 0.0
      
      # Series frequency in hrs
      ts_hr = nil
      case freq
      when 'HVAC System Timestep'
        ts_hr = 1.0 / 60.0 # Convert from non-uniform to minutely
      when 'Timestep', 'Zone Timestep'
        ts_hr = ts_frac
      when 'Hourly'
        ts_hr = 1.0
      when 'Daily'
        ts_hr = 24.0
      when 'Monthly'
        ts_hr = 24.0 * 30 # Even months
      when 'Runperiod'
        ts_hr = 24.0 * 365 # Assume whole year run
      end
      col << ts_hr.round(8)
      
      # Get the values
      ts = sql.timeSeries(ann_env_pd, freq, var_name, kv)
      if ts.empty?
        #runner.registerWarning("No data found for #{freq} #{var_name} #{kv}.")
        next
      else
        #runner.registerInfo("Found data for #{freq} #{var_name} #{kv}.")
        ts = ts.get
      end
      times = ts.dateTimes
      vals = ts.values
      new_units = units

      # If this series is a mass or volume flow rate, determine
      # the type of loop the component is on (air or water)
      # for later unit conversion.
      on_plant_loop = false
      on_air_loop = false
      if units == 'm3/s' || units == 'kg/s' || units == 'Kg/s'
        #puts "---- #{Time.new} Starting plant type determination"
        # Determine if the component is on a plantloop
        model.getPlantLoops.each do |plant_loop|
          if plant_loop.name.get.to_s.upcase == kv.upcase
            on_plant_loop = true
            break
          end
          plant_loop.components.each do |comp|
            if comp.name.get.to_s.upcase == kv.upcase
              on_plant_loop = true
              break
            end
          end
        end

        # If not on plant loop, check air loops
        unless on_plant_loop
          model.getAirLoopHVACs.each do |air_loop|
            if air_loop.name.get.to_s.upcase == kv.upcase
              on_air_loop = true
              break
            end
            air_loop.components.each do |comp|
              if comp.name.get.to_s.upcase == kv.upcase
                on_air_loop = true
                break
              end
            end
          end
        end

        #puts "#{kv} on_plant_loop = #{on_plant_loop}, on_air_loop = #{on_air_loop}"
        
      end

      # For HVAC System Timestep data, convert from E+ 
      # non-uniform timesteps to minutely with missing
      # entries linearly interpolated.
      if freq == 'HVAC System Timestep'

        # puts "---- #{Time.new} Starting nonuniform timestep interpolation"
        # Loop through each of the non-uniformly
        # reported timesteps.
        start_min = 0
        first_timestep = times[0]
        minutely_vals = []
        for i in 1..(times.size - 1)
          reported_time = times[i]
          
          # Figure out how many minutes to the
          # it's been since the previous reported timestep.
          min_until_prev_ts = 0
          for min in start_min..525600
            minute_ts = OpenStudio::Time.new(0, 0, min, 0) # d, hr, min, s
            minute_time = first_timestep + minute_ts
            if minute_time == reported_time
              break
            elsif minute_time < reported_time
              min_until_prev_ts += 1
            else 
              # minute_time > reported_time
              # This scenario shouldn't happen
              runner.registerError("Somehow a timestep was skipped when converting from HVAC System Timestep to uniform minutely.  Results will not look correct.")
            end
          end          
          
          # Get this value
          this_val = vals[i]
          
          # Get the previous value
          prev_val = vals[i-1]
          
          # Linearly interpolate the values between
          val_per_min = (this_val - prev_val)/min_until_prev_ts

          # At each minute, report a value if one
          # exists and a blank if none exists.
          for min in start_min..525600
            minute_ts = OpenStudio::Time.new(0, 0, min, 0) # d, hr, min, s
            minute_time = first_timestep + minute_ts
            if minute_time == reported_time
              # There was a value for this minute,
              # report out this value and skip
              # to the next reported timestep
              start_min = min + 1
              minutely_vals << this_val
              #puts "#{minute_time} = #{this_val}"
              break
            elsif minute_time < reported_time
              # There wasn't a value for this minute,
              # report out a blank entry
              minutely_vals << prev_val + (val_per_min * (min - start_min + 1))
              #puts "#{minute_time} = #{prev_val + (val_per_min * (min - start_min + 1))} interp, mins = #{min - start_min + 1} val_per_min = #{val_per_min}, min_until_prev_ts = #{min_until_prev_ts}"
            else 
              # minute_time > reported_time
              # This scenario shouldn't happen
              runner.registerError("Somehow a timestep was skipped when converting from HVAC System Timestep to uniform minutely.  Results will not look correct.")
            end
          end
          
        end
        
        #puts "---- #{Time.new} Done nonuniform timestep interpolation"
        
        # Replace the original values
        # with the new minutely values
        #puts "minutely has #{minutely_vals.size} entries"
        vals = minutely_vals
        
      end

      # Convert the values to a normal array
      #puts "---- #{Time.new} Starting conversion to normal array" 
      data = []
      if freq == 'HVAC System Timestep'
        # Already normal array
        data = vals
      else
        for i in 0..(vals.size - 1)
          #next if vals[i].nil?
          data[i] = vals[i].signif(5)
        end
      end

      # Determine the conversion factor
      conversion_factor = 1
      case units
      when 'C'
        new_units = 'F'
      when 'm3/s'
        if on_plant_loop
          new_units = 'gal/min'
        elsif on_air_loop
          new_units = 'cfm'
        end
      when 'kg/s', 'Kg/s'
        if on_plant_loop
          new_units = 'gal/min'
          conversion_factor = 0.2642 * 60 # 1 kg water = 0.2642 gal
        elsif on_air_loop
          new_units = 'cfm'
          conversion_factor = 27.69 * 60 # 1 kg air = 27.69 ft3
        end
      end
      
      # Perform unit conversion
      #puts "---- #{Time.new} Starting unit conversion"
      if units == 'C'
        data = data.collect{|e| e * 9.0/5.0 + 32.0}
      else
        data = data.collect{|e| e * conversion_factor} unless conversion_factor == 1
      end
      
      # Append the units and values
      col << new_units
      col += data
      
      puts "col is nil" if col.nil?
      
      # Add the series
      cols << col
      
    end

    # Create a DView csv with a column for each series.
    # For details on the file format, see the reference here:
    # https://beopt.nrel.gov/sites/beopt.nrel.gov/files/exes/DataFileTemplate.pdf
    #puts "#{Time.new} Writing CSV"

    # Don't export empty files
    if cols.size == 0
      runner.registerInfo("No timeseries data series were found in the sql file, no DView file will be exported.")
      return true
    end
    
    # Sort by number of datapoints (-s.size aka largest to smallest)
    # for correct transpose behavior, 
    # then by variable name ( s[0] ) so names are sorted inside DView.
    cols = cols.sort_by {|s| [-s.size, s[0]] }
    
    # Transpose the columns to rows
    longest_series_length = cols[0].size
    max_length_array = Array.new(longest_series_length + 3) # Make an array equal to the longest possible array
    runner.registerInfo("#{cols.size} series were found")
    runner.registerInfo("longest series is #{longest_series_length.size}")
    rows = max_length_array.zip(*cols[0..-1])
    puts rows[0]

    # Write the rows out to CSV
    csv_out_path = './output.dview'
    CSV.open(csv_out_path, "wb") do |csv|
      # Write the header row
      csv << ["wxDVFileHeaderVer.1"]
      # Write each row
      rows.each do |row|

        # Drop all nil values
        row = row.reject { |c| c.nil? }
        # Stop when we get to blank rows
        if row.size == 0 
          break
        end
        # Write this row
        csv << row
      end
    end  
    runner.registerInfo("DView CSV file saved to #{csv_out_path}.")
  
    # close the sql file
    sql.close

    return true
 
  end

end

# register the measure to be used by the application
DViewExport.new.registerWithApplication
