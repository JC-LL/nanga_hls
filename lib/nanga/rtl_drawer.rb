module Nanga

  class RTL::Drawer < Visitor

    def visitDef func,args=nil
      draw_datapath(func)
      draw_controler(func)
      func # warning : must be returned. Awkward.
    end

    def declare node
      code=Code.new
      inputs=node.inputs.map{|port| "<#{port.name}>#{port.name}"}.join("|")
      output="<#{str=node.output.name}>#{str}" if node.output
      fanin="{#{inputs}}"
      fanout="{#{output}}"
      label="{#{fanin}| #{node.name} |#{fanout}}"
      code << "#{node.object_id}[shape=record; style=filled;color=cadetblue; label=\"#{label}\"] //#{node.class}"
      code
    end

    def draw_datapath func
      code=Code.new
      code << "digraph G {"
      code.indent=2
      func.datapath.nodes.each{|node| code << declare(node)}

      # func.datapath.nodes.each do |node|
      #   port_src=node.output
      #   node.output.fanout.each do |port_dest|
      #     code << "#{node.object_id}:#{port_src.name} -> #{(dest=port_dest.node).object_id}:#{port_dest.name}[label=\"#{port_src.name}\"]"
      #   end
      # end
      func.datapath.edges.each do |edge|
        #var=edge.var
        port_src=edge.source
        node_src=port_src.node
        port_dst=edge.sink
        node_dst=port_dst.node
        code << "#{node_src.object_id}:#{port_src.name} -> #{node_dst.object_id}:#{port_dst.name}[label=\"#{edge.var}\"]"
      end

      code.indent=0
      code << "}"
      filename=code.save_as("#{func.name.str}_datapath.dot")
      puts " |--[+] generated : '#{filename}'"
      func
    end

    def draw_controler func
    end
  end
end
