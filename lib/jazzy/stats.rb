module Jazzy
  # Collect + report metadata about a processed module
  class Stats
    include Config::Mixin

    attr_reader :documented, :acl_skipped
    attr_reader :undocumented_decls

    def add_documented
      @documented += 1
    end

    def add_acl_skipped
      @acl_skipped += 1
    end

    def add_undocumented(decl)
      @undocumented_decls << decl
    end

    def acl_included
      documented + undocumented
    end

    def undocumented
      undocumented_decls.count
    end

    def initialize
      @documented = @acl_skipped = 0
      @undocumented_decls = []
    end

    def report
      puts "#{doc_coverage}\% documentation coverage " \
        "with #{undocumented} undocumented " \
        "#{symbol_or_symbols(undocumented)}"

      if acl_included > 0
        swift_acls = comma_list(config.min_acl.included_levels)
        puts "included #{acl_included} " +
             (config.objc_mode ? '' : "#{swift_acls} ") +
             symbol_or_symbols(acl_included)
      end

      if !config.objc_mode && acl_skipped > 0
        puts "skipped #{acl_skipped} " \
          "#{comma_list(config.min_acl.excluded_levels)} " \
          "#{symbol_or_symbols(acl_skipped)} " \
          '(use `--min-acl` to specify a different minimum ACL)'
      end
    end

    def doc_coverage
      return 0 if acl_included == 0
      (100 * documented) / acl_included
    end

    private

    def comma_list(items)
      case items.count
      when 0 then ''
      when 1 then items[0]
      when 2 then "#{items[0]} or #{items[1]}"
      else "#{items[0..-2].join(', ')}, or #{items[-1]}"
      end
    end

    def symbol_or_symbols(count)
      count == 1 ? 'symbol' : 'symbols'
    end
  end
end
