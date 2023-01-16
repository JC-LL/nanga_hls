module Nanga
  class DfgScheduler < CompilerPass

    ALGOS={
      asap: AsapScheduling
    }
    
    def visitDef func,algo_name
      report 0," |--[+] processing '#{func.name.str}'"
      inputs=func.dfg.nodes.select{|node| node.is_a?(Arg)}
      algo=ALGOS[algo_name]
      raise "ERROR : unknown algorithme named '#{algo_name}'" unless algo
      inputs.each{|node| algo.schedule_at(node,0)}
      fix_constant_scheduling(func)
      display_scheduling(func)
      func.body=generate_body(func)
      func
    end

    def fix_constant_scheduling func
      func.dfg.nodes.select{|node| node.is_a? Const}.each do |cst|
        cst.cstep=cst.succs.min_by{|node| node.cstep}.cstep
      end
    end

    def display_scheduling func
      schedule=func.dfg.nodes.group_by{|node| node.cstep}
      for cstep in 0..schedule.keys.max
        report 1,"cstep #{cstep}".center(40,'=')
        schedule[cstep].each do |node|
          report 1,node.str
        end
      end
    end

    def generate_body func
      ret=Body.new(stmts=[])
      schedule=func.dfg.nodes.group_by{|node| node.cstep}
      for cstep_id in 0..schedule.keys.max
        nodes=schedule[cstep_id]
        nodes.reject!{|stmt| stmt.is_a? Const}
        cstep_stmts=nodes.map do |node|
          case node
          when Binary, Unary, Ident, IntLit
            assigned_var=func.symtable.get(node.output.name)
            vname=assigned_var.name
            Assign.new(vname,node)
          else
            node
          end
        end
        cstep_body=Body.new(cstep_stmts)
        stmts << Cstep.new(IntLit.create(cstep_id),cstep_body)
      end
      ret
    end
  end
end
