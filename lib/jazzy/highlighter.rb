require 'rouge'

module Jazzy
  # This module helps highlight code
  module Highlighter
    SWIFT = 'swift'.freeze
    OBJC = 'objective_c'.freeze

    class Formatter < Rouge::Formatters::HTML
      def initialize(language)
        @language = Highlighter.formatted_language(language)
        super()
      end

      def stream(tokens, &b)
        yield "<pre class=\"highlight #{@language}\"><code>"
        super
        yield "</code></pre>\n"
      end
    end

    # Maps the language to the format required by Rouge
    def self.formatted_language(language)
      if language.downcase.include? SWIFT
        SWIFT
      else
        OBJC
      end
    end

    def self.highlight(source, language)
      source && Rouge.highlight(
        source,
        formatted_language(language),
        Formatter.new(language),
      )
    end
  end
end
