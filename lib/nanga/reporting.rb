module Nanga
  module Reporting
    def report verbosity_level,str
      puts str if $verbosity >= verbosity_level
    end
    def hit_a_key str=nil
      puts str if str
      puts "hit a key"
      $stdin.gets
    end

  end
end
