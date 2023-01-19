module Nanga
  module Dataflow
    class Builder < CompilerPass

      def visitDef func,args=nil
        build_dfg(func)
        func
      end

      def build_dfg func
        info_pass 1,"building dfg for '#{func.name.str}'"
        @producers=collect_producers(func)
        func.dfg=make_connect(func)
      end

      def collect_producers func
        info_pass 4, "collecting producers for '#{func.name.str}'"
        @producers={}
        [func.args,func.body.stmts].flatten.each do |stmt|
          case arg=assign=ret=stmt
          when Arg
            @producers[arg.name.str]=arg.output
          when Assign
            # only the first x = ... will be registered as producer.
            unless @producers[str=assign.lhs.str]
              @producers[str]=assign.rhs.output
            end
            # i decided to modify the name of *output* port only.
            # this seems to provide better local lisibility
            # in Nodes : better to have ().a than ().output
            # when 'output' means nothing for the app developper.
            # ---
            # Inputs of node are not modify, which may seem odd.
            # If inputs names are also modified, it causes an issue
            # during viewing using Graphviz : if a node has two input ports named identically,
            # the generated dot code cannot distinguish which of the two ports to connect to.
            #
            # Renaming except for Arg node.
            unless assign.rhs.output.node.is_a?(Arg)
              assign.rhs.output.rename(str)
            end
          end
        end

        @producers.each do |str,port|
          report 2,"#{port.full_name} --#{str}-->"
        end
      end

      def renaming psrc,pdst
        old_name=pdst.name
        new_name=psrc.name
        # for dot viewing, distinguis between x*x => x_0 * x_1
        ndst=pdst.node
        if ndst.inputs.any?{|input| input.name==new_name}
          ndst.inputs.each_with_index{|input,idx| input.name=new_name+"#{idx}"}
        else
          pdst.name=new_name
        end
        report 2,"#{pdst} named #{old_name} renamed to #{pdst.name}"
      end

      # this method connects node inputs to their producers.
      def make_connect func
        dfg=Dataflow::Graph.new(func)
        func.args.each{|arg| dfg << arg}
        func.stmts.each{|stmt| dfg << stmt if stmt.is_a?(Return)}

        func.body.stmts.each do |stmt|
          case ret=assign=stmt
          when Assign
            case binary=unary=ident=lit=assign.rhs
            when Binary
              lhs_port=@producers[binary.lhs.str] || binary.lhs.output
              rhs_port=@producers[binary.rhs.str] || binary.rhs.output
              bin_port_0=binary.get_input(0)
              bin_port_1=binary.get_input(1)
              renaming(lhs_port,bin_port_0)
              renaming(rhs_port,bin_port_1)
              lhs_port.to bin_port_0
              rhs_port.to bin_port_1

              @producers[assign.lhs.str]=binary.output
              dfg << lhs_port.node
              dfg << rhs_port.node
              dfg << binary
            when Unary
              port_expr=@producers[unary.expr.str] || unary.expr.output
              port_expr.to unary.get_input(0)
              dfg << port_expr.node
            when Ident
              port_prod=@producers[ident.str]
              dfg << port_prod.node
            when IntLit
            else
              raise "NIY : #{assign.rhs.class}"
            end
          when Return
            var=ret.expr.ref
            expr_port=@producers[var.name.str] || var.output
            expr_port.to dst=ret.get_input(0)
            renaming(expr_port,dst)
          end
        end
        return dfg
      end
    end
  end
end
