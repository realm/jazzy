require 'pathname'

require 'jazzy/jazzy_markdown'

module Jazzy
  class SourceDocument < SourceDeclaration
    attr_accessor :overview
    attr_accessor :readme_path

    def self.make_index(readme_path)
      SourceDocument.new.tap do |sd|
        sd.name = 'index'
        sd.children = []
        sd.type = SourceDeclaration::Type.new 'document.markdown'
        sd.readme_path = readme_path
      end
    end

    def config
      Config.instance
    end

    def url
      name.downcase.strip.tr(' ', '-').gsub(/[^\w-]/, '') + '.html'
    end

    def content(source_module)
      return readme_content(source_module) if name == 'index'
      overview
    end

    def readme_content(source_module)
      config_readme || fallback_readme || generated_readme(source_module)
    end

    def config_readme
      readme_path.read if readme_path && readme_path.exist?
    end

    def fallback_readme
      %w[README.md README.markdown README.mdown README].each do |potential_name|
        file = config.source_directory + potential_name
        return file.read if file.exist?
      end
      false
    end

    def generated_readme(source_module)
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
