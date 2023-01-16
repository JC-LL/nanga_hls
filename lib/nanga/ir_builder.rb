module Nanga

  class IrBuilder < Emitter

    def generate ast
      ast.accept(self)
    end

    def visitReturn ret,args=nil
      e=ret.expr.accept(self)
      if e.is_a?(Binary)
        tmp=create_tmp(e.range)
        emit Assign.new(tmp,e)
        emit ret=Return.new(tmp)
      else
        emit ret=Return.new(e)
      end
      ret
    end

    def visitBinary bin,args=nil
      lhs,rhs=bin.lhs,bin.rhs
      if lhs.is_a?(Binary)
        new_lhs=lhs.accept(self)
        tmp=create_tmp(lhs.range)
        emit Assign.new(tmp,new_lhs)
        lhs=tmp
      end
      if rhs.is_a?(Binary)
        new_rhs=rhs.accept(self)
        tmp=create_tmp(rhs.range)
        emit Assign.new(tmp,new_rhs)
        rhs=tmp
      end
      return Binary.new(lhs,bin.op,rhs)
    end
  end
end
