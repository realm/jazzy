# frozen_string_literal: true

module Jazzy
  class SourceMark
    attr_accessor :name
    attr_accessor :has_start_dash
    attr_accessor :has_end_dash

    def initialize(mark_string = nil)
      return unless mark_string

      # Format: 'MARK: - NAME -' with dashes optional
      mark_content = mark_string.sub(/^MARK: /, '')

      if mark_content.empty?
        # Empty
        return
      elsif mark_content == '-'
        # Separator
        self.has_start_dash = true
        return
      end

      self.has_start_dash = mark_content.start_with?('- ')
      self.has_end_dash = mark_content.end_with?(' -')

      start_index = has_start_dash ? 2 : 0
      end_index = has_end_dash ? -3 : -1

      self.name = mark_content[start_index..end_index]
    end

    def self.new_generic_requirements(requirements)
      marked_up = requirements.gsub(/\b([^=:]\S*)\b/, '`\1`')
      text = "Available where #{marked_up}"
      new(text)
    end

    def empty?
      !name && !has_start_dash && !has_end_dash
    end

    def copy(other)
      self.name = other.name
      self.has_start_dash = other.has_start_dash
      self.has_end_dash = other.has_end_dash
    end

    # Can we merge the contents of another mark into our own?
    def can_merge?(other)
      other.empty? || other.name == name
    end
  end
end
