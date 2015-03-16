module Rugments
  module Lexers
    class Julia < RegexLexer
      title 'Julia'
      desc 'Julia'
      tag 'julia'
      aliases 'jl'
      filenames '*.jl'
      mimetypes 'text/x-julia', 'application/x-julia'

      def self.analyze_text(text)
        return 0.4 if text.match(/^\s*% /) # % comments are a dead giveaway
      end

      def self.keywords
        @keywords = Set.new %w(
          begin while for in return break continue
             macro quote let if elseif else try catch end
             bitstype ccall do using module import export
             importall baremodule immutable
        )
      end
	  
	  def self.keywords_type
        @keywords_type ||= Set.new %w(
          Bool Int Int8 Int16 Int32 Int64 Uint Uint8 Uint16 Uint32 Uint64
          Float32 Float64 Complex64 Complex128 Any Nothing None
        )
      end

      def self.builtins
        load Pathname.new(__FILE__).dirname.join('julia/builtins.rb')
        builtins
      end

      state :root do
        rule /\s+/m, Text # Whitespace
        rule %r([{]%.*?%[}])m, Comment::Multiline
        rule /#.*$/, Comment::Single
        rule /([.][.][.])(.*?)$/ do
          groups(Keyword, Comment)
        end

        rule /^(!)(.*?)(?=%|$)/ do |m|
          token Keyword, m[1]
          delegate Shell, m[2]
        end

        rule /[a-zA-Z][_a-zA-Z0-9]*/m do |m|
          match = m[0]
          if self.class.keywords.include? match
            token Keyword
		  elsif self.class.keywords_type.include? match
            token Keyword::Type
          elsif self.class.builtins.include? match
            token Name::Builtin
          else
            token Name
          end
        end

        rule %r{[(){};:,\/\\\]\[]}, Punctuation

        rule /~=|==|<<|>>|[-~+\/*%=<>&^|.@]/, Operator

        rule /(\d+\.\d*|\d*\.\d+)(e[+-]?[0-9]+)?/i, Num::Float
        rule /\d+e[+-]?[0-9]+/i, Num::Float
        rule /\d+L/, Num::Integer::Long
        rule /\d+/, Num::Integer
		
        # TODO should probably be: 
        # rule /(?<![\]\)\w\.])'/i, Str::Single, :string
        # unfortunately look-behind assertion do not work
        # This rule leads to false recognition of strings
        # when using something like c = a' + b'; but all other
        # cases should be working
        rule /'(?=(.*'))/, Str::Single, :string 
        rule /'/, Operator
      end

      state :string do
        rule /[^']+/, Str::Single
        rule /''/, Str::Escape
        rule /'/, Str::Single, :pop!
      end
    end
  end
end
