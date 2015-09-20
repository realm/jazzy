module Jazzy
  module Executable
    class IO < Array
      def initialize(io = nil)
        @io = io
      end

      def <<(value)
        super
      ensure
        @io << value.to_s if @io
      end

      def to_s
        join("\n")
      end
    end

    class << self
      def execute_command(executable, args, exit_on_failure, env: {})
        require 'shellwords'
        bin = `which #{executable.to_s.shellescape}`.strip
        raise "Unable to locate the executable `#{executable}`" if bin.empty?

        require 'open4'

        stdout, stderr = IO.new, IO.new($stderr)

        options = { stdout: stdout, stderr: stderr, status: true }
        status  = Open4.spawn(env, bin, *args, options)
        unless status.success?
          if exit_on_failure
            exit status.exitstatus
          else
            full_command = "#{bin.shellescape} #{args.map(&:shellescape)}"
            warn("[!] Failed: #{full_command}")
          end
        end
        [stdout.to_s, status]
      end
    end
  end
end
