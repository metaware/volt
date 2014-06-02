# Since ReactiveValue's behave like the objects they proxy, their hash and .eql?
# methods will proxy.  If we want to store unique objects/reactive value's in a hash
# we need to use the .__id__ method as the key.  This class acts like a normal hash
# but uses the __id__ instead.

class HashWithReactiveTracking
  def initialize
    @hash = {}
  end

  def [](key)
    key_val = @hash[key.__id__]
    if key_val
      return key_val[1]
    else
      return nil
    end
  end

  def []=(key, value)
    @hash[key.__id__] = [key, value]
  end

  def delete(key)
    @hash.delete(key.__id__)
  end

  def inspect
    str = []

    @hash.each_pair do |key_id, (key, value)|
      str << "#{key.inspect}=>#{value.inspect}"
    end

    return "#<HashWithReactiveTracking {#{str.join(', ')}}>"
  end

  def size
    @hash.size
  end

  def each_pair
    @hash.each do |key_id, (key, value)|
      yield(key, value)
    end
  end
end