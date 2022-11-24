module Nanga
  class Parser < GenericParser
    attr_accessor :tokens
    SUPPRESSABLE=[:space,:newline,:comment1,:comment2]

    def parse filename
      puts "parsing #{filename}"
      code=IO.read(filename)
      tokens=Lexer.new.tokenize(code)
      @tokens=tokens.reject{|tok| SUPPRESSABLE.include? tok.kind}
      parse_root
    rescue Exception => e
      puts e
      puts e.backtrace
    end

    def parse_root
      elements=[]
      while @tokens.any?
        case show_next.kind
        when :def
          elements << parse_def()
        else
          raise "Syntax error : expecting def. Got '#{show_next.val}'"
        end
      end
      root=Root.new(elements)
    end

    def parse_def
      expect :def
      name=Ident.new(expect :ident)
      args=parse_args()
      expect :colon
      type=parse_type
      decls=parse_decls()
      body=parse_body()
      expect :end
      Def.new(name,args,type,decls,body)
    end

    def parse_type
      if lookahead(2).kind==:dotdot
        parse_interval
      else
        NamedType.new(Ident.new(expect :ident))
      end
    end

    def parse_interval
      l=parse_expression()
      expect :dotdot
      r=parse_expression()
      Interval.new(l,r)
    end

    def parse_args
      args=[]
      expect :lparen
      args << parse_arg
      while show_next.is_a? :comma
        accept_it
        args << parse_arg
      end
      expect :rparen
      args
    end

    def parse_arg
      name=Ident.new(expect :ident)
      expect :colon
      type=parse_type
      Arg.new(name,type)
    end

    DECLS=[:const,:var]
    def parse_decls
      decls=[]
      while DECLS.include? kind=show_next.kind
        decls << parse_(kind)
      end
      decls.flatten!
      decls
    end

    def parse_const
      expect :const
      name=Ident.new(expect :ident)
      expect :colon
      type=parse_type()
      expect :eq
      e=parse_expression()
      Const.new(name,type,e)
    end

    def parse_var
      vars=[]
      expect :var
      vars << Var.new(name=Ident.new(expect :ident))
      while show_next.kind==:comma
        accept_it
        vars << Var.new(name=Ident.new(expect :ident))
      end
      expect :colon
      type=parse_type()
      vars.each{|v| v.type=type}
      vars
    end

    def parse_body
      stmts=[]
      while show_next.is_not_a? [:end,:rbrace]
        case show_next.kind
        when :cstep
          stmts << parse_cstep
        when :return
          stmts << parse_return
        when :ident
          lhs=parse_expression()
          case show_next.kind
          when :sig
            stmts << parse_sig(lhs)
          when :eq
            stmts << parse_assignment(lhs)
          end
        else
          raise "syntax error at #{show_next.pos}"
        end
      end
      Body.new(stmts)
    end

    def parse_assignment lhs
      expect :eq
      e=parse_expression()
      Assign.new(lhs,e)
    end

    def parse_cstep
      puts "parse cstep"
      expect :cstep
      id=IntLit.new(expect :int_literal)
      expect :lbrace
      while show_next.is_not_a? :rbrace
        body=parse_body
      end
      expect :rbrace
      Cstep.new(id,body)
    end

    # range attribute can either be a NamedType or Interval
    def parse_range
      if show_next.kind==:lbrace
        accept_it
        parse_type
        expect :rbrace
      end
      return nil
    end

    def parse_mapping
      if show_next.is_a? :at
        expect :at
        name=Ident.new(expect :ident)
        return Mapping.new(name)
      end
    end

    def parse_return
      expect :return
      e=parse_expression
      Return.new(e)
    end

    def parse_expression
      parse_cmp
    end

    COMPARISONS=[:eqeq,:neq,:gt,:gte,:lt,:lte]
    def parse_cmp
      e1=parse_or
      if show_next.is_a? COMPARISONS
        op=accept_it.kind
        e2=parse_or
        e1=Binary.new(e1,op,e2)
      end
      return e1
    end

    def parse_or
      e1=parse_xor
      while show_next.is_a? :or
        tok=accept_it.tok
        e2=parse_xor()
        e1=Binary.new(e1,:or,e2)
      end
      e1
    end

    def parse_xor
      e1=parse_and
      while show_next.is_a? :xor
        tok=accept_it.tok
        e2=parse_and()
        e1=Binary.new(e1,:xor,e2)
      end
      e1
    end

    def parse_and
      e1=parse_shift()
      while show_next.is_a? :and
        tok=accept_it.tok
        e2=parse_shift()
        e1=Binary.new(e1,:and,e2)
      end
      e1
    end

    def parse_shift
      e1=parse_arith
      while show_next.is_a? [:lshift,:rshift]
        tok=accept_it
        map=parse_mapping
        e2=parse_arith()
        e1=Binary.new(e1,tok.kind,e2,map)
      end
      e1
    end

    def parse_arith
      e1=parse_term()
      while show_next.is_a? [:add,:sub]
        tok=accept_it
        map=parse_mapping()
        e2=parse_term()
        e1=Binary.new(e1,tok.kind,e2,map)
      end
      return e1
    end

    def parse_term
      e1=parse_power()
      while show_next.is_a? [:mul,:div,:mod]
        tok=accept_it
        map=parse_mapping()
        e2=parse_power()
        e1=Binary.new(e1,tok.kind,e2,map)
      end
      return e1
    end

    def parse_power
      e1=parse_factor()
      while show_next.is_a? [:pow]
        tok=accept_it
        e2=parse_factor()
        e1=Binary.new(e1,:pow,e2)
      end
      return e1
    end

    def parse_factor
      case show_next.kind
      when :ident
        tok=accept_it
        dyn=parse_range()
        map=parse_mapping()
        Ident.new(tok,dyn,map)
      when :int_literal
        tok=accept_it
        IntLit.new(tok)
      when :sub,:add
        parse_unary
      else
        raise "SYNTAX ERROR in term at #{show_next.pos}: #{show_next.val} (#{show_next.kind})"
      end
    end

    def parse_unary
      if [:add,:sub].include? show_next.kind
        op=accept_it.kind
        e=parse_arith()
        return Unary.new(op,e)
      end
    end

  end
end
