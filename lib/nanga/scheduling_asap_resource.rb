module Nanga
  class AsapResourceScheduling

    # N I Y !!!

    # ASAP with Resource constraints
    def self.schedule_at node,cstep
      if old_cstep=node.cstep
        node.cstep=[old_cstep,cstep].max
      else
        node.cstep=cstep
      end
      node.succs.each{|succ| schedule_at(succ,cstep+1)}
    end
  end
end
