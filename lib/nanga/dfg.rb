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
  end

  class Node
    attr_accessor :stmt,:inputs,:outputs
    attr_accessor :cstep
    attr_accessor :mapping

    def initialize stmt
      @stmt=stmt
      @inputs=[]
      @outputs=[]
    end

    def to node
      @outputs << node
      node.inputs << self
    end

    alias :succs :outputs
    alias :preds :inputs
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
