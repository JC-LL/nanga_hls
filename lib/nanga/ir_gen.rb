module Nanga

  class IrGen < Emitter

    def generate ast
      ast.accept(self)
    end

    def visitAssign assign,args=nil
      lhs=assign.lhs.accept(self)
      rhs=assign.rhs.accept(self)
      emit ret=Assign.new(lhs,rhs)
      ret
    end

    def visitReturn ret,args=nil
      e=ret.expr.accept(self)
      emit ret=Return.new(e)
      ret
    end

    def visitBinary bin,args=nil
      lhs=bin.lhs.accept(self)
      rhs=bin.rhs.accept(self)
      tmp=create_tmp(bin.range)
      emit Assign.new(tmp,Binary.new(lhs,bin.op,rhs,bin.range))
      return tmp
    end
  end
end
