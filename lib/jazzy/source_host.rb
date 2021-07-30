# frozen_string_literal: true

module Jazzy
  # Deal with different source code repositories
  module SourceHost
    # Factory to create the right source host
    def self.create(options)
      return unless options.source_host_url || options.source_host_files_url

      case options.source_host
      when :github then GitHub.new
      when :gitlab then GitLab.new
      when :bitbucket then BitBucket.new
      end
    end

    # Use GitHub as the default behaviour.
    class GitHub
      include Config::Mixin

      # Human readable name, appears in UI
      def name
        'GitHub'
      end

      # Jazzy extension with logo
      def extension
        name.downcase
      end

      # Logo image filename within extension
      def image
        'gh.png'
      end

      # URL to link to from logo
      def url
        config.source_host_url
      end

      # URL to link to from a SourceDeclaration.
      # Compare using `realpath` because `item.file` comes out of
      # SourceKit/etc.
      def item_url(item)
        return unless files_url && item.file

        realpath = item.file.realpath
        return unless realpath.to_path.start_with?(local_root_realpath)

        path = realpath.relative_path_from(local_root_realpath)
        fragment =
          if item.start_line && (item.start_line != item.end_line)
            item_url_multiline_fragment(item.start_line, item.end_line)
          else
            item_url_line_fragment(item.line)
          end

        "#{files_url}/#{path}##{fragment}"
      end

      private

      def files_url
        config.source_host_files_url
      end

      def local_root_realpath
        @local_root_realpath ||= config.source_directory.realpath.to_path
      end

      # Source host's line numbering link scheme
      def item_url_line_fragment(line)
        "L#{line}"
      end

      def item_url_multiline_fragment(start_line, end_line)
        "L#{start_line}-L#{end_line}"
      end
    end

    # GitLab very similar to GitHub
    class GitLab < GitHub
      def name
        'GitLab'
      end

      def image
        'gitlab.svg'
      end
    end

    # BitBucket has its own line number system
    class BitBucket < GitHub
      def name
        'Bitbucket'
      end

      def image
        'bitbucket.svg'
      end

      def item_url_line_fragment(line)
        "lines-#{line}"
      end

      def item_url_multiline_fragment(start_line, end_line)
        "lines-#{start_line}:#{end_line}"
      end
    end
  end
end
