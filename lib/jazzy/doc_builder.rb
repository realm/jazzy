require 'fileutils'
require 'mustache'
require 'uri'

require 'jazzy/config'
require 'jazzy/doc'
require 'jazzy/jazzy_markdown'
require 'jazzy/source_declaration'
require 'jazzy/sourcekitten'

module Jazzy
  # This module handles HTML generation, file writing, asset copying,
  # and generally building docs given sourcekitten output
  module DocBuilder
    # mkdir -p output directory and clean if option is set
    def self.prepare_output_dir(output_dir, clean)
      FileUtils.rm_r output_dir if clean && File.directory?(output_dir)
      FileUtils.mkdir_p output_dir
    end

    # Generate doc structure to be used in sidebar navigation
    # @return [Array] doc structure comprised of section names and child names and URLs
    def self.doc_structure_for_docs(docs)
      structure = []
      docs.each do |doc|
        structure << {
          section: doc.name,
          children: doc.children.map { |child| { name: child.name, url: child.url } },
        }
      end
      structure
    end

    # Build documentation from the given options
    # @param [Config] options
    def self.build(options)
      if options.sourcekitten_sourcefile
        file = File.open(options.sourcekitten_sourcefile)
        file_contents = file.read
        file.close
        build_docs_for_sourcekitten_output(file_contents, options)
      else
        stdout, stderr, status = SourceKitten.run_sourcekitten(options.xcodebuild_arguments)
        if status.exitstatus == 0 || status.exitstatus.nil?
          build_docs_for_sourcekitten_output(stdout, options)
        else
          warn stderr
          warn 'Please pass in xcodebuild arguments using -x'
          exit status.exitstatus
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
    def self.build_docs(output_dir, docs, options, depth, doc_structure)
      docs.each do |doc|
        next if doc.name != 'index' && doc.children.count == 0
        prepare_output_dir(output_dir, false)
        path = File.join(output_dir, "#{doc.name}.html")
        path_to_root = ['../'].cycle(depth).to_a.join('')
        File.open(path, 'w') { |file| file.write(DocBuilder.document(options, doc, path_to_root, doc_structure)) }
        if doc.name != 'index'
          DocBuilder.build_docs(File.join(output_dir, doc.name), doc.children, options, depth + 1, doc_structure)
        end
      end
    end

    # Build docs given sourcekitten output
    # @param [String] sourcekitten_output Output of sourcekitten command
    # @param [Config] options Build options
    def self.build_docs_for_sourcekitten_output(sourcekitten_output, options)
      output_dir = options.output
      prepare_output_dir(output_dir, options.clean)
      docs = SourceKitten.parse(sourcekitten_output)
      doc_structure = doc_structure_for_docs(docs)
      docs << SourceDeclaration.new.tap { |sd| sd.name = 'index' }
      DocBuilder.build_docs(output_dir, docs, options, 0, doc_structure)

      # Copy assets into output directory
      assets_dir = File.expand_path(File.dirname(__FILE__) + '/../../lib/jazzy/assets/') + '/.'
      FileUtils.cp_r(assets_dir, output_dir)

      puts 'jam out ♪♫ to your fresh new docs at ' + output_dir
    end

    # Build Mustache document from single parsed doc
    # @param [Config] options Build options
    # @param [Hash] doc_model Parsed doc. @see SourceKitten.parse
    # @param [String] path_to_root
    # @param [Array] doc_structure doc structure comprised of section names and
    #        child names and URLs. @see doc_structure_for_docs
    def self.document(options, doc_model, path_to_root, doc_structure)
      doc = Doc.new # Mustache model instance
      # Do something special for index.
      # @todo render README here
      if doc_model.name == 'index'
        doc[:name] = options.module_name
        doc[:overview] = Jazzy.markdown.render(
          "This is the index page for #{options.module_name} docs. " \
          'Navigate using the links on the left.',
        )
        doc[:structure] = doc_structure
        doc[:module_name] = options.module_name
        doc[:author_name] = options.author_name
        doc[:author_website] = options.author_url
        doc[:github_url] = options.github_url
        doc[:dash_url] = options.dash_url
        doc[:path_to_root] = path_to_root
        return doc.render
      end

      ########################################################
      # Map doc_model values to mustache model values
      ########################################################

      doc[:name] = doc_model.name
      doc[:kind] = doc_model.kindName
      doc[:overview] = Jazzy.markdown.render(doc_model.abstract)
      doc[:tasks] = []
      doc[:structure] = doc_structure
      # @todo parse mark-style comments and use as task names
      tasknames = ['Children']
      tasknames.each do |taskname|
        items = []
        doc_model.children.each do |sub_item|
          # Combine abstract and discussion into abstract
          abstract = (sub_item.abstract || '') + (sub_item.discussion || '')
          item = {
            name: sub_item.name,
            abstract: Jazzy.markdown.render(abstract),
            declaration: sub_item.declaration,
            usr: sub_item.usr,
          }
          if options.github_file_prefix && sub_item.file
            gh_prefix = options.github_file_prefix
            relative_file_path = sub_item.file.gsub(`pwd`.strip, '')
            gh_line = "#L#{sub_item.line}"
            item[:github_token_url] = gh_prefix + relative_file_path + gh_line
          end
          item[:return] = Jazzy.markdown.render(sub_item.return) if sub_item.return
          parameters = sub_item.parameters
          item[:parameters] = parameters if parameters.length > 0
          items << item
        end
        doc[:tasks] << {
          name: '',
          uid: URI.encode(taskname),
          items: items,
        }
      end
      doc[:module_name] = options.module_name
      doc[:author_name] = options.author_name
      doc[:author_website] = options.author_url
      doc[:github_url] = options.github_url
      doc[:dash_url] = options.dash_url
      doc[:path_to_root] = path_to_root
      doc.render
    end
  end
end
