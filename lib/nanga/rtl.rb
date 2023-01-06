module Nanga
  module RTL
    class DatapathNode
      attr_accessor :allocated_nodes
      def initialize
        # when 'wiring' datapath node, we systematically wire to a multiplexor (!),
        # either at the input of a dyadic operator (ALU,...), of a register, and even of
        # an output.
        # SO, the successors of a datapath node are named 'succ_muxes' instead of 'succs'.
        @succ_muxes=[]
        @allocated_nodes=[]
      end

      def wiring_to element,left_or_right=nil
        # Dyadic operators have a mux at their respective inputs : left and right.
        # When connecting, we indicate this assignement.
        # ---
        # In response, 'wiring_to' method returns the mux control index for this transfert
        # (namely the index of the connexion, that will serve as FSM control)
        # Note that index 0 is never returned, and will serve as a control that "does nothing"
        # or, for Reg, that loops back.
        # --
        # Stated differently, to operate, the transfert must use a value different from 0.
        if left_or_right
          @succ_muxes << element.mux[left_or_right]
          (mux=element.mux[left_or_right]) << self
          cmd_value=mux.size
        else # reg etc
          @succ_muxes << element.mux
          (mux=element.mux) << self
          cmd_value=mux.size
        end
        return Control.new(mux,cmd_value)
      end

      # returns the var type of the *first* allocated node... cross fingers
      def type
        @allocated_nodes.first.output_var.type
      end

      def <<(node)
        @allocated_nodes << node
      end
    end

    class FunctionalUnit < DatapathNode
      attr_accessor :id
      attr_accessor :name
      attr_accessor :nbits

      def initialize nbits
        super()
        @nbits=nbits
      end


    end

    class Input < FunctionalUnit
      @@id=0
      attr_accessor :id
      def initialize nbits
        super(nbits)
        @id=Input.next_id
        @name="I#{@id}"
      end

      def Input.next_id
        @@id+=1
      end
    end

    class Mux < DatapathNode
      @@id=0
      attr_accessor :id,:inputs
      def initialize
        @id=Mux.next_id
        @inputs=[]
      end

      def Mux.next_id
        @@id+=1
      end

      def <<(e)
        unless @inputs.include?(e)
          #puts "connecting #{e.name} to mux #{@id}"
          @inputs << e
        end
      end

      def size
        @inputs.size
      end
    end

    class Compute < FunctionalUnit
      attr_accessor :op,:mux

      def Compute.next_id
        @@id||=0
        @@id+=1
      end

      def initialize nbits
        super(nbits)
        @id=Compute.next_id
        mux_left=Mux.new
        mux_right=Mux.new
        @name="FU_#{@id}"
        #puts "#{@name} creating mux #{mux_left.id}"
        #puts "#{@name} creating mux #{mux_right.id}"
        @mux={left:mux_left,right:mux_right}
      end
    end

    class Const < FunctionalUnit
      @@id=0
      def initialize nbits
        super(nbits)
        @id=Const.next_id
        @name="const#{@id}"
      end

      def Const.next_id
        @@id+=1
      end
    end

    class Output < FunctionalUnit
      @@id=0
      attr_accessor :mux
      def initialize nbits
        super(nbits)
        @id=Output.next_id
        @name="O#{@id}"
        @mux=Mux.new
      end

      def Output.next_id
        @@id+=1
      end
    end

    class Register < DatapathNode
      attr_accessor :name,:vars
      attr_accessor :mux
      def initialize name
        super()
        @name=name
        @vars=[]
        @mux=Mux.new
        #puts "reg #{@name} creating #{@mux.id}"
      end

      def << vars
        @vars << vars
        @vars.uniq!
      end
    end

    class Datapath
      attr_accessor :name,:elements
      def initialize name
        @elements=[]
        @name=name
      end

      def <<(e)
        unless @elements.include?(e)
          #puts "datapath : insert '#{e.name}'"
          @elements << e
        end
      end

      def include?(e)
        @elements.include?(e)
      end
    end

    class State
      @@id=-1
      attr_accessor :controls
      attr_accessor :id
      def initialize
        @id=(@@id+=1)
        @controls=[]
      end

      def <<(control)
        # check that this control i not aleady registered
        @controls.each do |ctrl|
          return if ctrl.to_s==control.to_s
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
      attr_accessor :name
      def initialize name
        @name=name
        @states=[idle=State.new]
      end

      def <<(state)
        @states << state unless @states.include?(state)
      end
    end
  end
end
