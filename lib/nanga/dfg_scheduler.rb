module Nanga
  class DfgScheduler < Visitor

    def visitDef func,algo_name
      inputs=func.dfg.nodes.select{|node| node.is_a?(InputNode)}
      case algo_name
      when :asap
        algo=AsapScheduling #class!
      else
        raise "unknown algorithme named '#{algo_name}'"
      end

      inputs.each{|node| algo.schedule_at(node,0)}
      fix_constant_scheduling(func.dfg)
      display_scheduling(func.dfg)
      func
    end

    def fix_constant_scheduling dfg
      dfg.nodes.select{|node| node.is_a? ConstNode}.each do |cst|
        cst.cstep=cst.succs.first.cstep
      end
    end

    def display_scheduling dfg
      schedule=dfg.nodes.group_by{|node| node.cstep}
      for cstep in 0..schedule.keys.max
        puts "cstep #{cstep}".center(40,'=')
        schedule[cstep].each do |node|
          puts node.stmt.str
        end
      end
    end
  end
end
