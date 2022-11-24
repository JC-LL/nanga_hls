module Nanga
  class Lexer < GenericLexer
    def initialize
      super
      keyword 'def'
      keyword 'end'
      keyword 'bool'
      keyword 'string'
      keyword 'float'
      keyword 'const'
      keyword 'var'
      keyword 'cstep'
      keyword 'return'
      #....................
      keyword 'and'
      keyword 'or'
      keyword 'xor'
      keyword 'not'
      #.....................
      #.............................................................
      token :comment1           => /\A\#(.*)$/
      token :comment2           => /\A\;(.*)$/
      token :bool_literal      => /true|false/
      token :ident             => /[a-zA-Z]\w*/
      token :string_literal    => /"[^"]*"/
      token :char_literal      => /'(\w+)'/
      token :float_literal     => /\d+\.\d+([Ee]([+-]?)\d+)?/
      token :int_literal       => /0x(\da-fA-F)+|0b(01)+|\d+/
  
      token :comma             => /\A\,/
      token :colon             => /\A\:/
      token :semicolon         => /\A\;/
      token :lparen            => /\A\(/
      token :rparen            => /\A\)/
      token :lbrack            => /\A\[/
      token :rbrack            => /\A\]/
      token :lbrace            => /\A\{/
      token :rbrace            => /\A\}/

      # arith
      token :addeq             => /\A\+\=/
      token :subeq             => /\A\-\=/
      token :muleq             => /\A\*\=/
      token :diveq             => /\A\/\=/
      token :lshift            => /\A\<\</
      token :rshift            => /\A\>\>/

      token :add               => /\A\+/
      token :sub               => /\A\-/
      token :pow               => /\A\*\*/
      token :mul               => /\A\*/
      token :div               => /\A\//
      token :mod               => /\A\%/
      token :at                => /\A\@/



      # logical
      token :eqeq              => /\A\=\=/
      token :eq                => /\A\=/
      token :addeq             => /\A\+\=/
      token :subeq             => /\A\-\=/
      token :muleq             => /\A\*\=/
      token :diveq             => /\A\/\=/
      token :modeq             => /\A\%\=/
      token :oreq             => /\A\/|=/
      token :andeq             => /\A\/&=/

      token :neq               => /\A\!\=/
      token :gte               => /\A\>\=/
      token :gt                => /\A\>/
      token :lte               => /\A\<\=/
      token :sig               => /\A\<\~/
      token :lt                => /\A\</

      token :ampersand         => /\A\&/

      token :etc               => /\A\.\.\./
      token :dotdot            => /\A\.\./
      token :dot               => /\A\./
      token :bar               => /\|/
      #............................................................
      token :newline           =>  /[\n]/
      token :space             => /[ \t\r]+/

    end #def
  end
end
