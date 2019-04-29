 Shoes.app :title => "Simple OSW Runner" do
   button "Run OpenStudio ZEDG K12 Workflow" do
   	 # openstudio command doesn't work here without the path
   	 openstudio_path = "/Applications/OpenStudio-2.8.0/bin/"
     osw_path = "/Users/dgoldwas/Documents/GitHub/Personal/PAT_projects/PAT_SDDC_PrimarySchool/workflow_testing/zedg_k12_01/data_point.osw"
     append { para "Running OSW using the OpenStudio CLI." }
     #command_string = "#{openstudio_path}openstudio run -m -w #{osw_path}"
     command_string = "#{openstudio_path}openstudio run -w #{osw_path}"
     debug(command_string)
     asdf = system(command_string)
     # asdf = %x|command_string|
     debug("system call return #{asdf}")
     append{ para "Finished simulation, opening results html." }
     system("open zedg_k12_01/reports/openstudio_results_report.html")
     # todo - add in system notification

     # add core functionality by altering OSW based on user input
     # todo - make bool to run measures only or to run simulation
     # todo - enable change of seed model
     # todo - enable change of argument for location (better address weather file)
     # make use site from BCL meausre if it seems reliable
     # todo - make bool for each measure in workflow
     # todo - expose arguments from OSW and ability to change them

     # reporting
     # todo - report back initial and final condition of each measure
     # todo - open or link to html

     # make use more generalized
     # make path to OSW relative
     # todo - test out packging with resoruces like measures, seed and weather
     # todo - make bool to choose OSW so more generalized OSW runner
   end
 end