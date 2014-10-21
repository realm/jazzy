require 'mustache'
require 'redcarpet'
require 'nokogiri'
require 'json'
require 'date'
require 'uri'
require "jazzy/gem_version.rb"
require "jazzy/doc.rb"
require "jazzy/jazzy_markdown.rb"

class Jazzy::DocBuilder
  def self.document
    doc = Jazzy::Doc.new
    doc[:name] = "List"
    doc[:kind] = "Class"
    doc[:overview] = $markdown.render("List is a generic class (roughly the Swift equivalent of `RLMArray`).")
    taskname = "Creating a List"
    doc[:tasks] = [
        {
            :name => taskname,
            :uid => URI::encode(taskname),
            :abstract => $markdown.render("This is the abstract for the creator."),
            :declaration => "init(string aString: String)",
            :parameters => [:name => "aString", :description => $markdown.render("The characters for the new object.")],
            :return => $markdown.render("a `List` object initialized with the characters of `aString` and no attribute information.")
        }
    ]
    doc[:module_name] = "RealmSwift"
    doc[:company_name] = "Realm"
    doc[:company_website] = "http://realm.io"
    doc[:github_link] = "https://github.com/realm/realm-cocoa"
    doc[:dash_link] = "http://kapeli.com/dash"
    doc.render
  end
end
