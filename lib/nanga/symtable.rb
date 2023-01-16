module Nanga
  class Scope
    attr_accessor :table
    def initialize
      @table={}
    end

    def set str,obj
      @table[str]=obj
    end

    def get str
      @table[str]
    end
  end

  class Symtable
    def initialize
      @stack=[]
    end

    def create_scope
      @stack.push @scope=Scope.new # current scope
      @scope
    end

    def leave_scope
      @scope=@stack.pop
    end

    def get_scope
      @stack.last
    end

    def set str,obj
      @scope.set str,obj
    end

    def get str
      @stack.reverse.each do |scope|
        if ref=scope.get(str)
          return ref
        end
      end
      nil
    end
  end
end
