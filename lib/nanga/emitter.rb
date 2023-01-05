module Nanga

  class Emitter < Visitor

    def visitDef def_,args=nil
      @body_stack=[]
      @decls=[]
      @symtable=def_.symtable
      reset_tmp(def_)
      new_def=super(def_)
      new_def.decls << @decls
      new_def.decls.flatten!
      new_def
    end

    def visitBody body,args=nil
      @body_stack.push new_body=Body.new(stmts=[])
      body.stmts.each{|stmt| stmt.accept(self)}
      @body_stack.pop
    end

    def emit stmt
      @body_stack.last.stmts << stmt
      stmt
    end

    def reset_tmp def_
      tmp_decls=def_.decls.select{|decl| decl.name.str.start_with? '$'}
      if tmp_decls.any?
        max=tmp_decls.max_by{|tmp| tmp.name.str}
        @tmp=max.name.str[1..-1].to_i + 1
      else
        @tmp=-1
      end
    end

    def create_tmp type
      @tmp+=1
      name="$#{@tmp}"
      if type.nil?
        type=NamedType.new(id=Ident.create("unknown"))
        @symtable.set id.str,type
      end
      @decls << var=Var.new(ident=Ident.create(name),type)
      @symtable.set var.name.str,var
      ident.ref=var
      return ident
    end

    def visitAssign assign,args=nil
      emit new_assign=super(assign)
    end

    def visitReturn ret,args=nil
      emit new_return=super(ret)
    end
  end
end
