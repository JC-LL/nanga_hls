module Nanga
  class DfgPrinter < Visitor

    COLORS={
      InputNode => "green",
      OutputNode => "green",
      ComputeNode => "cyan",
    }
    def color_of node
      case node
      when InputNode,OutputNode
          "green"
      when ComputeNode
        case node.stmt.rhs.op
        when :add,:sub
          "cyan"
        when :mul
          "orange"
        else
          "red"
        end
      when ConstNode
        "white"
      else
        raise "NIY #{node}"
      end
    end

    def sig_name node
      case node
      when InputNode
        node.stmt.name.tok.val
      when OutputNode
        node.stmt.expr.tok.val
      when ComputeNode
        node.stmt.lhs.tok.val
      when ConstNode
        node.stmt.name.tok.val
      else
        raise "NIY #{node}"
      end
    end

    def label_of node
      case node
      when InputNode
        "?"+sig_name(node)
      when OutputNode
        "!"+sig_name(node)
      when ComputeNode
        OP2STR[node.stmt.rhs.op]
      when ConstNode
        node.stmt.val.str
      else
        raise "NIY #{node}"
      end
    end

    def visitDef func,args=nil
      code=Code.new
      code << "digraph G {"
      code.indent=2
      func.dfg.each do |node|
        code << "#{node.object_id} [shape=circle, style=filled, fillcolor=#{color_of(node)}, label=\"#{label_of(node)}\"];"
      end
      func.dfg.each do |node|
        node.inputs.each do |input|
          name=sig_name(input)
          code << "#{input.object_id} -> #{node.object_id} [label=\"#{name}\"]"
        end
      end
      code.indent=0
      code << "}"
      filename=code.save_as("#{func.name.str}.dot")
      puts " |--[+] #{filename}"
      func
    end
  end
end
