# TODO: Move 432 bits to options somewhere
if RUBY_PLATFORM == 'opal'
  # The opal implementaiton
  class TriggerSet
    def initialize
      # Create a bit vector
      @bit_vector = `new BitVector(432)`
    end

    def add(key)
      # Set the bits on the vector
      `this.bit_vector.setBitsForValue(key);`
    end

    # Tests if the bits in this Bloom are set in the passed in bloom.
    def has_trigger?(bloom)
      return `this.bit_vector.and(bloom.bit_vector).equals(bloom.bit_vector)`
    end

    def in?(key)
      other = `new BitVector(432)`

      `other.add(key)`

      return has_trigger?(other)
    end

    def &(other)
      raise "implement &"
    end
  end
else
  require 'volt/reactive/bit_vector'

  # The ruby implementation
  class TriggerSet
    attr_reader :bit_vector

    def initialize(start=nil)
      if start.is_a?(BitVector)
        @bit_vector = start
      else
        @bit_vector = BitVector.new(432)
        add(start) if start
      end
    end

    def add(key)
      @bit_vector.add(key)

      return self
    end

    def has_trigger?(trigger_set)
      return @bit_vector.and(trigger_set.bit_vector).equals(trigger_set.bit_vector)
    end

    def in?(key)
      return has_trigger?(TriggerSet.new(key))
    end

    def set_bit_vector(bit_vector)
      @bit_vector = bit_vector
      return self
    end

    def +(other)
      return TriggerSet.new(@bit_vector.or(other.bit_vector))
    end
  end
end