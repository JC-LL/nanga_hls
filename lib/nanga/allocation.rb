module Nanga

  module Allocation
    class CliqueCovering
    end

    class TsengSiework < CliqueCovering
      def apply_to g
        g_prime=iteration(g)
        while g_prime!=g
          g=g_prime
          g_prime=iteration(g)
        end
        return g_prime
      end

      def iteration g
        common_neighbors={}
        g.edge_pairs.each do |n1,n2|
          common_neighbors[[n1,n2]]=n1.neighbors.intersection(n2.neighbors)
        end

        return g if common_neighbors.empty?

        common_neighbors_count=common_neighbors.map{|pair,intersection| [pair,intersection.count]}.to_h
        first_pair_kv=common_neighbors_count.first
        first_pair=first_pair_kv.first

        gout=Graph.new(g.name)

        # create super node...
        nn_name=first_pair.map{|e| e.name}.join("_")
        gout << super_node=Node.new(nn_name)
        # ...and its content
        first_pair.each do |node|
          if (content=node.content).any?
            super_node.content << content
          else
            super_node.content << node
          end
          super_node.content.flatten!
        end

        # add copies of other nodes
        copies={}
        g.nodes.each do |node|
          name=node.name
          unless first_pair.include?(node)
            gout << copies[name]=nn=Node.new(name)
            nn.content=node.content
          end
        end

        common_neighbors[first_pair].each do |neighbor|
          gout.connect super_node,copies[neighbor.name]
        end

        # copy connect back everything, except cnx that swallowed nodes
        g.nodes.each do |node|
          if new_node=copies[node.name]
            node.neighbors.each do |neighbor|
              if new_neighbor=copies[neighbor.name]
                gout.connect new_node,new_neighbor
              end
            end
          end
        end
        gout
      end
    end
  end
end
