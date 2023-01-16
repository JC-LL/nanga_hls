module Nanga

  include Dataflow

  #===================== AST =======================
  module Visitable
    def accept(visitor, arg=nil)
      name = self.class.name.split(/::/).last
      visitor.send("visit#{name}".to_sym, self ,arg) # Metaprograming !
    end

    def str
      self.accept(Nanga::PrettyPrinter.new).to_s
    end
  end

  class Root
    include Visitable
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end
  end

  class Def
    include Visitable
    attr_accessor :name,:args,:type
    attr_accessor :decls,:body
    attr_accessor :symtable
    attr_accessor :dfg
    attr_accessor :dim
    attr_accessor :controler,:datapath

    def initialize name,args,type,decls,body
      @name,@args,@type,@decls,@body=name,args,type,decls,body
    end

    def stmts
      @body.stmts
    end

    def consts
      @decls.select{|decl| decl.is_a? Const}
    end
  end

  class Arg < Dataflow::BehavioralNode
    include Visitable
    attr_accessor :name,:type
    attr_accessor :range
    attr_accessor :mapping  # WARNING : for Node allocation
    attr_accessor :register # WARNING : for Edge allocation
    def initialize name_,type
      super([],name_.str) # creates Node output
      @name,@type=name_,type
    end
  end

  class Var < Dataflow::BehavioralNode
    include Visitable
    attr_accessor :name,:type
    attr_accessor :range
    attr_accessor :register #WARNING : for Edge allocation
    def initialize name,type=nil
      super([],name.str)
      @name,@type=name,type
    end
  end

  # declared const
  class Const < Dataflow::BehavioralNode
    include Visitable
    attr_accessor :name,:type,:val
    attr_accessor :range
    attr_accessor :mapping
    def initialize name,type,val
      super([],name.str)
      @name,@type,@val=name,type,val
      #@range=Interval.new()
    end
  end

  INT_TYPE_RX=Regexp.new('[us](\d+)') #WARN : single quotes!!!

  class NamedType
    include Visitable
    attr_accessor :name
    def initialize name
      @name=name
    end

    def self.create str
      NamedType.new Ident.create str
    end

      def nbits
      name.str.match(INT_TYPE_RX)[1].to_i
    end

    def signed?
      name.str.match(/\A[si](\d+)/)
    end

    def unsigned?
      name.str.match(/\Au(\d+)/)
    end

    def integer_kind
      return :u if unsigned?
      return :s if signed?
    end

    def kind_bits
      if signed? or unsigned?
        return [integer_kind,nbits]
      end
    end
  end

  class Interval
    include Visitable
    attr_accessor :min,:max
    def initialize min,max
      @min,@max=min,max
    end
  end

  class Mapping
    include Visitable
    attr_accessor :name
    def initialize name
      @name=name
    end
  end

  class Body
    include Visitable
    attr_accessor :stmts
    def initialize stmts=[]
      @stmts=stmts
    end
    def each &block
      @stmts.each(&block)
    end
  end
  #================= Statements ============
  class Assign
    include Visitable
    attr_accessor :lhs,:rhs
    def initialize lhs,rhs
      @lhs,@rhs=lhs,rhs
    end
  end

  class Return < Dataflow::BehavioralNode
    include Visitable
    attr_accessor :expr
    def initialize expr
      super([expr.str],nil)
      @expr=expr
    end
  end
  #============= Expressions ================
  class Expr < Dataflow::BehavioralNode
    include Visitable
    def initialize nb
      input_port_names=nb.times.map{|i| "i#{i}"}
      output_port_name="o"
      super(input_port_names,output_port_name)
    end
  end

  class Binary < Expr
    include Visitable
    attr_accessor :lhs,:op,:rhs
    attr_accessor :range
    attr_accessor :mapping
    def initialize lhs,op,rhs
      super(2)
      @lhs,@op,@rhs=lhs,op,rhs
    end
  end

  class Unary < Expr
    include Visitable
    attr_accessor :expr
    attr_accessor :range
    attr_accessor :mapping
    def initialize op,expr
      super(1)
      @op,@expr=op,expr
    end
  end

  #=============== terminals=================
  class Ident
    include Visitable
    attr_accessor :tok
    attr_accessor :ref
    attr_accessor :range
    def initialize tok
      @tok=tok
    end

    def self.create str
      Ident.new(Token.new(:ident,str,[0,0]))
    end

    def output
      ref.output
    end
  end

  class IntLit
    include Visitable
    attr_accessor :tok
    attr_accessor :val
    attr_accessor :range
    attr_accessor :type
    def initialize tok
      @tok=tok
      @val=tok.val.to_i
      @range=Interval.new(@val,@val)
      #nbits=@val==0 ? 1 : Math.log2(@val).ceil
      #@type=NamedType.new(Ident.create "u#{nbits}")
    end

    def self.create int
      IntLit.new(Token.new(:intlit,int.to_s,[0,0]))
    end
  end
  #================= Synthesis ==============
  class Cstep
    include Visitable
    attr_accessor :id,:body
    def initialize id,body
      @id=id
      @body=body
    end
  end

end
