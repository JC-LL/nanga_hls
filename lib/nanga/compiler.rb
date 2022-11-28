module Nanga

  class Compiler

    attr_accessor :options
    attr_accessor :project_name

    def initialize options={}
      @options=options
    end

    def compile filename
      begin
        ast=parse(filename)

        puts "[+] resolving references"
        ast=resolve(ast)

        puts "[+] elaborate intermediate representation"
        ir=gen_ir(ast)
        save(ir,"ir_1")

        puts "[+] strength reduction"
        ir=reduce_strength(ir)
        print(ir)
        save(ir,"sr_2")

        puts "[+] propagate value ranges"
        ir=propagate_range(ir)
        print(ir)
        save(ir,"vr_3",verbose=true)
        save(ir,"vr_4",verbose=false)

        puts "[+] elaborate dataflow graphs"
        ir=elaborate_dfg(ir)

        puts "[+] generate dot for dataflow graphs"
        generate_dot(ir)

        puts "[+] scheduling"
        ir=scheduling(ir)

        puts "[+] allocation"
        ir=allocation(ir)

      rescue Exception => e
        puts e.backtrace
        puts e
      end
    end

    def parse filename
      @basename=File.basename(filename,".nga")
      Parser.new.parse filename
    end

    def print ast,verbose=false
      PrettyPrinter.new.print(ast,verbose)
    end

    def save ast,tag,verbose=false
      code=print(ast,verbose)
      filename=@basename+"_"+tag+".nga"
      code.save_as(filename)
    end

    def resolve ast
      Resolver.new.run ast
    end

    def gen_ir ast
      IrGen.new.run(ast)
    end

    def reduce_strength ast
      StrengthReductor.new.run(ast)
    end

    def propagate_range ast
      RangePropagator.new.run ast
    end

    def elaborate_dfg ast
      DfgGen.new.run(ast)
    end

    def generate_dot ast
      DfgPrinter.new.run(ast)
    end

    def scheduling ast
      DfgScheduler.new.run(ast,:asap)
    end

    def allocation ast
      DfgAllocator.new.run(ast)
    end
  end
end
