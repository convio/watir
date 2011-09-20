class String
  def matches(x)
    return self == x
  end
end

class Regexp
  def matches(x)
    return self.match(x)
  end
end

class Integer
  def matches(x)
    return self == x
  end
end

class Array
  def matches(x)
    self.each do |item|
      return self.index(item) if item.matches x
    end
    return false
  end
end

class TrueClass
  def matches(x)
    self.== x
  end
end

class FalseClass
  def matches(x)
    self.== x
  end
end

# This is a workaround for a failure I'm seeing in getting ole to work with a checkbox
class WIN32OLE
  def matches(x)
    return self.outerHTML == x.outerHTML
  end
end
