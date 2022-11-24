module Nanga
  class PrettyPrinter
    OP2STR={
      :add => '+',
      :sub => '-',
      :mul => '*',
      :div => '/',
      :pow => '**',
    }
    def print ast_root
      ast_root.accept(self)
    end

    def visitRoot(root,args=nil)
      code=Code.new
      root.elements.each do |e|
        code << e.accept(self)
        code.newline
      end
      puts code.finalize
    end

    def visitDef(def_,args=nil)
      name=def_.name.accept(self)
      args=def_.args.map{|arg| arg.accept(self)}
      type=def_.type.accept(self)

      code=Code.new
      code << "def #{name}(#{args.join(",")}) : #{type}"
      code.indent=2
      def_.decls.each{|decl| code << decl.accept(self)}
      code << def_.body.accept(self)
      code.indent=0
      code << "end"
      code
    end

    def visitArg(arg,args=nil)
      name=arg.name.tok.val
      type=arg.type.accept(self)
      rge =arg.name.range.accept(self) if arg.name.range
      "#{name} : #{type} #{rge}"
    end

    def visitConst(cst,args=nil)
      name =cst.name.tok.val
      type =cst.type.accept(self)
      val  =cst.val.accept(self)
      rge  =cst.name.range.accept(self) if cst.name.range
      "const #{name} : #{type} = #{val} #{rge}"
    end

    def visitVar(var,args=nil)
      name=var.name.tok.val
      type=var.type.accept(self)
      rge =var.name.range.accept(self) if var.name.range
      "var #{name} : #{type} #{rge}"
    end

    def visitNamedType(type,args=nil)
      type.name.accept(self)
    end

    def visitInterval(interval,args=nil)
      min=interval.min.is_a?(Numeric) ? interval.min : interval.min.accept(self)
      max=interval.max.is_a?(Numeric) ? interval.max : interval.max.accept(self)
      return "{#{min}..#{max}}"
    end

    def visitMapping(mapping,args=nil)
      name=mapping.name.accept(self)
      "@#{name}"
    end

    def visitBody body,args=nil
      code=Code.new
      body.stmts.each do |stmt|
        code << stmt.accept(self)
      end
      code
    end

    def visitCstep cstep,args=nil
      id=cstep.id.accept(self)
      code=Code.new
      code << "cstep #{id} {"
      code.indent=2
      code << cstep.body.accept(self)
      code.indent=0
      code << "}"
      code
    end

    def visitAssign assign,args=nil
      lhs=assign.lhs.accept(self)
      rhs=assign.rhs.accept(self)
      "#{lhs} = #{rhs}"
    end

    def visitReturn ret,args=nil
      e=ret.expr.accept(self)
      "return #{e}"
    end

    def visitBinary binary,args=nil
      lhs=binary.lhs.accept(self)
      op=OP2STR[binary.op]
      rhs=binary.rhs.accept(self)
      mapping=binary.mapping.accept(self) if binary.mapping
      "#{lhs} #{op}#{mapping} #{rhs}"
    end

    def visitUnary unary,args=nil
      unary.expression.accept(self)
    end

    def visitIntType int_type,args=nil
      int_type.accept(self)
    end

    def visitIntervalType interval_type
      interval_type.accept(self)
    end

    def visitIntervalLit interval_lit,args=nil
      lhs=interval_lit.lhs.accept(self)
      rhs=interval_lit.rhs.accept(self)
      "#{lhs}..#{rhs}"
    end

    def visitIntLit intlit,args=nil
      intlit.tok.val
    end

    def visitIdent ident,args=nil
      str=ident.tok.val
      if ident.range
        str+=ident.range.accept(self)
      end
      if ident.mapping
        str+=ident.mapping.accept(self)
      end
      str
    end
  end
end
