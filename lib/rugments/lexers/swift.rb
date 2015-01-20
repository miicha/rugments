module Rugments
  module Lexers
    class Swift < RegexLexer
      tag 'swift'
      filenames '*.swift'

      title 'Swift'
      desc 'Multi paradigm, compiled programming language developed by Apple for iOS and OS X development. (developer.apple.com/swift)'

      id_head = /_|(?!\p{Mc})\p{Alpha}|[^\u0000-\uFFFF]/
      id_rest = /[\p{Alnum}_]|[^\u0000-\uFFFF]/
      id = /#{id_head}#{id_rest}*/

      keywords = Set.new %w(
        break case continue default do else fallthrough if in for return switch where while

        as dynamicType is new super self Self Type __COLUMN__ __FILE__ __FUNCTION__ __LINE__

        associativity didSet get infix inout left mutating none nonmutating operator override postfix precedence prefix right set unowned weak willSet
      )

      declarations = Set.new %w(
        class deinit enum extension final func import init internal lazy let optional private protocol public required static struct subscript typealias var dynamic
      )

      attributes = Set.new %w(
        autoclosure IBAction IBDesignable IBInspectable IBOutlet noreturn NSCopying NSManaged objc UIApplicationMain NSApplicationMain objc_block
      )

      constants = Set.new %w(
        true false nil
      )

      start { push :bol }

      # beginning of line
      state :bol do
        rule /#.*/, Comment::Preproc

        mixin :inline_whitespace

        rule(//) { pop! }
      end

      state :inline_whitespace do
        rule /\s+/m, Text
        rule %r{(?<re>\/\*(?:(?>[^\/\*\*\/]+)|\g<re>)*\*\/)}m, Comment::Multiline
      end

      state :whitespace do
        rule /\n+/m, Text, :bol
        rule %r{\/\/.*?$}, Comment::Single, :bol
        mixin :inline_whitespace
      end

      state :root do
        mixin :whitespace
        rule /\$(([1-9]\d*)?\d)/, Name::Variable

        rule %r{[()\[\]{}:;,?]}, Punctuation
        rule %r{[-/=+*%<>!&|^.~]+}, Operator
        rule /@?"/, Str, :dq
        rule /'(\\.|.)'/, Str::Char
        rule /(\d+\*|\d*\.\d+)(e[+-]?[0-9]+)?/i, Num::Float
        rule /\d+e[+-]?[0-9]+/i, Num::Float
        rule /0_?[0-7]+(?:_[0-7]+)*/, Num::Oct
        rule /0x[0-9A-Fa-f]+(?:_[0-9A-Fa-f]+)*/, Num::Hex
        rule /0b[01]+(?:_[01]+)*/, Num::Bin
        rule %r{[\d]+(?:_\d+)*}, Num::Integer

        rule /@availability[(][^)]+[)]/, Keyword::Declaration

        rule /(@objc[(])([^)]+)([)])/ do
          groups Keyword::Declaration, Name::Class, Keyword::Declaration
        end

        rule /@(#{id})/ do |m|
          if attributes.include? m[1]
            token Keyword
          else
            token Error
          end
        end

        rule /(private|internal)(\([ ]*)(\w+)([ ]*\))/ do |m|
          if m[3] == 'set'
            token Keyword::Declaration
          else
            groups Keyword::Declaration, Keyword::Declaration, Error, Keyword::Declaration
          end
        end

        rule /(unowned\([ ]*)(\w+)([ ]*\))/ do |m|
          if m[2] == 'safe' || m[2] == 'unsafe'
            token Keyword::Declaration
          else
            groups Keyword::Declaration, Error, Keyword::Declaration
          end
        end

        rule /(let|var)\b(\s*)(#{id})/ do
          groups Keyword, Text, Name::Variable
        end

        rule /(?!\b(if|while|for|private|internal|unowned|switch|case)\b)\b#{id}(?=(\?|!)?\s*[(])/ do |m|
          if m[0] =~ /^[[:upper:]]/
            token Keyword::Type
          else
            token Name::Function
          end
        end

        rule /(#?(?!default)(?![[:upper:]])#{id})(\s*)(:)/ do
          groups Name::Variable, Text, Punctuation
        end

        rule id do |m|
          if keywords.include? m[0]
            token Keyword
          elsif declarations.include? m[0]
            token Keyword::Declaration
          elsif constants.include? m[0]
            token Keyword::Constant
          elsif m[0] =~ /^[[:upper:]]/
            token Keyword::Type
          else
            token Name
          end
        end
      end

      state :dq do
        rule /\\[\\0tnr'"]/, Str::Escape
        rule /\\[(]/, Str::Escape, :interp
        rule /\\u\{\h{1,8}\}/, Str::Escape
        rule /[^\\"]+/, Str
        rule /"/, Str, :pop!
      end

      state :interp do
        rule /[(]/, Punctuation, :interp_inner
        rule /[)]/, Str::Escape, :pop!
        mixin :root
      end

      state :interp_inner do
        rule /[(]/, Punctuation, :push
        rule /[)]/, Punctuation, :pop!
        mixin :root
      end
    end
  end
end
