require 'sqlite3'

module Jazzy
  module DocBuilder
    # Follows the instructions found at http://kapeli.com/docsets#dashDocset.
    class DocsetBuilder
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
        info_plist_path = docset_dir + 'Contents/Info.plist'
        info_plist_path.open('w') do |plist|
          plist << <<-INFO_PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>CFBundleIdentifier</key>
      <string>con.jazzy.#{source_module.name.downcase}</string>
    <key>CFBundleName</key>
      <string>#{source_module.name}</string>
    <key>DocSetPlatformFamily</key>
      <string>jazzy</string>
    <key>isDashDocset</key>
      <true/>
    <key>dashIndexFilePath</key>
      <string>index.html</string>
    <key>isJavaScriptEnabled</key>
      <true/>
    <key>DashDocSetFamily</key>
      <string>dashtoc</string>
  </dict>
</plist>
          INFO_PLIST
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
          db.execute('CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);')
          db.execute('CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);')
          source_module.all_declarations.each do |doc|
            db.execute("INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?, ?, ?);", [doc.name, doc.dash_type, doc.url])
          end
        end
      end
    end
  end
end
