module Nanga
  class RangePropagator < CompilerPass

    def visitDef func,args=nil
      func.args.each{|arg| arg.accept(self,args)}
      func.decls.each{|var| var.accept(self,args)}
      func.body=func.body.accept( self,args)
      # now that ranges are known, we can indicate the types of each variable
      back_annotate_types(func)
      #verify that (return x) is correct wrt func definition
      check_return(func)
      func
    end

    def visitArg arg,args=nil
      set_range(arg)
      puts "range of #{arg.str} is now #{arg.range}"
      arg
    end

    def visitVar var,args=nil
      set_range(var)
      puts "range of #{var.str} is now #{var.range}"
      var
    end

    def set_range decl
      puts "set range #{decl.str}"
      case decl.type.str
      when /[is](\d+)/
        nbits=$1.to_i
        min,max=-2**(nbits-1),+2**(nbits-1)-1
        p decl.range=Interval.new(min,max)
      when /u(\d+)/
        nbits=$1.to_i
        min,max=0,+2**nbits-1
        p decl.range=Interval.new(min,max)
      else
        #raise "ERROR : set range for #{decl.str} NIY"
      end
    end

    def visitConst cst,args=nil
      val=cst.val.tok.val.to_i
      cst.range=Interval.new(val,val)
      cst
    end

    def visitAssign assign,args=nil
      rhs=assign.rhs.accept(self)
      assign.lhs.ref.range=rhs.range # WARNING note the .ref !!!
      puts "range of #{assign.lhs.str} is now #{rhs.range}"
      assign
    end

    def visitReturn ret,args=nil
      ret
    end

    def visitBinary bin,args=nil
      puts "visitBinary #{bin.str}"
      l=bin.lhs.accept(self)
      puts "has range #{l.str} : #{l.range!=nil}"
      o=bin.op
      r=bin.rhs.accept(self)
      puts "has range #{r.str} : #{r.range!=nil}"
      bin.range=compute_range(l.range,o,r.range)
      bin
    end

    def visitIdent ident,args=nil
      ident.ref
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
        var.type=compute_type(var)
      end
    end

    def compute_type var
      puts "compute_range #{var.str}"
      min,max=var.range.min,var.range.max
      type=(min >=0) ? get_unsigned(min,max) : get_signed(min,max)
      NamedType.new(Ident.create(type))
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

    def check_return func
      rets=func.stmts.select{|stmt| stmt.is_a? Return}
      ret=rets.first # WARNING uniq return assumed
      var=ret.expr.ref
      actual_ret_type=compute_type(var)
      if (spec=func.type.str)!=(actual=actual_ret_type.str)
        puts " |--[+] error detect : func '#{func.name.str}' specifies return type '#{spec}' but computed type is '#{actual}'"
        puts " |--[+] fixing return type to #{actual}"
        func.type=actual_ret_type
      end
    end
  end
end
