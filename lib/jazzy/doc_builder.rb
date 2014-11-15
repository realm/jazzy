require 'fileutils'
require 'mustache'
require 'uri'
require 'pathname'
require 'sass'

require 'jazzy/config'
require 'jazzy/doc'
require 'jazzy/jazzy_markdown'
require 'jazzy/source_declaration'
require 'jazzy/source_module'
require 'jazzy/sourcekitten'

module Jazzy
  # This module handles HTML generation, file writing, asset copying,
  # and generally building docs given sourcekitten output
  module DocBuilder
    # mkdir -p output directory and clean if option is set
    def self.prepare_output_dir(output_dir, clean)
      FileUtils.rm_r output_dir if clean && output_dir.directory?
      FileUtils.mkdir_p output_dir
    end

    # Generate doc structure to be used in sidebar navigation
    # @return [Array] doc structure comprised of
    #                     section names & child names & URLs
    def self.doc_structure_for_docs(docs)
      structure = []
      docs.each do |doc|
        structure << {
          section: doc.name,
          children: doc.children.map do |child|
            { name: child.name, url: child.url }
          end,
        }
      end
      structure
    end

    # Build documentation from the given options
    # @param [Config] options
    def self.build(options)
      if options.sourcekitten_sourcefile
        file_contents = options.sourcekitten_sourcefile.read
        build_docs_for_sourcekitten_output(file_contents, options)
      else
        stdout = SourceKitten.run_sourcekitten(options.xcodebuild_arguments)
        exitstatus = $?.exitstatus
        if exitstatus == 0
          warn 'building site'
          build_docs_for_sourcekitten_output(stdout, options)
        else
          warn 'Please pass in xcodebuild arguments using -x'
          warn 'If build arguments are correct, please file an issue on ' \
          'https://github.com/realm/jazzy/issues'
          exit exitstatus || 1
        end
      end
    end

    # Build & write HTML docs to disk from structured docs array
    # @param [String] output_dir Root directory to write docs
    # @param [Array] docs Array of structured docs
    # @param [Config] options Build options
    # @param [Integer] depth Number of parents. Used to calculate path_to_root
    #        for web.
    # @param [Array] doc_structure @see #doc_structure_for_docs
    def self.build_docs(output_dir, docs, source_module, depth)
      docs.each do |doc|
        next if doc.name != 'index' && doc.children.count == 0
        prepare_output_dir(output_dir, false)
        path = output_dir + "#{doc.name}.html"
        path_to_root = ['../'].cycle(depth).to_a.join('')
        path.open('w') do |file|
          file.write(document(source_module, doc, path_to_root))
        end
        next if doc.name == 'index'
        build_docs(
          output_dir + doc.name,
          doc.children,
          source_module,
          depth + 1,
        )
      end
    end

    # Build docs given sourcekitten output
    # @param [String] sourcekitten_output Output of sourcekitten command
    # @param [Config] options Build options
    def self.build_docs_for_sourcekitten_output(sourcekitten_output, options)
      output_dir = options.output
      prepare_output_dir(output_dir, options.clean)

      (docs, coverage) = SourceKitten.parse(sourcekitten_output)

      structure = doc_structure_for_docs(docs)

      docs << SourceDeclaration.new.tap { |sd| sd.name = 'index' }

      source_module = SourceModule.new(options, docs, structure, coverage)
      build_docs(output_dir, source_module.docs, source_module, 0)

      copy_assets(output_dir)

      puts "jam out ♪♫ to your fresh new docs in `#{output_dir}`"
    end

    def self.copy_assets(destination)
      origin = Pathname(__FILE__).parent + '../../lib/jazzy/assets/.'
      FileUtils.cp_r(origin, destination)
      Pathname.glob(destination + 'css/**/*.scss').each do |scss|
        contents = scss.read
        css = Sass::Engine.new(contents, syntax: :scss).render
        css_filename = scss.sub(/\.scss$/, '')
        css_filename.open('w') { |f| f.write(css) }
        FileUtils.rm scss
      end
    end

    # Build index Mustache document
    # @param [Config] options Build options
    # @param [String] path_to_root
    # @param [Array] doc_structure doc structure comprised of section names and
    #        child names and URLs. @see doc_structure_for_docs
    def self.document_index(source_module, path_to_root)
      doc = Doc.new # Mustache model instance
      doc[:name] = source_module.name
      doc[:overview] = Jazzy.markdown.render(
        "This is the index page for #{source_module.name} docs. " \
        'Navigate using the links on the left.',
      )
      doc[:doc_coverage] = source_module.doc_coverage
      doc[:structure] = source_module.doc_structure
      doc[:module_name] = source_module.name
      doc[:author_name] = source_module.author_name
      doc[:author_website] = source_module.author_url
      doc[:github_url] = source_module.github_url
      doc[:dash_url] = source_module.dash_url
      doc[:path_to_root] = path_to_root
      doc.render
    end

    # Construct Github token URL
    # @param [Hash] item Parsed doc child item
    # @param [Config] options Build options
    def self.gh_token_url(item, source_module)
      if source_module.github_file_prefix && item.file
        gh_prefix = source_module.github_file_prefix
        relative_file_path = item.file.gsub(`pwd`.strip, '')
        gh_line = "#L#{item.line}"
        gh_prefix + relative_file_path + gh_line
      end
    end

    # Build mustache item for a top-level doc
    # @param [Hash] item Parsed doc child item
    # @param [Config] options Build options
    def self.render_item(item, source_module)
      # Combine abstract and discussion into abstract
      abstract = (item.abstract || '') + (item.discussion || '')
      item_render = {
        name: item.name,
        abstract: Jazzy.markdown.render(abstract),
        declaration: item.declaration,
        usr: item.usr,
      }
      gh_token_url = gh_token_url(item, source_module)
      item_render[:github_token_url] = gh_token_url
      item_render[:return] = Jazzy.markdown.render(item.return) if item.return
      item_render[:parameters] = item.parameters if item.parameters.length > 0
      item_render[:url] = item.url if item.children.count > 0
      item_render.reject { |_, v| v.nil? } # remove nil values
    end

    # Render tasks for Mustache document
    # @param [Config] options Build options
    # @param [Hash] doc_model Parsed doc. @see SourceKitten.parse
    def self.render_tasks(source_module, doc_model)
      tasks = []
      # @todo parse mark-style comments and use as task names
      tasknames = ['Children']
      tasknames.each do |taskname|
        items = []
        doc_model.children.each do |item|
          items << render_item(item, source_module)
        end
        tasks << {
          name: '',
          uid: URI.encode(taskname),
          items: items,
        }
      end
      tasks
    end

    # Build Mustache document from single parsed doc
    # @param [Config] options Build options
    # @param [Hash] doc_model Parsed doc. @see SourceKitten.parse
    # @param [String] path_to_root
    # @param [Array] doc_structure doc structure comprised of section names and
    #        child names and URLs. @see doc_structure_for_docs
    def self.document(source_module, doc_model, path_to_root)
      # @todo render README here
      if doc_model.name == 'index'
        return document_index(source_module, path_to_root)
      end

      doc = Doc.new # Mustache model instance
      doc[:doc_coverage] = source_module.doc_coverage
      doc[:name] = doc_model.name
      doc[:kind] = doc_model.kindName
      doc[:overview] = Jazzy.markdown.render(doc_model.abstract || '')
      doc[:structure] = source_module.doc_structure
      doc[:tasks] = render_tasks(source_module, doc_model)
      doc[:module_name] = source_module.name
      doc[:author_name] = source_module.author_name
      doc[:author_website] = source_module.author_url
      doc[:github_url] = source_module.github_url
      doc[:dash_url] = source_module.dash_url
      doc[:path_to_root] = path_to_root
      doc.render
    end
  end
end
