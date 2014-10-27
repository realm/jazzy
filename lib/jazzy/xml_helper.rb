require 'nokogiri'

module Jazzy
  module XMLHelper
    # Gets value of XML attribute or nil (i.e. file in <Class file="Musician.swift"></Class>)
    def self.attribute(node, name)
      node.attributes[name].value if node.attributes[name]
    end

    # Gets text in XML node or nil (i.e. s:cMyUSR <USR>s:cMyUSR</USR>)
    def self.xpath(node, xpath)
      node.xpath(xpath).text if node.xpath(xpath).text.length > 0
    end
  end
end
