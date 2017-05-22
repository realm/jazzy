require 'pathname'

require 'jazzy/jazzy_markdown'

module Jazzy
  module ReadmeGenerator
    extend Config::Mixin

    def self.generate(source_module)
      readme = readme_path

      unless readme && readme.exist? && readme = readme.read
        readme = generated_readme(source_module)
      end

      Jazzy.markdown.render(readme)
    end

    def self.readme_path
      return config.readme_path if config.readme_path
      %w[README.md README.markdown README.mdown README].each do |potential_name|
        file = config.source_directory + potential_name
        return file if file.exist?
      end
      nil
    end

    def self.generated_readme(source_module)
      if podspec = config.podspec
        ### License

        # <a href="#{license[:url]}">#{license[:license]}</a>
        <<-EOS
# #{podspec.name}

### #{podspec.summary}

#{podspec.description}

### Installation

```ruby
pod '#{podspec.name}'
```

### Authors

#{source_module.author_name}
EOS
      else
        <<-EOS
# #{source_module.name}

### Authors

#{source_module.author_name}
EOS
      end
    end
  end
end
