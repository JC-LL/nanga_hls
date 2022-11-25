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
    def initialize stmt
      @stmt=stmt
      @inputs=[]
      @outputs=[]
    end

    def to node
      @outputs << node
      node.inputs << self
    end
  end

  class Input < Node
  end

  class Output < Node
  end

  class ComputeNode  < Node
  end

  class ConstNode  < Node
  end

  class MemRead < Node
  end

  class MemWrite < Node
  end

end
