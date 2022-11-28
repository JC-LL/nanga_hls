module Nanga
  module Hardware
    class FunctionalUnit
      attr_accessor :id
      attr_accessor :allocated_nodes

      @@id=-1

      def initialize
        @id=FunctionalUnit.next_id
        @allocated_nodes=[]
      end

      def << node
        @allocated_nodes << node
      end

      def self.next_id
        @@id+=1
      end
    end

    class InputUnit < FunctionalUnit
    end

    class ComputeUnit < FunctionalUnit
    end

    class ConstUnit < FunctionalUnit
    end

    class OutputUnit < FunctionalUnit
    end




  end
end
