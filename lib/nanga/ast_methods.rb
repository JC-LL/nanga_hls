# add 'accept' and 'str' methods to Struct.
class Struct
  def accept(visitor, arg=nil)
    name = self.class.name.split(/::/).last
    visitor.send("visit#{name}".to_sym, self ,arg) # Metaprograming !
  end

  def str
    self.accept(Nanga::PrettyPrinter.new).to_s
  end
end
