module Nanga
  class RangePropagator < Visitor

    def visitArg arg,args=nil
      set_ident_range(arg)
      arg
    end

    def visitVar var,args=nil
      set_ident_range(var)
      var
    end

    def set_ident_range decl
      case decl.type.str
      when /[is](\d+)/
        nbits=$1.to_i
        min,max=-2**(nbits-1),+2**(nbits-1)-1
        decl.name.range=Interval.new(min,max)
      when /u(\d+)/
        nbits=$1.to_i
        min,max=0,+2**nbits-1
        decl.name.range=Interval.new(min,max)
      end
    end

    def visitConst cst,args=nil
      val=cst.val.tok.val.to_i
      cst.name.range=Interval.new(val,val)
      cst
    end

    def visitAssign assign,args=nil
      rhs=assign.rhs.accept(self)
      assign.lhs.range=rhs.range
      assign
    end

    def visitBinary bin,args=nil
      l=bin.lhs.accept(self)
      o=bin.op
      r=bin.rhs.accept(self)
      bin.range=compute_range(l.range,o,r.range)
      bin
    end

    def visitIdent ident,args=nil
      ident
    end

    def compute_range x,op,y
      case op
      when :add
        min,max=[x.min+y.min,x.max+y.max].minmax
      when :sub
        min,max=[x.min-y.min,x.max-y.max].minmax
      when :mul
        min,max=[x.min*y.min,x.min*y.max,x.max*y.min,x.max*y.max].minmax
      when :div
        raise "NIY : div"
      end
      return Interval.new(min,max)
    end
  end
end
