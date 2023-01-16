module Nanga
  OP2STR={
    :add => '+',
    :sub => '-',
    :mul => '*',
    :div => '/',
    :pow => '**',
  }

  class PrettyPrinter < CompilerPass

    def print ast_root,verbose=false
      ast_root.accept(self,verbose)
    end

    def visitRoot(root,verbose=false)
      code=Code.new
      root.elements.each do |e|
        code << e.accept(self,verbose)
        code.newline
      end
      code
    end

    def visitDef(def_,verbose=false)
      name=def_.name.accept(self)
      args=def_.args.map{|arg| arg.accept(self,verbose)}
      type=def_.type.accept(self,verbose)

      code=Code.new
      code << "def #{name}(#{args.join(",")}) : #{type}"
      code.indent=2
      def_.decls.each{|decl| code << decl.accept(self,verbose)}
      code << def_.body.accept(self,verbose)
      code.indent=0
      code << "end"
      code
    end

    def visitArg(arg,verbose=false)
      name=arg.name.tok.val
      type=arg.type.accept(self,verbose)
      rge =arg.name.range.accept(self,verbose) if arg.name.range
      "#{name} : #{type} #{rge}"
    end

    def visitConst(cst,verbose=false)
      name =cst.name.tok.val
      type =cst.type.accept(self,verbose)
      val  =cst.val.accept(self,verbose)
      rge  =cst.name.range.accept(self,verbose) if cst.name.range
      "const #{name} : #{type} = #{val} #{rge}"
    end

    def visitVar(var,verbose=false)
      name=var.name.tok.val
      type=var.type.accept(self,verbose)
      rge =var.name.range.accept(self,verbose) if var.name.range
      "var #{name} : #{type} #{rge}"
    end

    def visitNamedType(type,verbose=false)
      type.name.accept(self,verbose)
    end

    def visitInterval(interval,verbose=false)
      min=interval.min.is_a?(Numeric) ? interval.min : interval.min.accept(self,verbose)
      max=interval.max.is_a?(Numeric) ? interval.max : interval.max.accept(self,verbose)
      verbose ? "{#{min}..#{max}}" :""
    end

    def visitMapping(mapping,verbose=false)
      name=mapping.name.accept(self,verbose)
      verbose ? "@#{name}" : ""
    end

    def visitBody body,verbose=false
      code=Code.new
      body.stmts.each do |stmt|
        code << stmt.accept(self,verbose)
      end
      code
    end

    def visitCstep cstep,verbose=false
      id=cstep.id.accept(self,verbose)
      code=Code.new
      code << "cstep #{id} {"
      code.indent=2
      code << cstep.body.accept(self,verbose)
      code.indent=0
      code << "}"
      code
    end

    def visitAssign assign,verbose=false
      lhs=assign.lhs.accept(self,verbose)
      rhs=assign.rhs.accept(self,verbose)
      "#{lhs} = #{rhs}"
    end

    def visitReturn ret,verbose=false
      e=ret.expr.accept(self,verbose)
      "return #{e}"
    end

    def visitBinary binary,verbose=false
      lhs=binary.lhs.accept(self,verbose)
      op=OP2STR[binary.op]
      rhs=binary.rhs.accept(self,verbose)
      case binary.mapping
      when Ident
        (mapping=("@"+binary.mapping.accept(self))) if binary.mapping
      when Dataflow::Node
        mapping="@"+binary.mapping.name
      end
      "#{lhs} #{op}#{mapping} #{rhs}"
    end

    def visitUnary unary,verbose=false
      unary.expression.accept(self,verbose)
    end

    def visitCast cast,verbose=false
      type=cast.type.accept(self,verbose)
      expr=cast.expr.accept(self,verbose)
      "('#{type} #{expr})"
    end

    def visitIntType int_type,verbose=false
      int_type.accept(self,verbose)
    end

    def visitIntervalType interval_type
      interval_type.accept(self,verbose)
    end

    def visitIntervalLit interval_lit,verbose=false
      lhs=interval_lit.lhs.accept(self,verbose)
      rhs=interval_lit.rhs.accept(self,verbose)
      "#{lhs}..#{rhs}"
    end

    def visitIntLit intlit,verbose=false
      intlit.tok.val
    end

    def visitIdent ident,verbose=false
      str=ident.tok.val
      if ident.range
        str+=ident.range.accept(self,verbose)
      end
      if ref=ident.ref
        case ref
        when Var
          if mapping=ref.mapping
            str+="@"+mapping.name
          end
        when Arg
          if mapping=ref.mapping
            str+="@"+mapping.name
          end
        end
      end
      str
    end
  end
end
