module Nanga
  module Reporting
    def info_pass level,str
      prefix="[+] "
      prefix="|--"+prefix if level > 0
      case level 
      when 0 
        spaces=""
      when 1
        spaces=" "
      else
        spaces=" "*((level-2)*4 + 1)
      end
      str=spaces+prefix+str
      puts str 
    end

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
