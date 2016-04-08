require 'tempfile'

module Jazzy
  module SearchBuilder
    def self.build(source_module, output_dir)
      decls = source_module.all_declarations.select {|d| d.type && d.name && !d.name.empty? }
      index = decls.map do |d|
        {
          name: d.name,
          abstract: d.abstract,
          url: d.url,
          parent_name: d.parent_in_code && d.parent_in_code.name
        }
      end

      Tempfile.open('jazzy-search') do |f|
        f.write(index.to_json)
        f.close

        build_index_js = File.expand_path('../search_builder/build_index.js', __FILE__)
        dest = File.join(output_dir,'search.json')
        `node #{build_index_js} #{f.path} #{dest}`
        # To-do: handle failure
      end

      
    end
  end
end