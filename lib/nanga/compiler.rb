module Nanga

  class Compiler

    attr_accessor :options
    attr_accessor :project_name

    def initialize options={}
      @options=options
    end

    def compile filename
      begin
        puts "=> compiling #{filename}"

        ast=parse(filename)
        print(ast)

        puts "=> resolving"
        ast=resolve(ast)
        print(ast)

        puts "=> elaborate intermediate representation"
        ir=gen_ir(ast)
        print(ir)

        puts "=> strength reduction"
        ir=reduce_strength(ir)
        print(ir)

        puts "=> propagate value ranges"
        ir=propagate_range(ir)
        print(ir)
        
      rescue Exception => e
        puts e.backtrace
        puts e
      end
    end

    def parse filename
      Parser.new.parse filename
    end

    def print root
      PrettyPrinter.new.print(root)
    end

    def resolve root
      Resolver.new.run root
    end

    def gen_ir root
      IrGen.new.run(root)
    end

    def reduce_strength root
      StrengthReductor.new.run(root)
    end

    def propagate_range root
      RangePropagator.new.run root
    end
  end
end
