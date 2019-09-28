require 'rouge'

module Jazzy
  # This module helps highlight code
  module Highlighter
    class Formatter < Rouge::Formatters::HTML
      def initialize(language)
        @language = language
        super()
      end

      def stream(tokens, &b)
        yield "<pre class=\"highlight #{@language}\"><code>"
        super
        yield "</code></pre>\n"
      end
    end

    def self.highlight(source, language)
      source && Rouge.highlight(source, language, Formatter.new(language))
    end
  end
end
