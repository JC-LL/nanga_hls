module Nanga
  class CompilerPass < Visitor
    include Reporting
    def pass level,str
      prefix="[+] "
      prefix="|--"+prefix if level > 0
      str=prefix+str
      puts str if $verbosity >= level
    end
  end
end
