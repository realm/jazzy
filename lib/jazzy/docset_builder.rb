require 'sqlite3'

module Jazzy
  module DocBuilder
    # Follows the instructions found at http://kapeli.com/docsets#dashDocset.
    class DocsetBuilder
      include Config::Mixin

      attr_reader :output_dir
      attr_reader :source_module
      attr_reader :docset_dir
      attr_reader :documents_dir

      def initialize(output_dir, source_module)
        @output_dir = output_dir
        @source_module = source_module
        @docset_dir = output_dir + "#{source_module.name}.docset"
        @documents_dir = docset_dir + 'Contents/Resources/Documents/'
      end

      def build!
        docset_dir.rmtree if docset_dir.exist?
        copy_docs
        write_plist
        create_index
      end

      private

      def write_plist
        require 'mustache'
        info_plist_path = docset_dir + 'Contents/Info.plist'
        info_plist_path.open('w') do |plist|
          template = Pathname(__FILE__) + '../docset_builder/info_plist.mustache'
          plist << Mustache.render(template.read,
            bundle_identifier: source_module.name.downcase,
            name: source_module.name,
            platform_family: config.docset_platform
          )
        end
      end

      def copy_docs
        files_to_copy = Dir.glob(output_dir + '**/*')

        FileUtils.mkdir_p documents_dir
        FileUtils.cp_r files_to_copy, documents_dir
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
    end
  end
end
