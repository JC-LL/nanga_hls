module Nanga
  module Dataflow
    #=================== dataflow concepts ===============
    # Some AST nodes will inherit from Node class
    class Port
      attr_accessor :node
      attr_accessor :name,:type
      attr_accessor :fanout,:fanin
      def initialize node,name
        @node=node
        @name=name
        @type=nil
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
      attr_accessor :graph
      def initialize input_port_names=[],output_port_name="?"
        @inputs=input_port_names.map{|name| Port.new(self,name)}
        @output=Port.new(self,output_port_name) if output_port_name
      end

      def get_input id
        @inputs[id]
      end

      def succs
        if @output
          return @output.fanout.map{|p_dest| p_dest.node}
        else
          []
        end
      end

      def signature
        respond_to?(:op) ? op : self.class.to_s.split('::').last.downcase.to_sym
      end
    end

    class Edge
      attr_accessor :source,:sink
      attr_accessor :var
      def initialize src,dest,var
        @source,@sink,@var=src,dest,var
      end

      def to_s
        vname=var.respond_to?(:name) ? var.name.str : var
        "[#{source.node}] ---#{vname}--> [#{sink.node}]"
      end
    end

    class Graph
      attr_accessor :nodes
      def initialize func
        @nodes=[]
        @edges=nil
        @func=func
      end

      def <<(node)
        unless @nodes.include?(node)
          puts "#{self} : adding #{node}"
          @nodes << node
          node.graph=self
        end
      end

      def each(&block)
        @nodes.each(&block)
      end

      def include?(e)
        @nodes.include?(e)
      end

      def print
        puts "print dataflow graph".center(40,'=')
        edges.each do |edge|
          var=edge.var
          p_src=edge.source
          n_src=p_src.node
          p_dst=edge.sink
          n_dst=p_dst.node
          puts "#{n_src.class}#{n_src.object_id}:#{p_src.name} ---#{}---> #{n_dst.class}#{n_dst.object_id}:#{p_dst.name}"
        end
      end

      def edges
        return @edges if @edges
        @edges=[]
        nodes_with_output=nodes.reject{|node| node.output.nil?}
        nodes_with_output.each do |node|
          node.output.fanout.each do |dst|
            var=@func.symtable.get(node.output.name)
            @edges << Edge.new(node.output,dst,var)
          end
        end
        @edges
      end
      # def connect src,dst,var
      #   puts "connect #{src.name}--#{var.name.str}-->#{dst.name}"
      #   src.to dst
      #   @edges << Edge.new(src,dst,var)
      # end
    end

    class BehavioralNode < Node
      attr_accessor :cstep
      attr_accessor :mapping
      def initialize input_port_names=[],output_port_name
        super(input_port_names,output_port_name)
      end
    end
  end
end
