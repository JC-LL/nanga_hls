module Nanga
  class StrengthReductor < Emitter

    def visitAssign assign,args=nil
      lhs,rhs=assign.lhs,assign.rhs
      case bin=rhs
      when Binary
        blhs,brhs=bin.lhs,bin.rhs
        case bin.op
        when :pow
          tmp=rhs.accept(self)
          exp=Binary.new(blhs,:mul,tmp)
          emit Assign.new(lhs,exp)
        else
          super(assign) #emit
        end
      else
        super(assign) #emit
      end
    end

    def visitBinary bin,args=nil
      lhs,rhs=bin.lhs,bin.rhs
      case op=bin.op
      when :pow
        case rhs
        when IntLit
          val=rhs.str.to_i
          tmp_old=lhs
          (val-2).times do
            tmp_new=create_tmp(bin.range)
            emit Assign.new(tmp_new,Binary.new(tmp_old,:mul,lhs))
            tmp_old=tmp_new
          end
          return tmp_old
        end
      end
      bin
    end
  end
end
