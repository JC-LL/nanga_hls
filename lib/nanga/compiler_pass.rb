module Nanga
  class CompilerPass < Visitor
    def hit_a_key
      puts "hit a key"
      $stdin.gets
    end
  end
end
