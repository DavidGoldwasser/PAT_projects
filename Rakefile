require 'bundler'
Bundler.setup

require 'rake'
require 'fileutils'
require 'openstudio'
require 'parallel'

#task default: 'tbd'

# throw way the run directory and everything in it.
def clear_run
  puts 'Deleting run diretory and underlying contents'

  # remove run directory
  FileUtils.rm_rf('run')
end

desc 'Delete contents under run directory'
task :clear_run do
  clear_run
end

# saving base path to measure gems to make it easier to maintain if it changes
def bundle_base_gem_path
  return '.bundle/install/ruby/2.5.0/bundler/gems'
end

# print out measure gems that are were installed by bundle
def find_bundle_measure_paths
  bundle_measure_paths = []

  puts "Getting measure directories for bundle installed measure gems"
  gems = Dir.entries(bundle_base_gem_path)
  gems.each do |gem|
    # check if has lib/measures
    gem = "#{bundle_base_gem_path}/#{gem}/lib/measures"
    next if ! Dir.exists?(gem)
    bundle_measure_paths << gem
  end

  puts "found #{bundle_measure_paths.size} measure directories"

  return bundle_measure_paths.sort
end

desc 'Find Bundle measure paths to add to bundle osws'
task :find_bundle_measure_paths do
  find_bundle_measure_paths
end

# update copies of measures with same directory name from measure gems into the PAT project.
def update_pat(pat_directory_name)
  puts "Updating copy of measures in measure directory of #{pat_directory_name} from .bundle measure gems."

  # array of measures to try and update
  project_measures = []

  # array of measures that were updated
  updated_measures = []

  # story measure gem paths
  measure_gem_paths = find_bundle_measure_paths

  # todo - loop through project measures looking for updates
  target_measures = Dir.entries("#{pat_directory_name}/measures")
  target_measures.each do |proj_measure|
    next if proj_measure.include?(".")

    # update project measures
    project_measures << proj_measure

    # loop through possible locations
    measure_gem_paths.each do |gem_measures|
      next if ! Dir.exists?("#{gem_measures}/#{proj_measure}") 

      # remove existing measure
      #FileUtils.rm_rf("#{pat_directory_name}/measures"proj_measure)

      # copy new measure
      FileUtils.copy_entry("#{gem_measures}/#{proj_measure}","#{pat_directory_name}/measures/#{proj_measure}")

      # add to array
      updated_measures << proj_measure
    end

  end

  # report skipped and updated measures
  puts "** Updated the following measures:"
  updated_measures.each do |updated_measure|
    puts updated_measure
  end
  puts "** Did not find the folllowing measures in measure gems:"
  skipped_project_measures = project_measures - updated_measures
  skipped_project_measures.each do |skipped_project_measure|
    puts skipped_project_measure
  end

  return project_measures
end

desc 'Update measures from measure gems for a single PAT project to'
task :update_pat , [:workflow_name] do |task, args|
  args.with_defaults(workflow_name: 'pat_sddc_office') # todo - having trouble overriding this. 
  workflow_name = args[:workflow_name]
  update_pat(workflow_name)
end

desc 'Setup all osw files to use bundler gems for measure paths'
task :setup_all_osws , [:short_measures] do |task, args|
  args.with_defaults(short_measures: false)
  # convert string to bool
  short_measures = args[:short_measures]
  if short_measures == 'true' then short_measures = true end
  if short_measures == 'false' then short_measures = false end
  find_osws.each do |workflow_name|
    setup_osw(workflow_name,short_measures)
  end
end


desc 'setup additional measures that are not measure gems as if they were installed with bundle install'
task :setup_non_gem_measures do
  puts "Extending bundler install with measures collections that are not currently setup as a ruby gem. This requires SVN"
  puts "setup_osw tasks should be run after this method, or OSW files won't have access to these measures"

  # gather additional measures
  additional_measures = {}
  # either because this is a master or I'm checking out the entire repo I seem to need to pass in a revision as well.
  additional_measures['unmet_hours'] = "-r 99999  https://github.com/UnmetHours/openstudio-measures/branches/master"

  # setup additional measures
  additional_measures.each do |new_dir_name,measure_string|

    non_gem_measures = "#{bundle_base_gem_path}/#{new_dir_name}/lib/measures"
    FileUtils.mkdir_p(non_gem_measures)

    # add measures
    system("svn checkout #{measure_string} #{non_gem_measures}")
  end


end