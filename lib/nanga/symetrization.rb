module Nanga
  class Symetrization < Visitor
    def visitBinary binary,args=nil
      cast_h=get_cast(binary)
      binary.lhs=cast_h[:lhs]
      binary.rhs=cast_h[:rhs]
      binary.type=compute_bin_type(binary)
      binary
    end

    def compute_bin_type bin
      case bin.lhs
      when Ident
        ltype=@symtable[bin.lhs.str].type
      when Cast
        ltype=bin.lhs.type
      end
      case bin.rhs
      when Ident
        rtype=@symtable[bin.rhs.str].type
      when Cast
        rtype=bin.rhs.type
      end

    end

    def get_cast binary
      lhs,rhs=binary.lhs,binary.rhs
      # default to inchanged (no cast) return:
      ret={:lhs=>lhs ,:rhs=>rhs}
      lhs_type=@symtable[lhs.str].type
      rhs_type=@symtable[rhs.str].type
      lkind,lbits=lhs_type.kind_bits
      rkind,rbits=rhs_type.kind_bits
      case lkind
      when :u
        case rkind
        when :u
          if lbits > rbits
            type=NamedType.create "u#{lbits}"
            ret[:rhs]=Cast.new(type,rhs)
          elsif lbits < rbits
            type=NamedType.create "u#{rbits}"
            ret[:lhs]=Cast.new(type,lhs)
          end
        when :s
          if lbits > rbits
            type=NamedType.create "s#{lbits}"
            ret[:rhs]=Cast.new(type,rhs)
          elsif lbits < rbits
            type=NamedType.create "s#{rbits}"
            ret[:lhs]=Cast.new(type,lhs)
          else #force sign on left
            type=NamedType.create "s#{rbits}"
            ret[:lhs]=Cast.new(type,lhs)
          end
        end
      when :s
        case rkind
        when :u
          if lbits > rbits
            type=NamedType.create "s#{lbits}"
            ret[:rhs]=Cast.new(type,rhs)
          elsif lbits < rbits
            type=NamedType.create "s#{rbits}"
            ret[:lhs]=Cast.new(type,lhs)
            ret[:rhs]=Cast.new(type,rhs)
          else
            type=NamedType.create "s#{lbits}"
            ret[:rhs]=Cast.new(type,rhs)
          end
        when :s
          if lbits > rbits
            type=NamedType.create "s#{lbits}"
            ret[:rhs]=Cast.new(type,rhs)
          elsif lbits < rbits
            type=NamedType.create "s#{lbits}"
            ret[:lhs]=Cast.new(type,lhs)
          end
        end
      end
      ret
    end

  end
end
