module Jazzy
  module SearchBuilder
    def self.build(source_module, output_dir)
      decls = source_module.all_declarations.select do |d|
        d.type && d.name && !d.name.empty?
      end
      index = Hash[decls.map do |d|
        [d.url,
         {
           name: d.name,
           abstract: d.abstract && d.abstract.split(/\n/).map(&:strip).first,
           parent_name: d.parent_in_code && d.parent_in_code.name,
         }.reject { |_, v| v.nil? || v.empty? }]
      end
      ]
      File.open(File.join(output_dir, 'search.json'), 'w') do |f|
        f.write(index.to_json)
      end
    end
  end
end
