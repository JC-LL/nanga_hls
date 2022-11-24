class GenericParser

  def accept_it
    tok=tokens.shift
    puts "consuming #{tok.val} (#{tok.kind})" if @verbose
    tok
  end

  def show_next k=1
    tokens[k-1]
  end

  def expect kind
    if ((actual=show_next).kind)!=kind
      abort "ERROR at #{actual.pos}. Expecting #{kind}. Got #{actual.kind}"
    else
      return accept_it()
    end
  end

  def maybe kind
    if show_next.kind==kind
      return accept_it
    end
    nil
  end

  def more?
    !tokens.empty?
  end

  def lookahead n
    show_next(k=n)
  end

  def niy
    raise "NIY"
  end

  def  next_tokens n=5
    @tokens[0..n].map{|tok| [tok.kind,tok.val].to_s}.join(',')
  end

  def consume_to token_kind
    while show_next && show_next.kind!=token_kind
      acceptIt
    end
    if show_next.nil?
      raise "cannot find token '#{token_kind}'"
    end
  end

  # warn : metaprogramming
  def parse_ kind
    send("parse_#{kind}".to_sym)
  end

end
