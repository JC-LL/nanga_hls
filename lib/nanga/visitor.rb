module Nanga
  class Visitor
    def run ast_root
      ast_root.accept(self)
    end

    alias :visit :run

    def visitRoot(root,args=nil)
      root.elements=root.elements.map{|e| e.accept(self)}
      root
    end

    def visitDef(def_,args=nil)
      #  @symtable will be seen for EVERY pass inheriting Visitor :
      @symtable=def_.symtable
      def_.name=def_.name.accept(self)
      def_.args=def_.args.map{|arg| arg.accept(self)}
      def_.type=def_.type.accept(self)
      def_.decls=def_.decls.each{|decl| decl.accept(self)}
      def_.body=def_.body.accept( self)
      def_
    end

    def visitArg(arg,args=nil)
      arg.name=arg.name.accept(self)
      arg.type=arg.type.accept(self)
      arg
    end

    def visitConst(cst,args=nil)
      cst.name=cst.name.accept(self)
      cst.type=cst.type.accept(self)
      cst.val  =cst.val.accept(self)
      cst
    end

    def visitVar(var,args=nil)
      var.name=var.name.accept(self)
      var.type=var.type.accept(self)
      var
    end

    def visitNamedType(type,args=nil)
      type.name=type.name.accept(self)
      type
    end

    def visitInterval(interval,args=nil)
      interval.min=interval.min.accept(self)
      interval.max=interval.max.accept(self)
      interval
    end

    def visitMapping(mapping,args=nil)
      mapping.name=mapping.name.accept(self)
      mapping
    end

    def visitBody body,args=nil
      body.stmts=body.stmts.map{|stmt|stmt.accept(self)}
      body
    end

    def visitCstep cstep,args=nil
      cstep.id=cstep.id.accept(self)
      cstep.body=cstep.body.accept(self)
      cstep
    end

    def visitAssign assign,args=nil
      assign.lhs=assign.lhs.accept(self)
      assign.rhs=assign.rhs.accept(self)
      assign
    end

    def visitReturn ret,args=nil
      ret.expr=ret.expr.accept(self)
      ret
    end

    def visitBinary binary,args=nil
      binary.lhs=binary.lhs.accept(self)
      binary.op =binary.op
      binary.rhs=binary.rhs.accept(self)
      binary.mapping=binary.mapping.accept(self) if binary.mapping
      binary
    end

    def visitUnary unary,args=nil
      unary.expr=unary.expr.accept(self)
    end

    def visitIntervalType interval_type
      interval_type
    end

    def visitIntervalLit interval_lit,args=nil
      interval_lit.lhs=interval_lit.lhs.accept(self)
      interval_lit.rhs=interval_lit.rhs.accept(self)
      interval_lit
    end

    def visitIntLit intlit,args=nil
      intlit
    end

    def visitIdent ident,args=nil
      ident
    end
  end
end
