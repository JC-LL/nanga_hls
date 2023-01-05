module Nanga
  class Visitor
    def run ast_root,args=nil
      ast_root.accept(self,args)
    end

    alias :visit :run

    def visitRoot(root,args=nil)
      root.elements=root.elements.map{|e| e.accept(self,args)}
      root
    end

    def visitDef(def_,args=nil)
      def_.name=def_.name.accept(self,args)
      def_.args=def_.args.map{|arg| arg.accept(self,args)}
      def_.type=def_.type.accept(self,args)
      def_.decls=def_.decls.each{|decl| decl.accept(self,args)}
      def_.body=def_.body.accept( self,args)
      def_
    end

    def visitArg(arg,args=nil)
      arg.name=arg.name.accept(self,args)
      arg.type=arg.type.accept(self,args)
      arg
    end

    def visitConst(cst,args=nil)
      cst.name=cst.name.accept(self,args)
      cst.type=cst.type.accept(self,args)
      cst.val  =cst.val.accept(self,args)
      cst
    end

    def visitVar(var,args=nil)
      var.name=var.name.accept(self,args)
      var.type=var.type.accept(self,args)
      var
    end

    def visitNamedType(type,args=nil)
      type.name=type.name.accept(self,args)
      type
    end

    def visitInterval(interval,args=nil)
      interval.min=interval.min.accept(self,args)
      interval.max=interval.max.accept(self,args)
      interval
    end

    def visitMapping(mapping,args=nil)
      mapping.name=mapping.name.accept(self,args)
      mapping
    end

    def visitBody body,args=nil
      puts "visiting body"
      body.stmts=body.stmts.map{|stmt|stmt.accept(self,args)}
      body
    end

    def visitCstep cstep,args=nil
      cstep.id=cstep.id.accept(self,args)
      cstep.body=cstep.body.accept(self,args)
      cstep
    end

    def visitAssign assign,args=nil
      puts "visiting #{assign.str}"
      assign.lhs=assign.lhs.accept(self,args)
      assign.rhs=assign.rhs.accept(self,args)
      assign
    end

    def visitReturn ret,args=nil
      ret.expr=ret.expr.accept(self,args)
      ret
    end

    def visitBinary binary,args=nil
      binary.lhs=binary.lhs.accept(self,args)
      binary.op =binary.op
      binary.rhs=binary.rhs.accept(self,args)
      binary
    end

    def visitUnary unary,args=nil
      unary.expr=unary.expr.accept(self,args)
    end

    def visitIntervalType interval_type
      interval_type
    end

    def visitIntervalLit interval_lit,args=nil
      interval_lit.lhs=interval_lit.lhs.accept(self,args)
      interval_lit.rhs=interval_lit.rhs.accept(self,args)
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
