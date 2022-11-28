module Nanga

  class Allocator

    # create a hash of {Node -> []} to store units for different node classes :
    INIT = ->(){[InputNode,ComputeNode,ConstNode,OutputNode].map{|node_klass| [node_klass,units=[]]}.to_h}

    def hit_a_key
      puts "hit a key"
      $stdin.gets
    end

    def initialize
      @units = INIT.call #node_kind -> [ units ]
      @cstep_table={}  #{cstep -> {node_kind -> [ units ]}}
    end

    def get_a_free_functional_unit cstep,node
      puts "\n[cstep #{cstep}] #{node.stmt.str}"
      if @cstep_table[cstep][node.class].any?
        unit=@cstep_table[cstep][node.class].shift
        return unit
      else
        puts "need to allocate a new unit"
        node_kind=node.class.to_s.split("::").last
        node_kind.gsub!("Node","")
        unit_name="Nanga::Hardware::"+node_kind+"Unit"
        unit_klas=Object.const_get(unit_name)
        unit=unit_klas.new
        @units[node.class] << unit
        return unit
      end
    end

    def free_ressources_for cstep
      puts "freeing ressources for cstep #{cstep}"
      @cstep_table[cstep]=INIT.call
      @units.each do |node_class,units|
        @cstep_table[cstep][node_class]||=[]
        units.each_with_index do |unit,idx|
          @cstep_table[cstep][node_class] << unit
        end
      end
    end
  end

  class DfgAllocator < Visitor

    def visitDef func,algo_name
      #-----------------------------------------------------------------
      # Here, we simply assign a node to any of the FUs (Function Units)
      # we assume a FU can perform every computation needed (except IO).
      #------------------------------------------------------------------
      @allocator=Allocator.new
      functional_units={}  # name -> [nodes running on it]
      scheduling=func.dfg.nodes.group_by{|node| node.cstep}
      scheduling.keys.sort.each do |cstep|
        @allocator.free_ressources_for(cstep)
        scheduling[cstep].each do |node|
          node.mapping=@allocator.get_a_free_functional_unit(cstep,node)
        end
      end
      display_allocation(func.dfg)
      func
    end

    def display_allocation dfg
      schedule=dfg.nodes.group_by{|node| node.cstep}
      for cstep in 0..schedule.keys.max
        puts "cstep #{cstep}".center(40,'=')
        schedule[cstep].each do |node|
          fu_name="FU#{node.mapping.id}"
          puts "mapping (#{node.stmt.str.green}) => #{fu_name.cyan}"
        end
      end
    end
  end
end
