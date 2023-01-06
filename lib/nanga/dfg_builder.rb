module Nanga
  class DfgGen < Visitor
    def visitDef func,args=nil
      puts " |--[+] processing '#{func.name.str}'"
      func.dfg=collecting(func)
      #linking(func.dfg)
      walk_and_link(func.dfg)
      func
    end

    def collecting func
      dfg=Dfg.new
      func.args.each{|arg|    dfg << InputNode.new(arg)}
      func.consts.each{|const|dfg << ConstNode.new(const)}
      func.stmts.each do |stmt|
        case stmt
        when Assign
          dfg << ComputeNode.new(stmt)
        when Return
          dfg << OutputNode.new(stmt)
        end
      end
      dfg
    end

    # here we walk nodes (created in stmt order) and build a sequential state of producers.
    # AND link producers to current visited.
    # this "walk and link" process, allows to handle several assignements to a same variable during
    # this DFG construction
    def walk_and_link dfg
      producers={}
      dfg.nodes.each do |node|
        case arg=assign=const=ret=node.stmt
        when Arg,Const
          producers[arg.name.str]=node
        when Assign
          producers[assign.lhs.str]=node
        end
        get_operands(node).each do |operand|
          producer=producers[operand.str] # operand is a Ident
          producer.signature[:out]=operand.ref.type.str.to_sym
          node.signature[:in] << operand.ref.type.str.to_sym
          raise "ERROR : no producer for '#{operand.str}" if producer.nil?
          producer.to(node)
        end
      end
    end

    def get_operands node
      operands=[]
      case arg=const=ret=assign=node.stmt
      when Assign
        operands << get_dependencies(assign.rhs)
      when Return
        operands << get_dependencies(ret.expr)
      end
      return operands.flatten
    end

    def get_dependencies expr
      ret=[]
      case bin=unary=ident=expr
      when Ident
        ret << ident
      when Binary
        ret << get_dependencies(bin.lhs)
        ret << get_dependencies(bin.rhs)
      when Unary
        ret << get_dependencies(unary.expr)
      end
      ret.flatten
    end

    def get_ident expr
      expr
    end

  end
end
