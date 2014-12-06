require 'jazzy/sourcekitten'

module Jazzy
  # This module helps highlight Swift code
  module SwiftHighlighting
    # Syntax type mapping between SourceKit and highlight.css
    @types = {
      'comment' => 'c',            # Comment
      'comment.url' => 'cs',       # Comment.Special
      'keyword' => 'k',            # Keyword
      'identifier' => 'ow',        # Operator.Word
      'attribute.builtin' => 'nb', # Name.Builtin
      'string' => 's',             # Literal.String
      'typeidentifier' => 'kt',    # Keyword.Type
      'number' => 'm',             # Literal.Number
      'attribute.id' => 'na',      # Name.Attribute
    }.freeze

    # Returns Swift string with proper HTML spans for code highlighting
    def self.highlight(swift_string)
      syntax_json = SourceKitten.run_sourcekitten(
        ['--syntax-text', "\"#{swift_string}\""],
      )
      syntax = JSON.parse(syntax_json)
      total_offset = 0
      syntax.each do |syntax_info|
        offset = syntax_info['offset'] + total_offset
        length = syntax_info['length']
        type = syntax_info['type']
                .sub(/^source\.lang\.swift\.syntaxtype\./, '')
        css_type = @types[type]
        substring = swift_string[offset..(offset + length)]
        replacement_string = "<span class=\"#{css_type}\">#{substring}</span>"
        total_offset += replacement_string.length - substring.length
        swift_string.sub!(substring, replacement_string)
      end
      swift_string
    end
  end
end
