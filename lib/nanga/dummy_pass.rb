module Nanga
  class DummyPass < Visitor
    def visitDef func,args=nil
      puts "func #{func.name.str}"
      puts func.symtable.keys
      func
    end
  end
end
