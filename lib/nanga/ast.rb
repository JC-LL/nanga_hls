module Nanga
  Root           = Struct.new(:elements)
  Def            = Struct.new(:name,:args,:type,:decls,:body,:symtable,:dfg,:controler,:datapath) do
    def stmts
      body.stmts
    end

    def consts
      decls.select{|decl| decl.is_a? Const}
    end
  end

  Arg            = Struct.new(:name,:type,:range,:mapping)
  Const          = Struct.new(:name,:type,:val,:range,:mapping)
  Var            = Struct.new(:name,:type,:range,:mapping)


  INT_TYPE_RX=Regexp.new('[us](\d+)') #WARN : single quotes!!!

  NamedType      = Struct.new(:name) do

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

  Interval       = Struct.new(:min,:max)
  Mapping        = Struct.new(:name)

  Body           = Struct.new(:stmts) do
    def each &block
      @stmts.each(&block)
    end
  end

  Cstep          = Struct.new(:id,:body)

  Assign         = Struct.new(:lhs,:rhs)
  Return         = Struct.new(:expr)

  Binary         = Struct.new(:lhs,:op,:rhs,:mapping,:range,:type)
  Unary          = Struct.new(:op,:expr,:mapping,:range)

  IntLit         = Struct.new(:tok) do
    def self.create int
      IntLit.new(Token.new(:intlit,int.to_s,[0,0]))
    end
  end

  Ident          = Struct.new(:tok,:range,:mapping,:ref) do
    def self.create str
      Ident.new(Token.new(:ident,str,[0,0]))
    end
  end

  Cast          = Struct.new(:type,:expr) do
  end
end
