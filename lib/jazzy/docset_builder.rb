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

      def initialize(generated_docs_dir, source_module)
        @source_module = source_module
        docset_path = config.docset_path ||
                      "docsets/#{source_module.name}.docset"
        @docset_dir = generated_docs_dir + docset_path
        @generated_docs_dir = generated_docs_dir
        @output_dir = docset_dir.parent
        @documents_dir = docset_dir + 'Contents/Resources/Documents/'
      end

      def build!
        docset_dir.rmtree if docset_dir.exist?
        copy_docs
        copy_icon if config.docset_icon
        write_plist
        create_index
        create_archive
        create_xml if config.version && config.root_url
      end

      private

      def write_plist
        info_plist_path = docset_dir + 'Contents/Info.plist'
        info_plist_path.open('w') do |plist|
          template = Pathname(__dir__) + 'docset_builder/info_plist.mustache'
          plist << Mustache.render(
            template.read,
            lowercase_name: source_module.name.downcase,
            name: source_module.name,
          )
        end
      end

      def create_archive
        target  = "#{source_module.name}.tgz"
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
        FileUtils.cp config.docset_icon, @docset_dir + 'icon.png'
      end

      def create_index
        search_index_path = docset_dir + 'Contents/Resources/docSet.dsidx'
        SQLite3::Database.new(search_index_path.to_s) do |db|
          db.execute('CREATE TABLE searchIndex(' \
            'id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);')
          db.execute('CREATE UNIQUE INDEX anchor ON ' \
            'searchIndex (name, type, path);')
          source_module.all_declarations.select(&:type).each do |doc|
            db.execute('INSERT OR IGNORE INTO searchIndex(name, type, path) ' \
              'VALUES (?, ?, ?);', [doc.name, doc.type.dash_type, doc.url])
          end
        end
      end

      def create_xml
        (output_dir + "#{source_module.name}.xml").open('w') do |xml|
          url = URI.join(config.root_url, "docsets/#{source_module.name}.tgz")
          xml << "<entry><version>#{config.version}</version><url>#{url}" \
                 "</url></entry>\n"
        end
      end
    end
  end
end
