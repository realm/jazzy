# Restores the config to the default state before each requirement

module Bacon
  class Context
    old_run_requirement = instance_method(:run_requirement)

    define_method(:run_requirement) do |description, spec|
      temporary_directory = SpecHelper.temporary_directory

      ::Jazzy::Config.instance = nil
      ::Jazzy::Config.instance.tap do |c|
        c.source_directory = temporary_directory
      end

      temporary_directory.rmtree if temporary_directory.exist?
      temporary_directory.mkpath

      old_run_requirement.bind(self).call(description, spec)
    end
  end
end
