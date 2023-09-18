# frozen_string_literal: true

module Jazzy
  module SearchBuilder
    def self.build(source_module, output_dir)
      decls = source_module.all_declarations.select do |d|
        d.type && d.name && !d.name.empty?
      end
      index = decls.to_h do |d|
        [d.url,
         {
           name: d.name,
           abstract: d.abstract && d.abstract.split("\n").map(&:strip).first,
           parent_name: d.parent_in_code&.name,
         }.reject { |_, v| v.nil? || v.empty? }]
      end
      File.write(File.join(output_dir, 'search.json'), index.to_json)
    end
  end
end
