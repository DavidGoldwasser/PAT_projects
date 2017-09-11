# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class RequireOpenstudioStandards < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Require openstudio-standards"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    runner.registerWarning "Look in Advanced Output"
    puts ''
    
    puts "Successfully loaded openstudio-standards?"
    begin 
      require 'openstudio-standards'
      puts "TRUE"
    rescue LoadError
      puts "FALSE"
    end
    puts ''
    
    puts "Ruby executable being used:"
    require 'rbconfig'
    puts "#{RbConfig::CONFIG['bindir']}"
    puts ''

    puts "Gem.dir:"
    puts "#{Gem.dir}"
    puts ''
    
    puts "Gem.user_dir:"
    puts "#{Gem.user_dir}"
    puts ''
    
    puts "Gem.user_home:"
    puts "#{Gem.user_home}"
    puts ''
    
    puts "Gem.path (in order):"
    Gem.path.each do |loc|
      puts "#{loc}"
    end
    puts ''
    
    puts "ENV['GEM_PATH'] (in order):"
    ENV['GEM_PATH'].split(';').each do |loc|
      puts "#{loc}"
    end
    puts ''
    
    puts "Here are the gems that are available:"
    local_gems = Gem::Specification.sort_by{ |g| [g.name.downcase, g.version] }.group_by{ |g| g.name }
    local_gems.each do |name, version|
      puts "#{name}"
    end
    puts ''

    return true

  end
  
end

# register the measure to be used by the application
RequireOpenstudioStandards.new.registerWithApplication
