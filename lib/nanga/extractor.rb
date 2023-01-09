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
        prod_state=states_h[cstep]
        report 0,"cstep #{cstep} / state #{prod_state.id}".center(50,'=')
        nodes.each do |node|
          report 0,node.stmt.str.ljust(30,'.')+node.mapping.name
          datapath << rtl_element_e=node.mapping
          node.succs.each do |succ|
            rtl_element=rtl_element_e #warning : copy needed for next iteration
            cons_state=states_h[succ.cstep]
            # if not in same control step, need to interpose a REG. node->REG->succ
            if prod_state!=cons_state
              datapath << reg=node.output_var.mapping
              control = rtl_element.wiring_to(reg)
              puts "state_#{prod_state.id}: control for #{rtl_element.name}->#{reg.name} is #{control.to_s}"
              # also need supplemental binding node->reg :
              reg.allocated_nodes << node
              prod_state << control
              rtl_element=reg # we prepare the link reg->succ_rtl
            end
            # In case of dyadic op, we need to determine if connexion is left or right
            # Mind that this decision is made upon bhv nodes (not RTL elements).
            if succ.preds.size==2 #dyadic
              # A naive idea is to determine l/r with the succ.preds.index(n).
              # That works for general case : n1-->([l]n3) AND n2-->([r]n3), that is
              # two different nodes n1 and n2 pointing to n3.
              # BUT this causes troubles for a special case n1-->([l]n2) AND n1-->([r]n2),
              # that is a node n1 pointing twice to a second node n2.
              # Here : preds(n2)=[n1,n1] and a simple index retreiving will always
              # give 0, which would cause a bug as 0 is meant for left (1 for right).
              # To solve this, I detect that all succ.preds are identical and connect
              # all succs (left and right) in a single step.
              if succ.preds.first!=succ.preds.last
                case succ.preds.index(node) #general case works
                when 0
                  left_or_right=:left
                when 1
                  left_or_right=:right
                else
                  raise "BUG idx=#{idx}"
                end
                datapath << succ_rtl=succ.mapping
                control = rtl_element.wiring_to(succ_rtl,left_or_right)
                puts "state_#{cons_state.id}: control for #{rtl_element.name}->#{succ_rtl.name} is #{control.to_s}"
                cons_state << control
              else # all succ.preds are indentical n1-->([l]n2) AND n1-->([r]n2)
                datapath << succ_rtl=succ.mapping
                control = rtl_element.wiring_to(succ_rtl,:left)
                puts "state_#{cons_state.id}: control for #{rtl_element.name}->[left]#{succ_rtl.name} is #{control.to_s}"
                cons_state << control
                control = rtl_element.wiring_to(succ_rtl,:right)
                puts "state_#{cons_state.id}: control for #{rtl_element.name}->[right]#{succ_rtl.name} is #{control.to_s}"
                cons_state << control
              end
            else
              datapath << succ_rtl=succ.mapping
              control = rtl_element.wiring_to(succ_rtl,nil)
              puts "state_#{cons_state.id}: control for #{rtl_element.name}->#{succ_rtl.name} is #{control.to_s}"
              cons_state << control
            end
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
