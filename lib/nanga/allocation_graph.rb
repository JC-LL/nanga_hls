module Nanga
  module Allocation
    class Graph
      attr_accessor :name,:nodes
      def initialize name
        @name=name
        @nodes=[]
      end

      def << node
        @nodes << node
      end

      def size
        @nodes.size
      end

      def connect n1,n2
        n1.neighbors << n2
        n2.neighbors << n1
        n1.neighbors.uniq!
        n2.neighbors.uniq!
      end

      def edge_pairs
        pairs=[]
        @nodes.each do |node|
          node.neighbors.each do |neighbor|
            unless pairs.include?([node,neighbor]) or pairs.include?([neighbor,node])
              pairs << [node,neighbor]
            end
          end
        end
        pairs
      end

      def gen_dot
        code=Code.new
        code << "graph {"
        code.indent=2
        pairs=[]
        edge_pairs.each do |n1,n2|
          code << "#{n1.name} -- #{n2.name}"
        end
        code.indent=0
        code << "}"
        code.save_as("#{name}.dot",verbose=true)
      end
    end

    class Node
      attr_accessor :name
      attr_accessor :neighbors
      attr_accessor :content
      def initialize name
        @name=name
        @neighbors=[]
        @content=[]
      end

      def inspect
        name
      end
    end
  end
end
