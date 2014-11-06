require 'rest'
require 'jazzy/jazzy_markdown'

module Jazzy
  module ReadmeGenerator
    def self.generate(config)
      readme = config.readme_path || readme_path

      unless readme && File.exist?(readme) && readme = File.read(readme)
        readme = generated_readme(config)
      end

      rendered_readme = github_readme(readme) || Jazzy.markdown(readme)
      "<div class='readme'>#{rendered_readme}</div>"
    end

    def self.github_readme(readme)
      response = REST.post(
        'https://api.github.com/markdown/raw',
        readme,
        'Content-Type' => 'text/x-markdown',
      )
      response.body.force_encoding('utf-8') if response.success?
    end

    def self.readme_path
      ['README.md', 'README.markdown', 'README.mdown', 'README'].each do |potential_name|
        if File.exist? potential_name
          return potential_name
        end
      end
      nil
    end

    def self.generated_readme(config)
      %(
# #{ config.module_name }

### Authors

#{ config.author_name }
      )
    end
  end
end
