require 'fileutils'
require 'mustache'
require 'uri'
require 'pathname'
require 'sass'

require 'jazzy/config'
require 'jazzy/doc'
require 'jazzy/docset_builder'
require 'jazzy/jazzy_markdown'
require 'jazzy/podspec_documenter'
require 'jazzy/readme_generator'
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
      docs.map do |doc|
        {
          section: doc.name,
          children: doc.children
              .sort_by(&:name)
              .sort_by(&:nav_order)
              .map do |child|
                { name: child.name, url: child.url }
              end,
        }
      end
    end

    # Build documentation from the given options
    # @param [Config] options
    # @return [SourceModule] the documented source module
    def self.build(options)
      if options.sourcekitten_sourcefile
        stdout = options.sourcekitten_sourcefile.read
      else
        if podspec = options.podspec
          stdout = PodspecDocumenter.new(podspec).sourcekitten_output
        else
          stdout = Dir.chdir(Config.instance.source_directory) do
            arguments = ['doc'] + options.xcodebuild_arguments
            SourceKitten.run_sourcekitten(arguments)
          end
        end
        unless $?.success?
          warn 'Please pass in xcodebuild arguments using -x'
          warn 'If build arguments are correct, please file an issue on ' \
            'https://github.com/realm/jazzy/issues'
          exit $?.exitstatus || 1
        end
      end
      warn 'building site'
      build_docs_for_sourcekitten_output(stdout, options)
    end

    # Build & write HTML docs to disk from structured docs array
    # @param [String] output_dir Root directory to write docs
    # @param [Array] docs Array of structured docs
    # @param [Config] options Build options
    # @param [Array] doc_structure @see #doc_structure_for_docs
    def self.build_docs(output_dir, docs, source_module)
      each_doc(output_dir, docs) do |doc, path|
        prepare_output_dir(path.parent, false)
        depth = path.relative_path_from(output_dir).each_filename.count - 1
        path_to_root = '../' * depth
        path.open('w') do |file|
          file.write(document(source_module, doc, path_to_root))
        end
      end
    end

    def self.each_doc(output_dir, docs, &block)
      docs.each do |doc|
        next if doc.name != 'index' && doc.children.count == 0
        # Assuming URL is relative to documentation root:
        path = output_dir + (doc.url || "#{doc.name}.html")
        block.call(doc, path)
        next if doc.name == 'index'
        each_doc(
          output_dir,
          doc.children,
          &block
        )
      end
    end

    # Build docs given sourcekitten output
    # @param [String] sourcekitten_output Output of sourcekitten command
    # @param [Config] options Build options
    # @return [SourceModule] the documented source module
    def self.build_docs_for_sourcekitten_output(sourcekitten_output, options)
      output_dir = options.output
      prepare_output_dir(output_dir, options.clean)

      (docs, coverage, undocumented) = SourceKitten.parse(
        sourcekitten_output,
        options.min_acl,
        options.skip_undocumented,
      )

      structure = doc_structure_for_docs(docs)

      docs << SourceDeclaration.new.tap do |sd|
        sd.name = 'index'
        sd.children = []
      end

      source_module = SourceModule.new(options, docs, structure, coverage)
      build_docs(output_dir, source_module.docs, source_module)

      write_undocumented_file(undocumented, output_dir)

      copy_assets(output_dir)

      DocsetBuilder.new(output_dir, source_module).build!

      puts "jam out ♪♫ to your fresh new docs in `#{output_dir}`"

      source_module
    end

    def self.decl_for_token(token)
      if token['key.parsed_declaration']
        token['key.parsed_declaration']
      elsif token['key.annotated_decl']
        token['key.annotated_decl'].gsub(/<[^>]+>/, '')
      elsif token['key.name']
        token['key.name']
      else
        'unknown declaration'
      end
    end

    def self.write_undocumented_file(undocumented, output_dir)
      (output_dir + 'undocumented.txt').open('w') do |f|
        tokens_by_file = undocumented.group_by do |d|
          if d['key.filepath']
            Pathname.new(d['key.filepath']).basename.to_s
          else
            d['key.modulename'] || ''
          end
        end
        tokens_by_file.each_key do |file|
          f.write(file + "\n")
          tokens_by_file[file].each do |token|
            f.write("\t" + decl_for_token(token) + "\n")
          end
        end
      end
    end

    def self.copy_assets(destination)
      FileUtils.cp_r(Config.instance.assets_directory.children, destination)
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
      doc[:overview] = ReadmeGenerator.generate(source_module)
      doc[:doc_coverage] = source_module.doc_coverage
      doc[:structure] = source_module.doc_structure
      doc[:module_name] = source_module.name
      doc[:author_name] = source_module.author_name
      doc[:github_url] = source_module.github_url.to_s
      doc[:dash_url] = source_module.dash_url
      doc[:path_to_root] = path_to_root
      doc[:hide_name] = true
      doc.render
    end

    def self.should_link_to_github(file)
      return unless file
      file = file.realpath.to_path
      source_directory = Config.instance.source_directory.to_path
      file.start_with?(source_directory)
    end

    # Construct Github token URL
    # @param [Hash] item Parsed doc child item
    # @param [Config] options Build options
    def self.gh_token_url(item, source_module)
      return unless github_prefix = source_module.github_file_prefix
      return unless should_link_to_github(item.file)
      if item.start_line && (item.start_line != item.end_line)
        gh_line = "#L#{item.start_line}-L#{item.end_line}"
      else
        gh_line = "#L#{item.line}"
      end
      relative_file_path = item.file.realpath.relative_path_from(Pathname.pwd)
      "#{github_prefix}/#{relative_file_path}#{gh_line}"
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
        dash_type: item.type.dash_type,
      }
      gh_token_url = gh_token_url(item, source_module)
      item_render[:github_token_url] = gh_token_url
      item_render[:return] = Jazzy.markdown.render(item.return) if item.return
      item_render[:parameters] = item.parameters if item.parameters.any?
      item_render[:url] = item.url if item.children.any?
      item_render[:start_line] = item.start_line
      item_render[:end_line] = item.end_line
      item_render.reject { |_, v| v.nil? }
    end

    def self.make_task(mark, uid, items)
      {
        name: mark.name,
        uid: URI.encode(uid),
        items: items,
        pre_separator: mark.has_start_dash,
        post_separator: mark.has_end_dash,
      }
    end

    # Render tasks for Mustache document
    # @param [Config] options Build options
    # @param [Hash] doc_model Parsed doc. @see SourceKitten.parse
    def self.render_tasks(source_module, children)
      marks = children.map(&:mark).uniq
      mark_names_counts = {}
      marks.map do |mark|
        mark_children = children.select { |child| child.mark == mark }
        items = mark_children.map { |child| render_item(child, source_module) }
        uid = "#{mark.name || 'Unnamed'}"
        if mark_names_counts.key?(uid)
          mark_names_counts[uid] += 1
          uid += "#{mark_names_counts[uid]}"
        else
          mark_names_counts[uid] = 1
        end
        make_task(mark, uid, items)
      end
    end

    # Build Mustache document from single parsed doc
    # @param [Config] options Build options
    # @param [Hash] doc_model Parsed doc. @see SourceKitten.parse
    # @param [String] path_to_root
    # @param [Array] doc_structure doc structure comprised of section names and
    #        child names and URLs. @see doc_structure_for_docs
    def self.document(source_module, doc_model, path_to_root)
      if doc_model.name == 'index'
        return document_index(source_module, path_to_root)
      end

      doc = Doc.new # Mustache model instance
      doc[:doc_coverage] = source_module.doc_coverage
      doc[:name] = doc_model.name
      doc[:kind] = doc_model.type.name
      doc[:dash_type] = doc_model.type.dash_type
      doc[:declaration] = doc_model.declaration
      doc[:overview] = Jazzy.markdown.render(doc_model.overview)
      doc[:structure] = source_module.doc_structure
      doc[:tasks] = render_tasks(source_module, doc_model.children)
      doc[:module_name] = source_module.name
      doc[:author_name] = source_module.author_name
      doc[:github_url] = source_module.github_url.to_s
      doc[:dash_url] = source_module.dash_url
      doc[:path_to_root] = path_to_root
      doc.render
    end
  end
end
