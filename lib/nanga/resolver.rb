module Nanga
  class Resolver < Visitor
    def run ast
      super(ast)
    end

    def visitDef def_,args=nil
      def_.symtable=@symtable={}
      @symtable[def_.name.str]=def_
      super(def_)
    end

    def visitNamedType type,args=nil
      @symtable[type.name.str]=type
    end

    def visitArg arg,args=nil
      arg.type.accept(self) #register its type
      @symtable[p arg.name.str]=arg
    end

    def visitConst const,args=nil
      @symtable[const.name.str]=const
    end

    def visitIdent ident,args=nil
      if def_=@symtable[ident.str]
        return def_.name
      end
      ident
    end
  end
end
