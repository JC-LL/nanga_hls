module Nanga
  # ASAP recursive schedule *WITHOUT* Resource constraints.
  class AsapScheduling < CompilerPass  
    def self.schedule_at node,cstep
      if old_cstep=node.cstep and old_cstep!=cstep
        node.cstep=[old_cstep,cstep].max
        "node #{node} (#{node.str}) rescheduled at #{node.cstep}"
      else
        node.cstep=cstep
        "node #{node} (#{node.str}) scheduled at #{node.cstep}"
      end
      node.succs.each{|succ| schedule_at(succ,cstep+1)}
    end
  end
end
