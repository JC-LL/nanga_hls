module Nanga

  class Compiler

    attr_accessor :options
    attr_accessor :project_name

    def initialize options={}
      @options=options
      $verbosity=0
    end

    def compile filename
      begin
        ast=parse(filename)
        puts "[+] resolving references"
        ast=resolve(ast)
        print(ast)

        puts "[+] elaborate intermediate representation"
        ir=build_ir(ast)
        print(ir)
        save(ir,"1_ir")

        puts "[+] strength reduction"
        ir=reduce_strength(ir)
        print(ir)
        save(ir,"2_sr")

        puts "[+] propagate value ranges"
        ir=propagate_range(ir)
        print(ir)
        save(ir,"3_vr")

        puts "[+] elaborate dataflow graphs"
        ir=elaborate_dfg(ir)

        puts "[+] generate dot for dataflow graphs"
        generate_dot(ir)

        puts "[+] scheduling"
        ir=scheduling(ir)
        save(ir,"4_sc")

        puts "[+] allocation"
        ir=allocation(ir)
        save(ir,"5_al")

        puts "[+] extracting fsm/datapath"
        ir=extract_controler_datapath(ir)

        puts "[+] VHDL generation"
        top_level=vhdl_generation(ir)

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
      if $verbosity > 0
        code=PrettyPrinter.new.print(ast)
        puts code.finalize
      end
    end

    def save ast,tag
      code=PrettyPrinter.new.print(ast)
      filename=@basename+"_"+tag+".nga"
      code.save_as(filename)
    end

    def resolve ast
      Resolver.new.run ast
    end

    def build_ir ast
      IrBuilder.new.run(ast)
    end

    def reduce_strength ast
      StrengthReductor.new.run(ast)
    end

    def propagate_range ast
      RangePropagator.new.run ast
    end

    def operations_symetrization ast
      Symetrization.new.run(ast)
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

    def extract_controler_datapath ast
      Extractor.new.run(ast)
    end

    def vhdl_generation ast
      VHDLGenerator.new.run(ast)
    end

  end
end
