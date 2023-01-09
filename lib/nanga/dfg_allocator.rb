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
      @functional_units=[] #declared FUs
      func.dfg.nodes.each do |node|
        fu=get_available_fu(node)
        # bind node and FU
        bind_to(node,fu)
        # now glue this FU to its *binary* operator :
        if (assign=node.stmt).is_a?(Assign) and (bin=assign.rhs).is_a?(Binary)
          bin.mapping=fu
        end
      end
      # report Allocation :
      func.dfg.nodes.each do |node|
        report 0,"binding node #{node} to #{node.mapping.name}"
      end

      register_allocation(func)

      func
    end

    def find_single_dim(func)
      comp_nodes=func.dfg.nodes.select{|n| n.is_a? ComputeNode}
      signatures={}
      comp_nodes.each do |node|
        signatures[node.op]||=[]
        signatures[node.op] << {node.signature[:in] => node.signature[:out]}
      end
      maxbits=0
      signatures.each do |op_kind,op_signatures|
        op_signatures.each do |op_sig_h|
          ary=op_sig_h.first.flatten
          nbits=ary.map{|type| type.to_s.match(/(\d+)/)[1]}.map(&:to_i).max
          maxbits=nbits if nbits > maxbits
        end
      end
      report 1,"     |--[+] required minimal architecture : #{maxbits} bits"
      maxbits
    end

    def get_available_fu node
      @table||={}
      # init list of FU AVAILABLE in this cstep :
      #   warn : dont forget to clone (otherwise?)
      @table[node.cstep]||=@functional_units.clone
      case node
      when InputNode
        fu=RTL::Input.new(@dim)
      when OutputNode
        fu=RTL::Output.new(@dim)
      when ComputeNode
        compute_units=@table[node.cstep].select{|fu| fu.is_a? RTL::Compute}
        if fu=compute_units.find{|fu| fu.op==node.op}
          @table[node.cstep].delete(fu)
        else
          fu=RTL::Compute.new(@dim)
          fu.op=node.op
        end
      when ConstNode
        fu=RTL::Const.new(@dim)
      else
        raise "unknown node type #{node}"
      end
      @functional_units << fu unless @functional_units.include?(fu)
      return fu
    end

    def bind_to node,fu
      fu << node
      node.mapping=fu
    end

    #lifetime[v] is an array of disjoint life_segments h={:birth=> cstep, :death=>cstep'}
    def compute_lifetimes func
      lifetime={}
      func.dfg.nodes.each do |node|
        case input=assign=node.stmt
        when Arg
          var=input
        when Assign
          var=assign.lhs.ref
        end
        if var
          life_segment={}
          life_segment[:birth]=node.cstep
          max_succ=node.outputs.max_by{|succ| succ.cstep}
          life_segment[:death]=max_succ.cstep
          lifetime[var]||=[]
          lifetime[var] << life_segment if life_segment[:birth]!=life_segment[:death]
        end
      end

      # for display :
      max_cstep=lifetime.collect{|var,life_segments| life_segments.map{|ls| ls[:death]}}.flatten.max

      lifetime.each do |var,life_segments|
        life_line=("-"*(max_cstep+1)).chars
        life_segments.each do |life_segment_h|
          birth=life_segment_h[:birth]
          life_line[birth]="["
          death=life_segment_h[:death]
          life_line[death]="]"
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
        reg=RTL::Register.new(name="r#{idx}")
        clique.content.each do |var|
          var.mapping=reg
          report 0,"binding #{var.name.tok.val} to register #{name}"
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
