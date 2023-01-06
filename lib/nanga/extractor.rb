module Nanga
  class Extractor <  CompilerPass
    def run ast
      ast.accept(self)
    end

    def same_control_step?(n1,n2)
      n1.cstep==n2.cstep
    end

    def visitDef func,args=nil
      report 0," |--[+] processing '#{func.name.str}'"
      controler=RTL::Controler.new(func.name.str+"_controler")
      datapath =RTL::Datapath.new(func.name.str+"_datapath")
      csteps_h=func.dfg.nodes.group_by{|node| node.cstep}
      states_h=csteps_h.keys.map{|cstep| [cstep,RTL::State.new]}.to_h
      states_h.values.each{|state| controler << state}
      csteps_h.each do |cstep,nodes|
        wr_state=states_h[cstep]
        report 1,"cstep #{cstep} / state #{wr_state.id}".center(50,'=')
        nodes.each do |node|
          report 1,node.stmt.str.ljust(30,'.')+node.mapping.name
          datapath << rtl_element_e=node.mapping
          node.succs.each_with_index do |succ,idx|
            rtl_element=rtl_element_e #warning : for next iteration
            rd_state=states_h[succ.cstep]
            # if not in same control step, need to interpose a REG. node->REG->succ
            if wr_state!=rd_state
              datapath << reg=node.output_var.mapping
              control = rtl_element.wiring_to(reg)
              # also need supplemental binding node->reg :
              reg.allocated_nodes << node
              wr_state << control
              rtl_element=reg # we prepare the link reg->succ_rtl
            end
            # In case of dyadic op, we need to determine if connexion is left or right
            # Mind that this decision is made upon bhv nodes (not RTL elements).
            if succ.preds.size==2 #dyadic
              case succ.preds.index(node)
              when 0
                left_or_right=:left
              when 1
                left_or_right=:right
              else
                raise "BUG"
              end
            end

            datapath << succ_rtl=succ.mapping
            control = rtl_element.wiring_to(succ_rtl,left_or_right)
            rd_state << control
          end
        end
      end

      controler.states.each do |state|
        report 1,"state #{state.id}".center(40,'=')
        state.controls.each do |control|
          report 1,control
        end
      end

      func.controler=controler
      func.datapath=datapath
      func
    end
  end
end
