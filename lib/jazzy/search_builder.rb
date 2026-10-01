# frozen_string_literal: true

# Workarounds for:
# 1. CocoaPods has died leaving a dep on activesupport < 8.0
# 2. JSON (builtin) is now at 3.0+
# 3. JSON 3+ is not supported by activesupport < 8.0
#
# Try to support CocoaPods for one more year by patching the
# problematic methods.

module JSON
  class << self
    # Store a reference to the original json gem's parse method
    alias real_parse parse
    alias real_generate generate

    def parse(source, **opts)
      opts = opts.dup
      opts.delete(:quirks_mode)
      real_parse(source, **opts)
    end

    def generate(source, **opts)
      opts = opts.dup
      opts.delete(:quirks_mode)
      real_generate(source, **opts)
    end
  end
end

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
