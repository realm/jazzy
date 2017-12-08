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

    # What Rouge calls the language
    def self.default_language
      if Config.instance.objc_mode
        'objective_c'
      else
        'swift'
      end
    end

    def self.highlight(source, language = default_language)
      source && Rouge.highlight(source, language, Formatter.new(language))
    end

    # 'language' can be nil, use Rouge to guess at the right one from source
    def self.highlight_code_block(source, language)
      lexer = Rouge::Lexer.find_fancy(language, source) ||
              Rouge::Lexers::PlainText
      Rouge.highlight(source, lexer, Formatter.new(lexer.tag))
    end
  end
end
