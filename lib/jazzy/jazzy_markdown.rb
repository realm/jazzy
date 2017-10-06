require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

module Jazzy
  module Markdown
    class JazzyHTML < Redcarpet::Render::HTML
      include Redcarpet::Render::SmartyPants
      include Rouge::Plugins::Redcarpet

      attr_accessor :default_language

      def header(text, header_level)
        text_slug = text.gsub(/[^\w]+/, '-')
                        .downcase
                        .sub(/^-/, '')
                        .sub(/-$/, '')

        "<h#{header_level} id='#{text_slug}' class='heading'>" \
          "#{text}" \
        "</h#{header_level}>\n"
      end

      # List from
      # https://github.com/apple/swift/blob/master/include/swift/Markup/SimpleFields.def
      UNIQUELY_HANDLED_CALLOUTS = %w[parameters
                                     parameter
                                     returns].freeze
      GENERAL_CALLOUTS = %w[attention
                            author
                            authors
                            bug
                            complexity
                            copyright
                            date
                            experiment
                            important
                            invariant
                            keyword
                            mutatingvariant
                            nonmutatingvariant
                            note
                            postcondition
                            precondition
                            recommended
                            recommendedover
                            remark
                            remarks
                            requires
                            see
                            seealso
                            since
                            todo
                            throws
                            version
                            warning].freeze
      SPECIAL_LIST_TYPES = (UNIQUELY_HANDLED_CALLOUTS + GENERAL_CALLOUTS).freeze

      SPECIAL_LIST_TYPE_REGEX = %r{
        \A\s* # optional leading spaces
        (<p>\s*)? # optional opening p tag
        # any one of our special list types
        (#{SPECIAL_LIST_TYPES.map(&Regexp.method(:escape)).join('|')})
        [\s:] # followed by either a space or a colon
      }ix

      ELIDED_LI_TOKEN =
        '7wNVzLB0OYPL2eGlPKu8q4vITltqh0Y6DPZf659TPMAeYh49o'.freeze

      def list_item(text, _list_type)
        if text =~ SPECIAL_LIST_TYPE_REGEX
          type = Regexp.last_match(2)
          if UNIQUELY_HANDLED_CALLOUTS.include? type.downcase
            return ELIDED_LI_TOKEN
          end
          return render_aside(type, text.sub(/#{Regexp.escape(type)}:\s+/, ''))
        end
        str = '<li>'
        str << text.strip
        str << "</li>\n"
      end

      def render_aside(type, text)
        <<-HTML
<div class="aside aside-#{type.underscore.tr('_', '-')}">
    <p class="aside-title">#{type.underscore.humanize}</p>
    #{text}
</div>
        HTML
      end

      def list(text, list_type)
        elided = text.gsub!(ELIDED_LI_TOKEN, '')
        return if text =~ /\A\s*\Z/ && elided
        return text if text =~ /class="aside-title"/
        str = "\n"
        str << (list_type == :ordered ? "<ol>\n" : "<ul>\n")
        str << text
        str << (list_type == :ordered ? "</ol>\n" : "</ul>\n")
      end

      def block_code(code, language)
        super(code, language || default_language)
      end

      def rouge_formatter(lexer)
        Highlighter::Formatter.new(lexer.tag)
      end
    end

    REDCARPET_OPTIONS = {
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      quote: true,
      strikethrough: true,
      space_after_headers: false,
      tables: true,
      lax_spacing: true,
    }.freeze

    # Spot and capture returns & param HTML for separate display.
    class JazzyDeclarationHTML < JazzyHTML
      attr_reader :returns, :parameters

      def reset
        @returns = nil
        @parameters = {}
      end

      INTRO_PAT = '\A(?<intro>\s*(<p>\s*)?)'.freeze
      OUTRO_PAT = '(?<outro>.*)\z'.freeze

      RETURNS_REGEX = /#{INTRO_PAT}returns:#{OUTRO_PAT}/im

      IDENT_PAT = '(?<param>\S+)'.freeze

      # Param formats: normal swift, objc via sourcekitten, and
      # possibly inside 'Parameters:'
      PARAM_PAT1 = "(parameter +#{IDENT_PAT}\\s*:)".freeze
      PARAM_PAT2 = "(parameter:\\s*#{IDENT_PAT}\\s+)".freeze
      PARAM_PAT3 = "(#{IDENT_PAT}\\s*:)".freeze

      PARAM_PAT = "(?:#{PARAM_PAT1}|#{PARAM_PAT2}|#{PARAM_PAT3})".freeze

      PARAM_REGEX = /#{INTRO_PAT}#{PARAM_PAT}#{OUTRO_PAT}/im

      def list_item(text, _list_type)
        if text =~ RETURNS_REGEX
          @returns = render_param_returns(Regexp.last_match)
        elsif text =~ PARAM_REGEX
          @parameters[Regexp.last_match(:param)] =
            render_param_returns(Regexp.last_match)
        end
        super
      end

      def render_param_returns(matches)
        body = matches[:intro].strip + matches[:outro].strip
        body = "<p>#{body}</p>" unless body.start_with?('<p>')
        # call smartypants for pretty quotes etc.
        postprocess(body)
      end
    end

    def self.renderer
      @renderer ||= JazzyDeclarationHTML.new
    end

    def self.markdown
      @markdown ||= Redcarpet::Markdown.new(renderer, REDCARPET_OPTIONS)
    end

    def self.render(markdown_text, default_language = nil)
      renderer.reset
      renderer.default_language = default_language
      markdown.render(markdown_text)
    end

    def self.rendered_returns
      renderer.returns
    end

    def self.rendered_parameters
      renderer.parameters
    end

    class JazzyCopyright < Redcarpet::Render::HTML
      def link(link, _title, content)
        %(<a class="link" href="#{link}" target="_blank" \
rel="external">#{content}</a>)
      end
    end

    def self.copyright_markdown
      @copyright_markdown ||= Redcarpet::Markdown.new(
        JazzyCopyright,
        REDCARPET_OPTIONS,
      )
    end

    def self.render_copyright(markdown_text)
      copyright_markdown.render(markdown_text)
    end
  end
end
