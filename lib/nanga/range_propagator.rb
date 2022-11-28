module Nanga
  class RangePropagator < Visitor

    def visitDef func,args=nil
      ret=super(func)
      #now that ranges are known, we can indicate the types of each variable
      back_annotate_types(ret)
      ret
    end

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

    def back_annotate_types def_
      puts " |--[+] type annotations"
      vars=def_.decls.select{|decl| decl.is_a? Var}
      undef_vars=vars.select{|var| var.type.str=="unknown"}
      undef_vars.each do |var|
        min,max=var.range.min,var.range.max
        type=(min >=0) ? get_unsigned(min,max) : get_signed(min,max)
        var.type=Ident.create(type)
      end
    end

    include Math
    def get_unsigned(min,max)
      nbits=log2(max).floor + 1
      return "u#{nbits}"
    end

    def get_signed(min,max)
      nbits=log2([min.abs-1,max.abs].max).floor + 2
      return "s#{nbits}"
    end
  end
end
