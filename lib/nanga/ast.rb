module Nanga
  Root           = Struct.new(:elements)
  Def            = Struct.new(:name,:args,:type,:decls,:body,:symtable)
  Arg            = Struct.new(:name,:type)
  Const          = Struct.new(:name,:type,:val)
  Var            = Struct.new(:name,:type)
  NamedType      = Struct.new(:name)
  Interval       = Struct.new(:min,:max)

  Range          = Struct.new(:lhs,:rhs)
  Mapping        = Struct.new(:name)

  Body           = Struct.new(:stmts)

  Cstep          = Struct.new(:id,:body)

  Assign         = Struct.new(:lhs,:rhs)
  Return         = Struct.new(:expr)

  Binary         = Struct.new(:lhs,:op,:rhs,:mapping,:range)
  Unary          = Struct.new(:op,:expr,:mapping,:range)

  IntLit         = Struct.new(:tok) do
    def self.create int
      IntLit.new(Token.new(:intlit,int.to_s,[0,0]))
    end
  end

  Ident          = Struct.new(:tok,:range,:mapping) do
    def self.create str
      Ident.new(Token.new(:ident,str,[0,0]))
    end
  end
end