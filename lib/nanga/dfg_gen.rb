module Nanga
  class DfgGen < Visitor
    def visitDef func,args=nil
      puts " |--[+] dfg for '#{func.name.str}'"
      func.dfg=collecting(func)
      linking(func.dfg)
      func
    end

    def collecting func
      dfg=Dfg.new
      func.args.each{|arg|    dfg << Input.new(arg)}
      func.consts.each{|const|dfg << ConstNode.new(const)}
      func.stmts.each do |stmt|
        case stmt
        when Assign
          dfg << ComputeNode.new(stmt)
        when Return
          dfg << Output.new(stmt)
        end
      end
      dfg
    end

    def linking dfg
      producers=collect_producers(dfg)
      dfg.nodes.each do |consumer|
        get_operands(consumer).each do |operand|
          producer=producers[operand.str] # operand is a Ident
          raise "ERROR : no producer for '#{operand.str}" if producer.nil?
          producer.to(consumer)
        end
      end
    end

    def collect_producers dfg
      producers={}
      dfg.nodes.each do |node|
        case arg=assign=const=ret=node.stmt
        when Arg,Const
          producers[arg.name.str]=node
        when Assign
          producers[assign.lhs.str]=node
        end
      end
      producers
    end

    def get_operands node
      operands=[]
      case arg=const=ret=assign=node.stmt
      when Assign
        case binary=unary=ident=assign.rhs
        when Binary
          operands << binary.lhs
          operands << binary.rhs
        when Unary
          operands << unary.expr
        when Ident
          operands << ident
        end
      when Return
          operands << ret.expr
      end
      return operands.select{|arg| arg.is_a?(Ident)}
    end

  end
end
