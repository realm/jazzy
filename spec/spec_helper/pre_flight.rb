# Restores the config to the default state before each requirement

module Bacon
  class Context
    old_run_requirement = instance_method(:run_requirement)

    define_method(:run_requirement) do |description, spec|
      ::Jazzy::Config.instance = nil
      ::Jazzy::Config.instance.tap do |c|
        c.source_directory  =  SpecHelper.temporary_directory
      end

      SpecHelper.temporary_directory.rmtree if SpecHelper.temporary_directory.exist?
      SpecHelper.temporary_directory.mkpath

      old_run_requirement.bind(self).call(description, spec)
    end
  end
end
