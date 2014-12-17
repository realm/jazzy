require 'jazzy/source_declaration/access_control_level'
require 'jazzy/source_declaration/type'

module Jazzy
  class SourceDeclaration
    attr_accessor :type
    attr_accessor :file
    attr_accessor :line
    attr_accessor :column
    attr_accessor :usr
    attr_accessor :name
    attr_accessor :declaration
    attr_accessor :abstract
    attr_accessor :discussion
    attr_accessor :return
    attr_accessor :children
    attr_accessor :parameters
    attr_accessor :url
    attr_accessor :mark
    attr_accessor :access_control_level
  end
end
