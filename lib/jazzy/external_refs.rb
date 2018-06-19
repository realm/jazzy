require 'sqlite3'

module Jazzy
  class ExternalRefs

    def self.xcode_db
      @xcode_db ||=
          SQLite3::Database.new('/Applications/Xcode.app/Contents/SharedFrameworks/DNTDocumentationSupport.framework/Versions/A/Resources/external/map.db')
    end

    def self.resolve(name)
      token = "/#{name.downcase}/"
      rows = xcode_db.execute("select reference_path from map where reference_path like '%#{token}%' limit 1")
      return nil if rows.empty?
      # strip all following symbol we are looking for
      "https://developer.apple.com/documentation/" +
        rows[0][0].sub(/#{token}.*$/, token)
    rescue
      nil
    end
  end
end  
