# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class RemoveEMSObjects < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Remove EMS objects'
  end

  # human readable description
  def description
    return 'This will remove all EMS objects from the model'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This initial use case of this is to cleanup EMS added by prototype measure before running create typical building from model after it. This is probably only ncessary when chaning HVAC is selected'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.objects.size} objects.")


    # remove EMS objects
    model.getEnergyManagementSystemActuators.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemConstructionIndexVariables.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemCurveOrTableIndexVariables.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemGlobalVariables.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemInternalVariables.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemMeteredOutputVariables.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemOutputVariables.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemPrograms.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemProgramCallingManagers.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemSensors.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemSubroutines.each do |ems_obj|
      ems_obj.remove
    end
    model.getEnergyManagementSystemTrendVariables.each do |ems_obj|
      ems_obj.remove
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.objects.size} size.")

    return true
  end
end

# register the measure to be used by the application
RemoveEMSObjects.new.registerWithApplication
