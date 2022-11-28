module Nanga
  class AsapScheduling

    # ASAP recursive schedule *WITHOUT* Resource constraints.
    def self.schedule_at node,cstep
      if old_cstep=node.cstep
        node.cstep=[old_cstep,cstep].max
      else
        node.cstep=cstep
      end
      #puts "node #{node.stmt.str} scheduled at #{node.cstep}"
      node.succs.each{|succ| schedule_at(succ,cstep+1)}
    end
  end
end
