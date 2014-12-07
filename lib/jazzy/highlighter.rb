require 'rouge'

module Jazzy
  # This module helps highlight code
  module Highlighter
    def self.highlight(source, language)
      source && Rouge.highlight(source, language, 'html')
    end
  end
end
