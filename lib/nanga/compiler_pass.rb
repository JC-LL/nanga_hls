module Nanga
  class CompilerPass < Visitor
    def hit_a_key
      puts "hit a key"
      $stdin.gets
    end

    def report verbosity_level,str
      puts str if $verbosity >= verbosity_level
    end
  end
end
