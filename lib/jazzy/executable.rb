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
      def execute_command(executable, args, raise_on_failure, env: {})
        require 'shellwords'
        bin = `which #{executable.to_s.shellescape}`.strip
        raise "Unable to locate the executable `#{executable}`" if bin.empty?

        require 'open4'

        stdout = IO.new
        stderr = IO.new($stderr)

        options = { stdout: stdout, stderr: stderr, status: true }
        status  = Open4.spawn(env, bin, *args, options)
        unless status.success?
          full_command = "#{bin.shellescape} #{args.map(&:shellescape)}"
          output = stdout.to_s << stderr.to_s
          if raise_on_failure
            raise "#{full_command}\n\n#{output}"
          else
            warn("[!] Failed: #{full_command}")
          end
        end
        [stdout.to_s, status]
      end
    end
  end
end
