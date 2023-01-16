module Nanga
  module RTL
    class Extractor <  CompilerPass
      
      def run ast
        ast.accept(self)
      end

      def same_control_step?(n1,n2)
        n1.cstep==n2.cstep
      end

      def visitDef func,args=nil
        report 0," |--[+] processing '#{func.name.str}'"
        @controler=RTL::Controler.new
        @datapath =RTL::Datapath.new(func)
        init_sig()
        csteps_h=func.dfg.nodes.group_by{|node| node.cstep}
        states_h=csteps_h.keys.map{|cstep| [cstep,RTL::State.new]}.to_h
        states_h.values.each{|state| @controler << state}
        func.dfg.edges.each do |edge|
          puts "-"*50
          puts "processing edge #{edge}"
          puts "-"*50
          var=edge.var
          bhv_port_src=edge.source
          bhv_port_dst=edge.sink
          bhv_node_src=bhv_port_src.node
          #hit_a_key "bhv_node_src : #{bhv_node_src.class}"
          bhv_node_dst=bhv_port_dst.node
          cstep_node_src=bhv_node_src.cstep
          cstep_node_dst=bhv_node_dst.cstep
          #--
          rtl_node_src=bhv_node_src.mapping
          rtl_port_src=rtl_node_src.output
          rtl_node_dst=bhv_node_dst.mapping
          #rtl_port_dst=rtl_node_dst.output
          @datapath << rtl_node_src
          @datapath << rtl_node_dst
          if (var.is_a?(Var) or var.is_a?(Arg)) and reg=clocked?(var)
            puts "clocked #{var} in reg #{reg}"
            @datapath << reg
            @datapath << reg.mux
            control=build_transfer(rtl_port_src,reg.mux)
            states_h[cstep_node_src] << control
            # From now on, source is the Register itself :
            rtl_node_src=reg
            rtl_port_src=reg.output
          end

          case rtl_node_dst
          when FunctionalUnit #dyadic
            #position left/right :
            index=bhv_node_dst.inputs.index(bhv_port_dst)
            ##hit_a_key "index=#{index}"
            lr_position=index==0 ? :left : :right
            mux=rtl_node_dst.mux[lr_position]
            @datapath <<  mux
            ##hit_a_key "mux=#{mux}"
            control=build_transfer(rtl_port_src,mux)

            states_h[cstep_node_dst] << control
          when Output
            sig=next_sig(rtl_port_src.type)
            port=rtl_node_dst.get_input(0)
            rtl_port_src.to port
          else
            raise "NIY #{rtl_node_dst}"
          end
        end

        @controler.states.each do |state|
          report 1,"state #{state.id}".center(40,'=')
          state.controls.each do |control|
            report 1,control
          end
        end

        @datapath.print
        func.controler=@controler
        func.datapath=@datapath
        func
      end

      def clocked? var
        if (reg=var.register).is_a? RTL::Reg
          return reg
        end
      end

      def build_transfer src,mux
        #hit_a_key "building transfer for source #{src.name} to mux #{mux}"

        # find the index of the mux input port, if exists, that 
        # is already driven by src port
        if index=mux.inputs.index{|input| input.fanin==src}
          #index+=1 # mux command 0 is reserved.
          puts "found! index=#{index}"
          return RTL::Control.new(mux,index)
        else
          #index=mux.size+1
          index=mux.size
          new_input_name="i"+index.to_s
          new_input=Dataflow::Port.new(mux,new_input_name)
          mux.inputs << new_input
          src.to new_input
          return RTL::Control.new(mux,index)
        end
      end

      def init_sig
        @sig=-1
      end

      def next_sig type
        @sig+=1
        Var.new(Ident.create("sig_#{@sig}"),type)
      end
    end
  end
end
