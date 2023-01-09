class Port
  attr_accessor :node
  attr_accessor :name
  attr_accessor :fanout,:fanin
  def initialize node,name
    @node=node
    @name=name
    puts "creating port #{full_name}"
    @fanout,@fanin=[],nil
  end

  def full_name
    "#{node}.#{name}"
  end

  def rename new_name
    old_name=full_name
    @name=new_name
    puts "renaming #{old_name} to #{full_name}"
  end

  def to port
    puts "connecting #{self.full_name} --> #{port.full_name}"
    @fanout << port
    port.fanin=self
  end
end

# nodes DONT HAVE a *name*
# nodes HAVE *PORTS*
class Node
  attr_accessor :inputs,:output
  def initialize input_port_names=[],output_port_name
    @inputs=input_port_names.map{|name| Port.new(self,name)}
    @output=Port.new(self,output_port_name)
  end

  def get_input id
    @inputs[id]
  end

  def succs
    @output.fanout.map{|p_dest| p_dest.component}
  end

end

class Dfg
  attr_accessor :nodes
  def initialize
    @nodes=[]
  end

  def <<(e)
    @nodes << e
  end
end

class Func
  attr_accessor :name,:args,:body
  def initialize name,args,decls,body
    @name=name
    @args=args
    @decls=decls
    @body=body
  end
end

class Arg < Node
  attr_accessor :name
  def initialize name
    super([],name) # creates Node output.
    @name=name
  end
end

class Var < Node
  attr_accessor :name
  def initialize name
    super([],name) # creates Node output.
    @name=name
  end

  def Var.create s
    Var.new(Ident.create s)
  end
end

class Body
  attr_accessor :stmts
  def initialize stmts_v
    @stmts=stmts_v
  end
end

class Assign
  attr_accessor :lhs,:rhs
  def initialize lhs,rhs
    @lhs,@rhs=lhs,rhs
  end
end

class Ret
  attr_accessor :expr
  def initialize expr
    @expr=expr
  end
end

class Expr < Node
  def initialize nb
    input_port_names=nb.times.map{|i| "i#{i}"}
    output_port_name="o"
    super(input_port_names,output_port_name)
  end
end

class Binary < Expr
  attr_accessor :lhs,:op,:rhs
  def initialize lhs,op,rhs
    super(2)
    @lhs,@op,@rhs=lhs,op,rhs
  end
end

class Unary < Expr
  attr_accessor :op,:expr
  def initialize op,rhs
    super(1)
    @op,@expr=op,rhs
  end
end

class Ident
  attr_accessor :name
  def initialize name
    @name=name
  end

  def to_s
    @name
  end

  def Ident.create s
    Ident.new(s)
  end
end

class IntLit < Node
  attr_accessor :value
  def initialize val
    super([],"cst_#{val}") #create Node output
    @value=val
  end
end

class DfgBuilder
  def build func
    puts "building dfg for '#{func.name}'"
    @producers=collect_producers(func)
    dfg=connect(func)
  end

  def collect_producers func
    puts "collecting producers for '#{func.name}'"
    @producers={}
    [func.args,func.body.stmts].flatten.each do |stmt|
      case arg=assign=ret=stmt
      when Arg
        @producers[arg.name.to_s]=arg.output
      when Assign
        @producers[str=assign.lhs.name.to_s]=assign.rhs.output
        assign.rhs.output.rename(str)
      end
    end
    @producers.each do |str,port|
      puts "#{port.full_name} --#{str}-->"
    end
  end

  def connect func
    dfg=Dfg.new
    func.body.stmts.each do |stmt|
      case ret=assign=stmt
      when Assign
        case binary=unary=var=lit=assign.rhs
        when Binary
          lhs_port=@producers[binary.lhs.to_s] || binary.lhs.output
          rhs_port=@producers[binary.rhs.to_s] || binary.rhs.output
          lhs_port.to bin_input=binary.get_input(0)
          bin_input.rename(lhs_port.name)
          rhs_port.to bin_input=binary.get_input(1)
          bin_input.rename(rhs_port.name)
        when Unary
          e=@producers[unary.expr.to_s] || unary.expr.output
          e.to unary.get_input(0)
        when Var
          # ?
        when IntLit
          # ?
        else
          raise "NIY : #{assign.rhs.class}"
        end
      when Ret
      end
    end
  end
end

# func f(x,y){
#  var t1;
#  var t2;
#  t1=x+y
#  t2=x*2
#  $1=t2-t1
#  return $1
# }

func=Func.new(Ident.new("f"),[x=Arg.new("x"),y=Arg.new("y")],
  [ t1=Var.new("t1"),
    t2=Var.new("t2"),
    t3=Var.new("t3"),
    t4=Var.new("t4"),
    tp=Var.new("$1"),
  ],
  Body.new([
    Assign.new(t1,Binary.new(x,:+,y)),
    Assign.new(t2,Binary.new(x,:*,IntLit.new(2))),
    Assign.new(t3,Unary.new(:-,IntLit.new(42))),
    Assign.new(t4,t3),
    Assign.new(tp,Binary.new(t2,:-,t1)),
    Ret.new(tp)]
  )
)

DfgBuilder.new().build(func)
