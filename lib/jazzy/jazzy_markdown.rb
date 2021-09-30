# frozen_string_literal: true

require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

module Jazzy
  module Markdown
    # Publish if generated HTML needs math support
    class << self; attr_accessor :has_math; end

    module Footnotes
      # Global unique footnote ID
      def self.next_footnote
        @next_footnote ||= 0
        @next_footnote += 1
      end

      # Per-render map from user to global ID
      attr_accessor :footnotes_hash

      def reset
        @footnotes_hash = {}
      end

      def map_footnote(user_num)
        footnotes_hash.fetch(user_num) do
          footnotes_hash[user_num] = Footnotes.next_footnote
        end
      end

      def footnote_ref(num)
        mapped = map_footnote(num)
        "<span class='footnote-ref' id=\"fnref#{mapped}\">" \
          "<sup><a href=\"#fn#{mapped}\">#{num}</a></sup></span>"
      end

      # follow native redcarpet: backlink goes before the first </p> tag
      def footnote_def(text, num)
        mapped = map_footnote(num)
        "\n<li><div class='footnote-def' id=\"fn#{mapped}\">" +
          text.sub(%r{(?=</p>)},
                   "&nbsp;<a href=\"#fnref#{mapped}\">&#8617;</a>") +
          '</div></li>'
      end
    end

    # rubocop:disable Metrics/ClassLength
    class JazzyHTML < Redcarpet::Render::HTML
      include Redcarpet::Render::SmartyPants
      include Rouge::Plugins::Redcarpet
      include Footnotes

      attr_accessor :default_language

      def header(text, header_level)
        text_slug = text.gsub(/[^[[:word:]]]+/, '-')
          .downcase
          .sub(/^-/, '')
          .sub(/-$/, '')

        "<h#{header_level} id='#{text_slug}' class='heading'>" \
          "#{text}" \
          "</h#{header_level}>\n"
      end

      def codespan(text)
        case text
        when /^\$\$(.*)\$\$$/m
          o = ["</p><div class='math m-block'>",
               Regexp.last_match[1],
               '</div><p>']
          Markdown.has_math = true
        when /^\$(.*)\$$/m
          o = ["<span class='math m-inline'>", Regexp.last_match[1], '</span>']
          Markdown.has_math = true
        else
          o = ['<code>', text.to_s, '</code>']
        end

        o[0] + CGI.escapeHTML(o[1]) + o[2]
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
        }ix.freeze

      ELIDED_LI_TOKEN =
        '7wNVzLB0OYPL2eGlPKu8q4vITltqh0Y6DPZf659TPMAeYh49o'

      def list_item(text, _list_type)
        if text =~ SPECIAL_LIST_TYPE_REGEX
          type = Regexp.last_match(2)
          if UNIQUELY_HANDLED_CALLOUTS.include? type.downcase
            return ELIDED_LI_TOKEN
          end

          return render_list_aside(type,
                                   text.sub(/#{Regexp.escape(type)}:\s+/, ''))
        end
        "<li>#{text.strip}</li>\n"
      end

      def render_list_aside(type, text)
        "</ul>#{render_aside(type, text).chomp}<ul>\n"
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

        tag = list_type == :ordered ? 'ol' : 'ul'
        "\n<#{tag}>\n#{text}</#{tag}>\n"
          .gsub(%r{\n?<ul>\n?</ul>}, '')
      end

      # List from
      # https://developer.apple.com/documentation/xcode/formatting-your-documentation-content#Add-Notes-and-Other-Asides
      DOCC_CALLOUTS = %w[note
                         important
                         warning
                         tip
                         experiment].freeze

      DOCC_CALLOUT_REGEX = %r{
        \A\s* # optional leading spaces
        (?:<p>\s*)? # optional opening p tag
        # any one of the callout names
        (#{DOCC_CALLOUTS.map(&Regexp.method(:escape)).join('|')})
        : # followed directly by a colon
      }ix.freeze

      def block_quote(html)
        if html =~ DOCC_CALLOUT_REGEX
          type = Regexp.last_match[1]
          render_aside(type, html.sub(/#{Regexp.escape(type)}:\s*/, ''))
        else
          "\n<blockquote>\n#{html}</blockquote>\n"
        end
      end

      def block_code(code, language)
        super(code, language || default_language)
      end

      def rouge_formatter(lexer)
        Highlighter::Formatter.new(lexer.tag)
      end
    end
    # rubocop:enable Metrics/ClassLength

    REDCARPET_OPTIONS = {
      autolink: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true,
      strikethrough: true,
      space_after_headers: false,
      tables: true,
      lax_spacing: true,
      footnotes: true,
    }.freeze

    # Spot and capture returns & param HTML for separate display.
    class JazzyDeclarationHTML < JazzyHTML
      attr_reader :returns, :parameters

      def reset
        @returns = nil
        @parameters = {}
        super
      end

      INTRO_PAT = '\A(?<intro>\s*(<p>\s*)?)'
      OUTRO_PAT = '(?<outro>.*)\z'

      RETURNS_REGEX = /#{INTRO_PAT}returns:#{OUTRO_PAT}/im.freeze

      IDENT_PAT = '(?<param>\S+)'

      # Param formats: normal swift, objc via sourcekitten, and
      # possibly inside 'Parameters:'
      PARAM_PAT1 = "(parameter +#{IDENT_PAT}\\s*:)"
      PARAM_PAT2 = "(parameter:\\s*#{IDENT_PAT}\\s+)"
      PARAM_PAT3 = "(#{IDENT_PAT}\\s*:)"

      PARAM_PAT = "(?:#{PARAM_PAT1}|#{PARAM_PAT2}|#{PARAM_PAT3})"

      PARAM_REGEX = /#{INTRO_PAT}#{PARAM_PAT}#{OUTRO_PAT}/im.freeze

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

    # Produces <p>-delimited block content
    def self.render(markdown_text, default_language = nil)
      renderer.reset
      renderer.default_language = default_language
      markdown.render(markdown_text)
    end

    # Produces <span>-delimited inline content
    def self.render_inline(markdown_text, default_language = nil)
      render(markdown_text, default_language)
        .sub(%r{^<p>(.*)</p>$}, '<span>\1</span>')
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
rel="external noopener">#{content}</a>)
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
