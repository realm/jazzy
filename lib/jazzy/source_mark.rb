module Jazzy
  class SourceMark
    attr_accessor :name
    attr_accessor :has_start_dash
    attr_accessor :has_end_dash

    def initialize(mark_string = nil)
      return unless mark_string

      # Format: 'MARK: - NAME -' with dashes optional
      mark_string = mark_string[6..-1] # Remove 'MARK: '

      if mark_string.length == 0
        # Empty
        return
      elsif mark_string == '-'
        # Separator
        self.has_start_dash = true
        return
      end

      self.has_start_dash = mark_string.start_with?('- ')
      self.has_end_dash = mark_string.end_with?(' -')

      start_index = has_start_dash ? 2 : 0
      end_index = has_end_dash ? -3 : -1

      self.name = mark_string[start_index..end_index]
    end
  end
end
