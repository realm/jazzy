# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Jazzy
  module SymbolGraph
    # A Symbol is a tidied-up SymbolGraph JSON object
    class Symbol
      attr_accessor :usr
      attr_accessor :path_components
      attr_accessor :declaration
      attr_accessor :kind
      attr_accessor :acl
      attr_accessor :spi
      attr_accessor :location # can be nil, keys :filename :line :character
      attr_accessor :constraints # array, can be empty
      attr_accessor :doc_comments # can be nil
      attr_accessor :attributes # array, can be empty
      attr_accessor :generic_type_params # set, can be empty
      attr_accessor :parameter_names # array, can be nil

      def name
        path_components[-1] || '??'
      end

      def full_name
        path_components.join('.')
      end

      def initialize(hash)
        self.usr = hash[:identifier][:precise]
        self.path_components = hash[:pathComponents]
        raw_decl, keywords = parse_decl_fragments(hash[:declarationFragments])
        init_kind(hash[:kind][:identifier], keywords)
        init_declaration(raw_decl)
        if func_signature = hash[:functionSignature]
          init_func_signature(func_signature)
        end
        init_acl(hash[:accessLevel])
        self.spi = hash[:spi]
        if location = hash[:location]
          init_location(location)
        end
        init_constraints(hash, raw_decl)
        if comments_hash = hash[:docComment]
          init_doc_comments(comments_hash)
        end
        init_attributes(hash[:availability] || [])
        init_generic_type_params(hash)
      end

      def parse_decl_fragments(fragments)
        decl = ''
        keywords = Set.new
        fragments.each do |frag|
          decl += frag[:spelling]
          keywords.add(frag[:spelling]) if frag[:kind] == 'keyword'
        end
        [decl, keywords]
      end

      # Repair problems with SymbolGraph's declprinter

      def init_declaration(raw_decl)
        # Too much 'Self.TypeName'; omitted arg labels look odd;
        # duplicated constraints; swift 5.3 vs. master workaround
        self.declaration = raw_decl
          .gsub(/\bSelf\./, '')
          .gsub(/(?<=\(|, )_: /, '_ arg: ')
          .gsub(/ where.*$/, '')
        if kind == 'source.lang.swift.decl.class'
          declaration.sub!(/\s*:.*$/, '')
        end
      end

      # Remember pieces of methods for later markdown parsing

      def init_func_signature(func_signature)
        self.parameter_names =
          (func_signature[:parameters] || []).map { |h| h[:name] }
      end

      # Mapping SymbolGraph's declkinds to SourceKit

      KIND_MAP = {
        'class' => 'class',
        'struct' => 'struct',
        'enum' => 'enum',
        'enum.case' => 'enumelement', # intentional
        'protocol' => 'protocol',
        'init' => 'function.constructor',
        'deinit' => 'function.destructor',
        'func.op' => 'function.operator',
        'type.method' => 'function.method.class',
        'static.method' => 'function.method.static',
        'method' => 'function.method.instance',
        'func' => 'function.free',
        'type.property' => 'var.class',
        'static.property' => 'var.static',
        'property' => 'var.instance',
        'var' => 'var.global',
        'subscript' => 'function.subscript',
        'type.subscript' => 'function.subscript',
        'static.subscript' => 'function.subscript',
        'typealias' => 'typealias',
        'associatedtype' => 'associatedtype',
        'actor' => 'actor',
        'macro' => 'macro',
        'extension' => 'extension',
      }.freeze

      # We treat 'static var' differently to 'class var'
      # We treat actors as first-class entities
      def adjust_kind_for_declaration(kind, keywords)
        if kind == 'swift.class' && keywords.member?('actor')
          return 'swift.actor'
        end
        return kind unless keywords.member?('static')

        kind.gsub('type', 'static')
      end

      def init_kind(kind, keywords)
        adjusted = adjust_kind_for_declaration(kind, keywords)
        sourcekit_kind = KIND_MAP[adjusted.sub('swift.', '')]
        raise "Unknown symbol kind '#{kind}'" unless sourcekit_kind

        self.kind = "source.lang.swift.decl.#{sourcekit_kind}"
      end

      def extension?
        kind.end_with?('extension')
      end

      # Mapping SymbolGraph's ACL to SourceKit

      def init_acl(acl)
        self.acl = "source.lang.swift.accessibility.#{acl}"
      end

      # Symbol location - only available for public+ decls

      def init_location(loc_hash)
        self.location = {}
        location[:filename] = loc_hash[:uri].sub(%r{^file://}, '')
        location[:line] = loc_hash[:position][:line]
        location[:character] = loc_hash[:position][:character]
      end

      # Generic constraints: in one or both of two places.
      # There can be duplicates; these are removed by `Constraint`.
      def init_constraints(hash, raw_decl)
        raw_constraints = %i[swiftGenerics swiftExtension].flat_map do |key|
          next [] unless container = hash[key]

          container[:constraints] || []
        end

        constraints =
          Constraint.new_list_for_symbol(raw_constraints, path_components)
        if raw_decl =~ / where (.*)$/
          constraints +=
            Constraint.new_list_from_declaration(Regexp.last_match[1])
        end

        self.constraints = constraints.sort.uniq
      end

      # Generic type params
      def init_generic_type_params(hash)
        self.generic_type_params = Set.new(
          if (generics = hash[:swiftGenerics]) &&
             (parameters = generics[:parameters])
            parameters.map { |p| p[:name] }
          else
            []
          end,
        )
      end

      def init_doc_comments(comments_hash)
        self.doc_comments = comments_hash[:lines]
          .map { |l| l[:text] }
          .join("\n")
      end

      # Availability
      # Re-encode this as Swift.  Should really teach Jazzy about these,
      # could maybe then do something smarter here.
      def availability_attributes(avail_hash_list)
        avail_hash_list.map do |avail|
          str = '@available('
          if avail[:isUnconditionallyDeprecated]
            str += '*, deprecated'
          elsif domain = avail[:domain]
            str += domain
            %i[introduced deprecated obsoleted].each do |event|
              if version = avail[event]
                str += ", #{event}: #{decode_version(version)}"
              end
            end
          else
            warn "Found confusing availability: #{avail}"
            next nil
          end

          str += ", message: \"#{avail[:message]}\"" if avail[:message]
          str += ", renamed: \"#{avail[:renamed]}\"" if avail[:renamed]

          str + ')'
        end.compact
      end

      def decode_version(hash)
        str = hash[:major].to_s
        str += ".#{hash[:minor]}" if hash[:minor]
        str += ".#{hash[:patch]}" if hash[:patch]
        str
      end

      def spi_attributes
        spi ? ['@_spi(Unknown)'] : []
      end

      def init_attributes(avail_hash_list)
        self.attributes =
          availability_attributes(avail_hash_list) + spi_attributes
      end

      # SourceKit common fields, shared by extension and regular symbols.
      # Things we do not know for fabricated extensions.
      def add_to_sourcekit(hash)
        unless doc_comments.nil?
          hash['key.doc.comment'] = doc_comments
          hash['key.doc.full_as_xml'] = ''
        end

        hash['key.accessibility'] = acl

        unless location.nil?
          hash['key.filepath'] = location[:filename]
          hash['key.doc.line'] = location[:line] + 1
          hash['key.doc.column'] = location[:character] + 1
        end

        hash
      end

      # Sort order
      include Comparable

      def <=>(other)
        # Things with location: order by file/line/column
        # (pls tell what wheel i am reinventing :/)
        if location && other_loc = other.location
          if location[:filename] == other_loc[:filename]
            if location[:line] == other_loc[:line]
              return location[:character] <=> other_loc[:character]
            end

            return location[:line] <=> other_loc[:line]
          end
          return location[:filename] <=> other_loc[:filename]
        end

        # Things with a location before things without a location
        return +1 if location.nil? && other.location
        return -1 if location && other.location.nil?

        # Things without a location: by name and then USR
        return usr <=> other.usr if name == other.name

        name <=> other.name
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
