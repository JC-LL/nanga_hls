module Nanga
  class DfgAllocator < CompilerPass

    # fu : functional unit.
    # story :
    # 0) We suppose that only computing FU need to be shared (not IO nor Const)
    # 1) node signatures has been performed by DFG builder
    # 2) we extract the maximum number of bits characterizing the whole architecture.

    def visitDef func,args=nil
      report 0," |--[+] processing '#{func.name.str}'"
      func.dfg.nodes.sort_by!{|node| node.cstep}
      func.dim=find_single_dim(func)
      init_resource_allocation(func)
      func.dfg.nodes.each do |node|
        fu=get_an_available_fu_in_cstep(node)
        #bind node and FU
        bind_to(node,fu)
      end
      # report Allocation :
      func.dfg.nodes.each do |node|
        report 0,"binding node #{node} to #{node.mapping}"
      end

      register_allocation(func)

      func
    end

    def init_resource_allocation func
      report 1,"|--[+] initializing resource allocation for '#{func.name.str}'"
      @functional_units=[] #declared FUs
      csteps=func.dfg.nodes.collect{|node| node.cstep}.uniq
      @max_cstep=csteps.max
      @availability=csteps.map{|cstep| [cstep,[]]}.to_h
    end

    def get_an_available_fu_in_cstep node
      report 1,"fu for #{node.str}"
      cstep=node.cstep
      # search
      puts "searching #{node.signature}"
      if fu=@availability[cstep].find{|unit| unit.signature==node.signature}
        @availability[cstep].delete fu
        return fu
      else
        puts "no FU found for #{node.str} in cstep #{cstep}"
        # allocate
        new_fu=allocation_for(node)
        # makes fu available for next cteps :
        (cstep+1..@max_cstep).each{|cstep_| @availability[cstep_] << new_fu unless new_fu.is_a?(RTL::Const)}
        return new_fu
      end
    end

    def allocation_for node
      report 1,"allocation for node #{node.class} (#{node.str})"
      # creates a FU with same i/o types
      case node
      when Arg
        ret=RTL::Input.new(node.name.str)
      when Return
        ret=RTL::Output.new(node.get_input(0).name)
      when Binary
        case node.op
        when :add
          ret=RTL::Add.new
        when :sub
          ret=RTL::Sub.new
        when :mul
          ret=RTL::Mul.new
        when :div
          ret=RTL::Div.new
        else
          raise "NIY : #{node.op}"
        end
      when Unary
        raise "NIY : #{node.op}"
      when Const
        ret=RTL::Const.new(node.val)
      else
        raise "BUG during allocation : #{node.class} NIY"
      end
      copy_signature(node,ret)
      ret
    end

    def copy_signature node,fu
      report 1,"copy signature #{node} #{fu}"
      node.inputs.each_with_index{|input,i| fu.get_input(i).type=input.type}
      fu.output.type=node.output.type if node.output
    end

    def find_single_dim(func)
      type_names=func.dfg.edges.collect{|edge| edge.var.type}.map{|type| type.str}.uniq
      if type_names.all?{|name| name.match(/[us]\d+/)}
        max_bits=type_names.map{|name| name.match(/[us](\d+)/)[1].to_i}.max
        report 1,"     |--[+] required minimal architecture : #{@max_bits} bits"
        if all_unsigned=type_names.all?{|name| name.match(/u\d+/)}
          @max_type=NamedType.create "u#{@max_bits}"
          report 1,"     |--[+] optimal type : #{@max_type.str}"
        else
          @max_type=NamedType.create "s#{@max_bits}"
          report 1,"     |--[+] optimal type : #{@max_type.str}"
        end
      else
        report 1,"     |--[+] cannot determine #bits for this program."
      end
      return max_bits
    end

    def bind_to node,fu
      fu << node
      node.mapping=fu
    end

    #lifetime[v] is an array of disjoint life_segments h={:birth=> cstep, :death=>cstep'}
    def compute_lifetimes func
      report 1,"compute variables lifetimes"
      lifetime={}
      # edges can convey : Arg, Var, Const
      func.dfg.edges.reject{|edge| edge.var.is_a?(Const)}.each do |edge|
        report 2, "processing edge #{edge.to_s}"
        var=edge.var
        lifetime[var]||=[]
        life_segment={}
        life_segment[:birth]=edge.source.node.cstep
        life_segment[:death]=edge.sink.node.cstep
        report 2,"lifetime of #{var.name.str} : ...#{life_segment}"
        lifetime[var] << life_segment if life_segment[:birth]!=life_segment[:death]
      end

      # for display :
      max_cstep=lifetime.collect{|var,life_segments| life_segments.map{|ls| ls[:death]}}.flatten.max

      lifetime.each do |var,life_segments|
        life_line=("-"*(max_cstep+1)).chars
        life_segments.each do |life_segment_h|
          birth=life_segment_h[:birth]
          life_line[birth]="["
          death=life_segment_h[:death]
          life_line[death]="]" unless life_line[death]=="="
          for cstep in birth+1..death-1
            life_line[cstep]="="
          end
        end
        report 0,"#{var.name.str.rjust(10)} : #{life_line.join}"
      end
      return lifetime
    end

    def register_allocation func
      report 1," [+] register allocation"
      lifetime=compute_lifetimes(func)
      graph=build_compatibility_graph(lifetime)
      graph=clique_partitioning(graph)
      graph.nodes.each_with_index do |clique,idx|
        reg_type=clique.content.first.type
        reg=RTL::Reg.new(reg_type)
        clique.content.each do |var|
          var.register=reg
          report 0,"mapping [#{var.class}]#{var.name.str} to register #{reg.id}"
        end
      end
    end

    def build_compatibility_graph lifetime
      report 1,"building compatibility graph"
      graph=Allocation::Graph.new("alloc")
      nodes_h={}
      lifetime.keys.each do |var|
        graph << n1=Allocation::Node.new(var.name.str)
        n1.content << var
        nodes_h[var]=n1
      end
      for v1 in lifetime.keys
        n1=nodes_h[v1]
        for v2 in lifetime.keys
          unless v1==v2
            n2=nodes_h[v2]
            unless overlap?(lifetime[v1],lifetime[v2])
              graph.connect n1,n2
            end
          end
        end
      end
      graph
    end

    def overlap? segments_1,segments_2
      rg1=segments_1.map{|h| h[:birth]..h[:death]-1}.map(&:to_a).flatten
      rg2=segments_2.map{|h| h[:birth]..h[:death]-1}.map(&:to_a).flatten
      rg1.intersection(rg2).any?
    end

    def clique_partitioning graph
      report 1,"clique partitioning"
      algo=Allocation::TsengSiework.new
      result=algo.apply_to(graph)
    end

  end
end
