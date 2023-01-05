module Nanga

  class Dfg
    attr_accessor :nodes
    def initialize nodes=[]
      @nodes=nodes
    end

    def <<(o)
      @nodes << o
    end

    def each(&block)
      @nodes.each(&block)
    end

    def inputs
      @inputs||=@nodes.select{|node| node.stmt.is_a?(Arg)}
    end
  end

  class Node
    attr_accessor :stmt,:inputs,:outputs
    attr_accessor :output_var
    attr_accessor :cstep
    attr_accessor :mapping
    attr_accessor :signature

    def initialize stmt
      @stmt=stmt
      @inputs=[]
      @outputs=[]
      @signature={in:[],out:nil}
      case stmt
      when Arg
        @output_var=stmt
      when Assign
        @output_var=stmt.lhs.ref
      end
    end

    def to node
      @outputs << node
      node.inputs << self
    end

    alias :succs :outputs
    alias :preds :inputs

    def op
      case assign=stmt
      when Assign
        lhs,rhs=assign.lhs,assign.rhs
        rhs.op
      end
    end
  end

  class InputNode < Node
  end

  class OutputNode < Node
  end

  class ComputeNode  < Node
  end

  class ConstNode  < Node
  end

  class MemReadNode < Node
  end

  class MemWriteNode < Node
  end

end
