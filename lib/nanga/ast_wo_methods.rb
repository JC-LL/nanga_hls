module Nanga
  Root           = Struct.new(:elements)

  # function prototype
  Def            = Struct.new(:name,:args,:type,:decls,:body,:symtable,:dfg)
  Arg            = Struct.new(:name,:type)

  Const          = Struct.new(:name,:type,:val)
  Var            = Struct.new(:name,:type)

  # types
  NamedType      = Struct.new(:name)
  Interval       = Struct.new(:min,:max)

  # body & statements
  Body           = Struct.new(:stmts)
  Assign         = Struct.new(:lhs,:rhs)
  Return         = Struct.new(:expr)

  # expressions
  Binary         = Struct.new(:lhs,:op,:rhs,:mapping,:range,:type)
  Unary          = Struct.new(:op,:expr,:mapping,:range)
  Cast          = Struct.new(:type,:expr)

  # ident & numeric literals
  IntLit         = Struct.new(:tok)
  Ident          = Struct.new(:tok,:range,:mapping)

  # dfg processing
  Cstep          = Struct.new(:id,:body)
  Mapping        = Struct.new(:name)
end
