require 'jazzy/jazzy_markdown'

module Jazzy
  module ReadmeGenerator
    def self.generate(source_module)
      readme = readme_path

      unless readme && File.exist?(readme) && readme = File.read(readme)
        readme = generated_readme(source_module)
      end

      rendered_readme = Jazzy.markdown.render(readme)
      "<div class='readme'>#{rendered_readme}</div>"
    end

    def self.readme_path
      %w(README.md README.markdown README.mdown README).each do |potential_name|
        if File.exist? potential_name
          return potential_name
        end
      end
      nil
    end

    def self.generated_readme(source_module)
      %(
# #{ source_module.name }

### Authors

#{ source_module.author_name }
      )
    end
  end
end
