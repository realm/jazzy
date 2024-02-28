# frozen_string_literal: true

require 'pathname'

require 'jazzy/jazzy_markdown'

module Jazzy
  # Standalone markdown docs including index.html
  class SourceDocument < SourceDeclaration
    attr_accessor :overview
    attr_accessor :readme_path

    def initialize
      super
      self.children = []
      self.parameters = []
      self.abstract = ''
      self.type = SourceDeclaration::Type.markdown
      self.mark = SourceMark.new
    end

    def self.make_index(readme_path)
      SourceDocument.new.tap do |sd|
        sd.name = 'index'
        sd.url = sd.name + '.html'
        sd.readme_path = readme_path
      end
    end

    def render_as_page?
      true
    end

    def omit_content_from_parent?
      true
    end

    def config
      Config.instance
    end

    def url_name
      name.downcase.strip.tr(' ', '-').gsub(/[^[[:word:]]-]/, '')
    end

    def content(source_module)
      return readme_content(source_module) if name == 'index'

      overview
    end

    def readme_content(source_module)
      config_readme || fallback_readme || generated_readme(source_module)
    end

    def config_readme
      readme_path.read if readme_path&.exist?
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
        <<-README
# #{podspec.name}

### #{podspec.summary}

#{podspec.description}

### Installation

```ruby
pod '#{podspec.name}'
```

### Authors

#{source_module.author_name}
        README
      else
        <<-README
# #{source_module.readme_title}

### Authors

#{source_module.author_name}
        README
      end
    end
  end
end
