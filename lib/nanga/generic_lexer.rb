require 'strscan'

require_relative 'token'

class GenericLexer

  def initialize
    @rules = []
    @rules << [:newline,/[\n]/]
  end

  def ignore pattern
    @rules << [:skip,pattern]
  end

  def keyword str
    @rules.unshift [str.to_sym,/#{str}\b/i]
  end

  def token hash
    token,pattern=*hash.to_a.flatten
    @rules << [token, pattern]
  end

  def open code
    @ssc = StringScanner.new code
    @line=0
  end

  def next_token
    return [nil,nil,nil] if @ssc.empty?
    tok = get_token
    return (tok.is_a? :skip) ? next_token : tok
  end

  def get_token
    linecol=position()
    @rules.each do |rule, regexp|
      val = @ssc.scan(regexp)
      return Token.new(rule, val, linecol) if val
    end
    raise  "lexing error line #{linecol.first} around : ...'#{@ssc.peek(5)}'... "
  end

  def position
    if @ssc.bol?
      @line+=1
      @old_pos=@ssc.pos
    end
    [@line,@ssc.pos-@old_pos+1]
  end

  def tokenize code
    open(code)
    tokens=[]
    tokens << next_token() while not @ssc.eos?
    # while not @ssc.eos?
    #   tokens << (p next_token)
    # end #usefull for debug
    tokens
  end
end
