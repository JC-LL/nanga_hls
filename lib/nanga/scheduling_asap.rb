module Nanga
  class AsapScheduling
    # ASAP recursive schedule *WITHOUT* Resource constraints.
    def self.schedule_at node,cstep
      if old_cstep=node.cstep and old_cstep!=cstep
        node.cstep=[old_cstep,cstep].max
        puts "node #{node} (#{node.str}) rescheduled at #{node.cstep}"
      else
        node.cstep=cstep
        puts "node #{node} (#{node.str}) scheduled at #{node.cstep}"
      end
      node.succs.each{|succ| schedule_at(succ,cstep+1)}
    end
  end
end
