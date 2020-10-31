require 'fileutils'
require 'mustache'
require 'pathname'
require 'sassc'

require 'jazzy/config'
require 'jazzy/doc'
require 'jazzy/docset_builder'
require 'jazzy/documentation_generator'
require 'jazzy/search_builder'
require 'jazzy/jazzy_markdown'
require 'jazzy/podspec_documenter'
require 'jazzy/source_declaration'
require 'jazzy/source_document'
require 'jazzy/source_module'
require 'jazzy/sourcekitten'
require 'jazzy/symbol_graph'

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
      docs
        .map do |doc|
          children = children_for_doc(doc)
          {
            section: doc.name,
            url: doc.url,
            children: children,
          }
        end
        .select do |structure|
          if Config.instance.hide_unlisted_documentation
            unlisted_prefix = Config.instance.custom_categories_unlisted_prefix
            structure[:section] != "#{unlisted_prefix}Guides"
          else
            true
          end
        end
    end

    def self.children_for_doc(doc)
      doc.children
         .sort_by { |c| [c.nav_order, c.name, c.usr || ''] }
         .flat_map do |child|
        # FIXME: include arbitrarily nested extensible types
        [{ name: child.name, url: child.url }] +
          Array(child.children.select do |sub_child|
            sub_child.type.swift_extensible? || sub_child.type.extension?
          end).map do |sub_child|
            { name: "– #{sub_child.name}", url: sub_child.url }
          end
      end
    end

    # Build documentation from the given options
    # @param [Config] options
    # @return [SourceModule] the documented source module
    def self.build(options)
      if options.sourcekitten_sourcefile_configured
        stdout = '[' + options.sourcekitten_sourcefile.map(&:read)
                              .join(',') + ']'
      elsif options.podspec_configured
        pod_documenter = PodspecDocumenter.new(options.podspec)
        stdout = pod_documenter.sourcekitten_output(options)
      elsif options.swift_build_tool == :symbolgraph
        stdout = SymbolGraph.build(options)
      else
        stdout = Dir.chdir(options.source_directory) do
          arguments = SourceKitten.arguments_from_options(options)
          SourceKitten.run_sourcekitten(arguments)
        end
      end

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
        next unless doc.render_as_page?
        # Filepath is relative to documentation root:
        path = output_dir + doc.filepath
        block.call(doc, path)
        each_doc(
          output_dir,
          doc.children,
          &block
        )
      end
    end

    def self.build_site(docs, coverage, options)
      warn 'building site'

      structure = doc_structure_for_docs(docs)

      docs << SourceDocument.make_index(options.readme_path)

      source_module = SourceModule.new(options, docs, structure, coverage)

      output_dir = options.output
      build_docs(output_dir, source_module.docs, source_module)

      unless options.disable_search
        warn 'building search index'
        SearchBuilder.build(source_module, output_dir)
      end

      copy_assets(output_dir)
      copy_extensions(output_dir)

      DocsetBuilder.new(output_dir, source_module).build!

      generate_badge(source_module.doc_coverage, options)

      friendly_path = relative_path_if_inside(output_dir, Pathname.pwd)
      puts "jam out ♪♫ to your fresh new docs in `#{friendly_path}`"

      source_module
    end

    # Build docs given sourcekitten output
    # @param [String] sourcekitten_output Output of sourcekitten command
    # @param [Config] options Build options
    # @return [SourceModule] the documented source module
    def self.build_docs_for_sourcekitten_output(sourcekitten_output, options)
      (docs, stats) = SourceKitten.parse(
        sourcekitten_output,
        options.min_acl,
        options.skip_undocumented,
        DocumentationGenerator.source_docs,
      )

      prepare_output_dir(options.output, options.clean)

      stats.report

      unless options.skip_documentation
        build_site(docs, stats.doc_coverage, options)
      end

      write_lint_report(stats.undocumented_decls, options)
    end

    def self.relative_path_if_inside(path, base_path)
      relative = path.relative_path_from(base_path)
      if relative.to_path =~ %r{/^..(\/|$)/}
        path
      else
        relative
      end
    end

    def self.undocumented_warnings(decls)
      decls.map do |decl|
        {
          file: decl.file,
          line: decl.line || decl.start_line,
          symbol: decl.fully_qualified_name,
          symbol_kind: decl.type.kind,
          warning: 'undocumented',
        }
      end
    end

    def self.write_lint_report(undocumented, options)
      (options.output + 'undocumented.json').open('w') do |f|
        warnings = undocumented_warnings(undocumented)

        lint_report = {
          warnings: warnings.sort_by do |w|
            [w[:file], w[:line] || 0, w[:symbol], w[:symbol_kind]]
          end,
          source_directory: options.source_directory,
        }
        f.write(JSON.pretty_generate(lint_report))
      end
    end

    def self.copy_assets(destination)
      assets_directory = Config.instance.theme_directory + 'assets'
      FileUtils.cp_r(assets_directory.children, destination)
      Pathname.glob(destination + 'css/**/*.scss').each do |scss|
        css = SassC::Engine.new(scss.read).render
        css_filename = scss.sub(/\.scss$/, '')
        css_filename.open('w') { |f| f.write(css) }
        FileUtils.rm scss
      end
    end

    def self.copy_extensions(destination)
      copy_extension('katex', destination) if Markdown.has_math
    end

    def self.copy_extension(name, destination)
      ext_directory = Pathname(__FILE__).parent + 'extensions/' + name
      FileUtils.cp_r(ext_directory.children, destination)
    end

    def self.render(doc_model, markdown)
      html = Markdown.render(markdown)
      SourceKitten.autolink_document(html, doc_model)
    end

    # Build Mustache document from a markdown source file
    # @param [Config] options Build options
    # @param [Hash] doc_model Parsed doc. @see SourceKitten.parse
    # @param [String] path_to_root
    # @param [Array] doc_structure doc structure comprised of section names and
    #        child names and URLs. @see doc_structure_for_docs
    def self.document_markdown(source_module, doc_model, path_to_root)
      doc = Doc.new # Mustache model instance
      name = doc_model.name == 'index' ? source_module.name : doc_model.name
      doc[:name] = name
      doc[:overview] = render(doc_model, doc_model.content(source_module))
      doc[:custom_head] = Config.instance.custom_head
      doc[:disable_search] = Config.instance.disable_search
      doc[:doc_coverage] = source_module.doc_coverage unless
        Config.instance.hide_documentation_coverage
      doc[:structure] = source_module.doc_structure
      doc[:module_name] = source_module.name
      doc[:author_name] = source_module.author_name
      doc[:github_url] = source_module.github_url
      doc[:dash_url] = source_module.dash_url
      doc[:path_to_root] = path_to_root
      doc[:hide_name] = true
      doc.render.gsub(ELIDED_AUTOLINK_TOKEN, path_to_root)
    end

    # Returns the appropriate color for the provided percentage,
    # used for generating a badge on shields.io
    # @param [Number] coverage The documentation coverage percentage
    def self.color_for_coverage(coverage)
      if coverage < 10
        'e05d44' # red
      elsif coverage < 30
        'fe7d37' # orange
      elsif coverage < 60
        'dfb317' # yellow
      elsif coverage < 85
        'a4a61d' # yellowgreen
      elsif coverage < 90
        '97CA00' # green
      else
        '4c1' # brightgreen
      end
    end

    # rubocop:disable Metrics/MethodLength

    # Generates an SVG similar to those from shields.io displaying the
    # documentation percentage
    # @param [Number] coverage The documentation coverage percentage
    # @param [Config] options Build options
    def self.generate_badge(coverage, options)
      return if options.hide_documentation_coverage

      coverage_length = coverage.to_s.size.succ
      percent_string_length = coverage_length * 80 + 10
      percent_string_offset = coverage_length * 40 + 975
      width = coverage_length * 8 + 104
      svg = <<-SVG.gsub(/^ {8}/, '')
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{width}" height="20">
          <linearGradient id="b" x2="0" y2="100%">
            <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
            <stop offset="1" stop-opacity=".1"/>
          </linearGradient>
          <clipPath id="a">
            <rect width="#{width}" height="20" rx="3" fill="#fff"/>
          </clipPath>
          <g clip-path="url(#a)">
            <path fill="#555" d="M0 0h93v20H0z"/>
            <path fill="##{color_for_coverage(coverage)}" d="M93 0h#{percent_string_length / 10 + 10}v20H93z"/>
            <path fill="url(#b)" d="M0 0h#{width}v20H0z"/>
          </g>
          <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="110">
            <text x="475" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="830">
              documentation
            </text>
            <text x="475" y="140" transform="scale(.1)" textLength="830">
              documentation
            </text>
            <text x="#{percent_string_offset}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="#{percent_string_length}">
              #{coverage}%
            </text>
            <text x="#{percent_string_offset}" y="140" transform="scale(.1)" textLength="#{percent_string_length}">
              #{coverage}%
            </text>
          </g>
        </svg>
      SVG

      badge_output = options.output + 'badge.svg'
      File.open(badge_output, 'w') { |f| f << svg }
    end
    # rubocop:enable Metrics/MethodLength

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
      gh_line = if item.start_line && (item.start_line != item.end_line)
                  "#L#{item.start_line}-L#{item.end_line}"
                else
                  "#L#{item.line}"
                end
      relative_file_path = item.file.realpath.relative_path_from(
        source_module.root_path,
      )
      "#{github_prefix}/#{relative_file_path}#{gh_line}"
    end

    # Build mustache item for a top-level doc
    # @param [Hash] item Parsed doc child item
    # @param [Config] options Build options
    # rubocop:disable Metrics/MethodLength
    def self.render_item(item, source_module)
      # Combine abstract and discussion into abstract
      abstract = (item.abstract || '') + (item.discussion || '')
      {
        name:                       item.name,
        name_html:                  item.name.gsub(':', ':<wbr>'),
        abstract:                   abstract,
        declaration:                item.display_declaration,
        language:                   item.display_language,
        other_language_declaration: item.display_other_language_declaration,
        usr:                        item.usr,
        dash_type:                  item.type.dash_type,
        github_token_url:           gh_token_url(item, source_module),
        default_impl_abstract:      item.default_impl_abstract,
        from_protocol_extension:    item.from_protocol_extension,
        return:                     item.return,
        parameters:                 (item.parameters if item.parameters.any?),
        url:                        (item.url if item.render_as_page?),
        start_line:                 item.start_line,
        end_line:                   item.end_line,
        direct_link:                item.omit_content_from_parent?,
        deprecation_message:        item.deprecation_message,
        unavailable_message:        item.unavailable_message,
        usage_discouraged:          item.usage_discouraged?,
      }
    end
    # rubocop:enable Metrics/MethodLength

    def self.make_task(mark, uid, items, doc_model)
      {
        name: mark.name,
        name_html: (render(doc_model, mark.name) if mark.name),
        uid: ERB::Util.url_encode(uid),
        items: items,
        pre_separator: mark.has_start_dash,
        post_separator: mark.has_end_dash,
      }
    end

    # Render tasks for Mustache document
    # @param [Config] options Build options
    # @param [Hash] doc_model Parsed doc. @see SourceKitten.parse
    def self.render_tasks(source_module, children)
      marks = children.map(&:mark).uniq.compact
      mark_names_counts = {}
      marks.map do |mark|
        mark_children = children.select { |child| child.mark == mark }
        items = mark_children.map { |child| render_item(child, source_module) }
        uid = (mark.name || 'Unnamed').to_s
        if mark_names_counts.key?(uid)
          mark_names_counts[uid] += 1
          uid += (mark_names_counts[uid]).to_s
        else
          mark_names_counts[uid] = 1
        end
        make_task(mark, uid, items, mark_children.first)
      end
    end

    # rubocop:disable Metrics/MethodLength
    # Build Mustache document from single parsed doc
    # @param [Config] options Build options
    # @param [Hash] doc_model Parsed doc. @see SourceKitten.parse
    # @param [String] path_to_root
    # @param [Array] doc_structure doc structure comprised of section names and
    #        child names and URLs. @see doc_structure_for_docs
    def self.document(source_module, doc_model, path_to_root)
      if doc_model.type.markdown?
        return document_markdown(source_module, doc_model, path_to_root)
      end

      overview = (doc_model.abstract || '') + (doc_model.discussion || '')
      alternative_abstract = doc_model.alternative_abstract
      if alternative_abstract
        overview = render(doc_model, alternative_abstract) + overview
      end

      doc = Doc.new # Mustache model instance
      doc[:custom_head] = Config.instance.custom_head
      doc[:disable_search] = Config.instance.disable_search
      doc[:doc_coverage] = source_module.doc_coverage unless
        Config.instance.hide_documentation_coverage
      doc[:name] = doc_model.name
      doc[:kind] = doc_model.type.name
      doc[:dash_type] = doc_model.type.dash_type
      doc[:declaration] = doc_model.display_declaration
      doc[:language] = doc_model.display_language
      doc[:other_language_declaration] =
        doc_model.display_other_language_declaration
      doc[:overview] = overview
      doc[:parameters] = doc_model.parameters
      doc[:return] = doc_model.return
      doc[:structure] = source_module.doc_structure
      doc[:tasks] = render_tasks(source_module, doc_model.children)
      doc[:module_name] = source_module.name
      doc[:author_name] = source_module.author_name
      doc[:github_url] = source_module.github_url
      doc[:github_token_url] = gh_token_url(doc_model, source_module)
      doc[:dash_url] = source_module.dash_url
      doc[:path_to_root] = path_to_root
      doc[:deprecation_message] = doc_model.deprecation_message
      doc[:unavailable_message] = doc_model.unavailable_message
      doc[:usage_discouraged] = doc_model.usage_discouraged?
      doc.render.gsub(ELIDED_AUTOLINK_TOKEN, path_to_root)
    end
    # rubocop:enable Metrics/MethodLength
  end
end
