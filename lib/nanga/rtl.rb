module Nanga
  module RTL
    class DatapathNode < Dataflow::Node
      attr_accessor :id

      def <<(node)
        @allocated_nodes||=[]
        @allocated_nodes << node
      end

      def name
        self.class.to_s.split('::').last.downcase+"_#{@id}"
      end

      def kind
        self.class.to_s.split('::').last.downcase
      end
    end

    class Input < DatapathNode
      @@id=-1
      attr_accessor :name
      def initialize name=nil
        super([],name)
        @id=Input.next_id
        @name=name||"I#{@id}"
      end

      def Input.next_id
        @@id+=1
      end
    end

    class Output < DatapathNode
      @@id=-1
      attr_accessor :name
      def initialize name=nil
        super([name],nil)
        @id=Input.next_id
        @name=name||"0#{@id}"
      end

      def Input.next_id
        @@id+=1
      end
    end

    class Mux < DatapathNode
      @@id=0
      attr_accessor:name
      def initialize
        super([],"f")
        @id=Mux.next_id
        @name="mux_#{@id}"
      end

      def Mux.next_id
        @@id+=1
      end

      def size
        @inputs.size
      end
    end

    class FunctionalUnit < DatapathNode
      attr_accessor :mux
      def initialize
        super(["i0",'i1'],"f")
        @mux={left:mux_l=Mux.new,right:mux_r=Mux.new}
        mux_l.output.to self.get_input(0)
        mux_r.output.to self.get_input(1)
      end

      def op
        self.class.to_s.split('::').last.downcase.to_sym
      end
    end

    class Add < FunctionalUnit
      @@id=-1
      def initialize
        super()
        @id=Add.next_id
      end

      def Add.next_id
        @@id+=1
      end
    end

    class Sub < FunctionalUnit
      @@id=-1
      attr_accessor :id,:name
      def initialize
        super()
        @id=Sub.next_id
      end

      def Add.next_id
        @@id+=1
      end
    end

    class Mul < FunctionalUnit
      @@id=-1
      attr_accessor :id
      def initialize
        super()
        @id=Mul.next_id
      end

      def Mul.next_id
        @@id+=1
      end
    end

    class Div < FunctionalUnit
      @@id=-1
      attr_accessor :id
      def initialize
        super()
        @id=Div.next_id
      end

      def Div.next_id
        @@id+=1
      end
    end

    class Const < DatapathNode
      @@id=-1
      attr_accessor :val
      def initialize val
        super([],"o")
        @val=val
        @id=Const.next_id
        @name="const#{@id}_#{val}"
      end

      def Const.next_id
        @@id+=1
      end
    end

    class Reg < DatapathNode
      @@id=-1
      attr_accessor :vars
      attr_accessor :mux
      attr_accessor :type
      def initialize type
        super(["d"],"q")
        @type=type
        self.get_input(0).type=type
        self.output.type=type

        @id=Reg.next_id
        @vars=[]
        @mux=Mux.new
        @mux.output.to self.get_input(0)
        new_input_name="i0"
        new_input=Dataflow::Port.new(mux,new_input_name)
        @mux.inputs << new_input
        output.to new_input
        #puts "reg #{@name} creating #{@mux.id}"
      end

      def Reg.next_id
        @@id+=1
      end

      def << vars
        @vars << vars
        @vars.uniq!
      end
    end

    class Datapath < Dataflow::Graph
      def edges
        return @edges if @edges
        @edges=[]
        nodes_with_output=nodes.reject{|node| node.output.nil?}
        nodes_with_output.each do |node|
          var_name=node.name # warn : a String here. Differs from Dfg
          node.output.fanout.each do |dst|
            @edges << Dataflow::Edge.new(node.output,dst,var_name)
          end
        end
        @edges
      end
    end

    class State
      @@id=-1 # idle = 0
      attr_accessor :controls
      attr_accessor :id
      def initialize
        @id=(@@id+=1)
        @controls=[]
      end

      def <<(control)
        #puts "state #{@id} : pushing transfer mux #{control.mux.id} #{control.value}"
        # check that this control i not already registered
        @controls.each do |ctrl|
          if ctrl.mux==control.mux
            if ctrl.value!=control.value
              puts "ERROR: mux #{control.mux.id} is already assigned (with a value #{ctrl.value}) during state #{@id}"
              puts "new value is #{control.value}"
              raise
            else
              return
            end
          end
        end
        #puts "adding control #{control.to_s} to state #{@id}"
        @controls << control
      end
    end

    class Control
      attr_accessor :mux,:value
      def initialize mux,value
        @mux,@value=mux,value
      end

      def to_s
        "mux_#{@mux.id} => #{@value}"
      end
    end

    class Controler
      attr_accessor :states
      def initialize
        @states=[idle=State.new] #idle = -1
      end

      def <<(state)
        @states << state unless @states.include?(state)
      end
    end
  end
end
