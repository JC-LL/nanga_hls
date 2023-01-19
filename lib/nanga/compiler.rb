module Nanga

  class Compiler

    include Reporting

    attr_accessor :options
    attr_accessor :project_name

    def initialize options={}
      @options=options
      $verbosity=1
    end

    def compile filename
      begin
        ast=parse(filename)

        info_pass 0,"resolving references"
        ast=resolve(ast)
        #print(ast)

        info_pass 0,"elaborate intermediate representation"
        ir=build_ir(ast)
        #print(ir)
        save(ir,"1_ir")

        info_pass 0,"strength reduction"
        ir=reduce_strength(ir)
        #print(ir)
        save(ir,"2_sr")

        info_pass 0,"propagate value ranges"
        ir=propagate_range(ir)
        #print(ir)
        save(ir,"3_vr")

        info_pass 0,"elaborate dataflow graphs"
        ir=elaborate_dfg(ir)

        info_pass 0,"generate dot for dataflow graphs"
        generate_dot(ir)

        info_pass 0,"scheduling"
        ir=scheduling(ir)
        save(ir,"4_sc")

        info_pass 0,"allocation"
        ir=allocation(ir)
        save(ir,"5_al")

        info_pass 0,"extracting fsm/datapath"
        ir=extract_controler_datapath(ir)
        draw_architecture(ir)
        
        info_pass 0,"VHDL generation"
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
      Dataflow::Builder.new.run(ast)
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
      RTL::Extractor.new.run(ast)
    end

    def draw_architecture ast
      RTL::Drawer.new.run(ast)
    end

    def vhdl_generation ast
      VHDLGenerator.new.run(ast)
    end

  end
end
