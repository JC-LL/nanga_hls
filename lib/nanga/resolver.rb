module Nanga
  class Resolver < CompilerPass
    def run ast
      @symtable=Symtable.new
      @symtable.create_scope #upper scope, seeing func definitions
      super(ast)
    end

    def visitDef def_,args=nil
      @symtable.set def_.name.str,def_
      @symtable.create_scope
      super(def_)
      def_.symtable=@symtable.get_scope
      @symtable.leave_scope
      def_
    end

    def visitArg arg,args=nil
      report 2,"registering #{arg.name.str}"
      unless @symtable.get arg.name.str
        @symtable.set arg.name.str,arg
      else
        raise "ERROR : duplicate #{arg.name.str}"
      end
      arg
    end

    def visitVar var,args=nil
      #report 1,"registering #{var.name.str}"
      @symtable.set var.name.str,var
      var
    end

    def visitConst const,args=nil
      report 2,"registering #{const.name.str}"
      @symtable.set const.name.str,const
      const
    end

    def visitNamedType ntype,args=nil
      report 2,"registering #{ntype.name.str}"
      unless @symtable.get ntype.name.str
        @symtable.set ntype.name.str,ntype
      end
      ntype
    end

    def visitIdent ident,args=nil
      if reference=@symtable.get(ident.str)
        report  2,"linking #{ident.str} to a #{reference.class}"
        ident.ref=reference
      else
        raise "unknown identifier '#{ident.str}'. Not found in symtable."
      end
      ident
    end

  end
end
