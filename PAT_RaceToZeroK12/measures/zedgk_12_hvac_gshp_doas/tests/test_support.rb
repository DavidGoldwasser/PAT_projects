require 'openstudio'

def runSimulation(output_model_path)
  outdir = output_model_path.parent_path

  config_options = OpenStudio::Runmanager::ConfigOptions.new
  config_options.fastFindEnergyPlus
  tools = config_options.getTools

  epw_path = config_options.getDefaultEPWLocation / OpenStudio::Path.new("USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")
  db_path = outdir / OpenStudio::Path.new('rm.db')

  wf = OpenStudio::Runmanager::Workflow.new
  wf.addWorkflow(OpenStudio::Runmanager::Workflow.new("ModelToIdf->EnergyPlus"))

  wf.add(tools)
  j = wf.create(outdir, output_model_path, epw_path)

  kit = OpenStudio::Runmanager::RunManager.new(db_path, true)
  kit.setPaused(true)
  kit.enqueue(j, false)
  kit.setPaused(false)
  kit.waitForFinished()

  return OpenStudio::SqlFile.new(j.treeAllFiles().getLastByFilename("eplusout.sql").fullPath)
end

