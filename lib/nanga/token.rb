class Token
  attr_accessor :kind,:val,:pos
  def initialize kind,val,pos
    @kind,@val,@pos=kind,val,pos
  end

  def is_a? kind
    case kind
    when Symbol
      return @kind==kind
    when Array
      for sym in kind
        return true if @kind==sym
      end
      return false
    else
      raise "wrong type during lookahead"
    end
  end

  def not_a? kind
    result=self.is_a? kind
    !result
  end

  def is_not_a? kind
    case kind
    when Symbol
      return @kind!=kind
    when Array
      ret=true
      for sym in kind
        ret=false if @kind==sym
      end
      return ret
    else
      raise "wrong type during lookahead"
    end
  end

  def self.create str
    Token.new :id,str,[0,0]
  end

  def to_s
    val
  end
end

ONE  = Token.new :int_lit,'1',['na','na']
ZERO = Token.new :int_lit,'0',['na','na']
DUMMY= Token.new :id     ,'' ,['na','na']
