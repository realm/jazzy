# frozen_string_literal: true

require 'mustache'
require 'sqlite3'

module Jazzy
  module DocBuilder
    # Follows the instructions found at https://kapeli.com/docsets#dashDocset.
    class DocsetBuilder
      include Config::Mixin

      attr_reader :output_dir
      attr_reader :generated_docs_dir
      attr_reader :source_module
      attr_reader :docset_dir
      attr_reader :documents_dir
      attr_reader :name

      def initialize(generated_docs_dir)
        @name = config.docset_title || config.module_names.first
        docset_path = config.docset_path ||
                      "docsets/#{safe_name}.docset"
        @docset_dir = generated_docs_dir + docset_path
        @generated_docs_dir = generated_docs_dir
        @output_dir = docset_dir.parent
        @documents_dir = docset_dir + 'Contents/Resources/Documents/'
      end

      def build!(all_declarations)
        docset_dir.rmtree if docset_dir.exist?
        copy_docs
        copy_icon if config.docset_icon
        write_plist
        create_index(all_declarations)
        create_archive
        create_xml if config.version && config.root_url
      end

      private

      def safe_name
        name.gsub(/[^a-z0-9_\-]+/i, '_')
      end

      def write_plist
        info_plist_path = docset_dir + 'Contents/Info.plist'
        info_plist_path.open('w') do |plist|
          template = Pathname(__dir__) + 'docset_builder/info_plist.mustache'
          plist << Mustache.render(
            template.read,
            lowercase_name: name.downcase,
            lowercase_safe_name: safe_name.downcase,
            name: name,
            root_url: config.root_url,
            playground_url: config.docset_playground_url,
          )
        end
      end

      def create_archive
        target  = "#{safe_name}.tgz"
        source  = docset_dir.basename.to_s
        options = {
          chdir: output_dir.to_s,
          [1, 2] => '/dev/null', # silence all output from `tar`
        }
        system('tar', "--exclude='.DS_Store'", '-cvzf', target, source, options)
      end

      def copy_docs
        files_to_copy = Pathname.glob(generated_docs_dir + '*') -
                        [docset_dir, output_dir]

        FileUtils.mkdir_p documents_dir
        FileUtils.cp_r files_to_copy, documents_dir
      end

      def copy_icon
        FileUtils.cp config.docset_icon, docset_dir + 'icon.png'
      end

      def create_index(all_declarations)
        search_index_path = docset_dir + 'Contents/Resources/docSet.dsidx'
        SQLite3::Database.new(search_index_path.to_s) do |db|
          db.execute('CREATE TABLE searchIndex(' \
            'id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);')
          db.execute('CREATE UNIQUE INDEX anchor ON ' \
            'searchIndex (name, type, path);')
          all_declarations.select(&:type).each do |doc|
            db.execute('INSERT OR IGNORE INTO searchIndex(name, type, path) ' \
              'VALUES (?, ?, ?);', [doc.name, doc.type.dash_type, doc.filepath])
          end
        end
      end

      def create_xml
        (output_dir + "#{safe_name}.xml").open('w') do |xml|
          url = URI.join(config.root_url, "docsets/#{safe_name}.tgz")
          xml << "<entry><version>#{config.version}</version><url>#{url}" \
            "</url></entry>\n"
        end
      end

      # The web URL where the user intends to place the docset XML file.
      def dash_url
        return nil unless config.dash_url || config.root_url

        config.dash_url ||
          URI.join(
            config.root_url,
            "docsets/#{safe_name}.xml",
          )
      end

      public

      # The dash-feed:// URL that links from the Dash icon in generated
      # docs.  This is passed to the Dash app and encodes the actual web
      # `dash_url` where the user has placed the XML file.
      #
      # Unfortunately for historical reasons this is *also* called the
      # 'dash_url' where it appears in mustache templates and so on.
      def dash_feed_url
        dash_url&.then do |url|
          "dash-feed://#{ERB::Util.url_encode(url.to_s)}"
        end
      end
    end
  end
end
