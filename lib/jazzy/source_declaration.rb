module Jazzy
  class SourceDeclaration
    attr_accessor :kindNamePlural
    attr_accessor :kind
    attr_accessor :kindName
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

    DASH_TYPES = {
      'Class Method' => 'Method',
      'Class Variable' => 'Variable',
      'Class' => 'Class',
      'Constructor' => 'Constructor',
      'Destructor' => 'Method',
      'Global Variable' => 'Global',
      'Enum Element' => 'Element',
      'Enum' => 'Enum',
      'Extension' => 'Extension',
      'Function' => 'Function',
      'Instance Method' => 'Method',
      'Instance Variable' => 'Property',
      'Local Variable' => 'Variable',
      'Parameter' => 'Parameter',
      'Protocol' => 'Protocol',
      'Static Method' => 'Method',
      'Static Variable' => 'Variable',
      'Struct' => 'Struct',
      'Subscript' => 'Operator',
      'Typealias' => 'Type',
    }.freeze

    def dash_type
      DASH_TYPES[kindName] || kindName
    end
  end
end
