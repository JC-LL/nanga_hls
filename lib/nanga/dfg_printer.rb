module Nanga

  class DfgPrinter < Visitor

    def visitDef func,args=nil
      code=Code.new
      code << "digraph G {"
      code.indent=2
      func.dfg.nodes.each{|node| code << declare(node)}

      func.dfg.nodes.each do |node|
        port_src=node.output
        unless node.output.nil?
          node.output.fanout.each do |port_dest|
            code << "#{node.object_id}:#{port_src.name} -> #{(dest=port_dest.node).object_id}:#{port_dest.name}[label=\"#{port_src.name}\"]"
          end
        end
      end
      code.indent=0
      code << "}"
      filename=code.save_as("#{func.name.str}.dot")
      #puts code.finalize
      puts " |--[+] generated : '#{filename}'"
      func
    end

    def declare node
      code=Code.new
      inputs=node.inputs.map{|port| "<#{port.name}>#{port.name}"}.join("|")
      output="<#{str=node.output.name}>#{str}" if node.output
      fanin="{#{inputs}}"
      fanout="|{#{output}}"
      label="{#{fanin}| #{node.str}#{fanout}}"
      code << "#{node.object_id}[shape=record; style=filled;color=cadetblue; label=\"#{label}\"]"
      code
    end
  end
end
