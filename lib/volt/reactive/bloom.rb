# TODO: Move 432 bits to options somewhere
if RUBY_PLATFORM == 'opal'
  # The opal implementaiton
  class Bloom
    def initialize
      # Create a bit vector
      @bit_vector = `new BitVector(432)`
    end

    def add(key)
      # Set the bits on the vector
      `this.bit_vector.setBitsForValue(key);`
    end

    # Tests if the bits in this Bloom are set in the passed in bloom.
    def bloom_in?(bloom)
      return `this.bit_vector.and(bloom.bit_vector).equals(bloom.bit_vector)`
    end

    def in?(key)
      other = `new BitVector(432)`

      `other.add(key)`

      return bloom_in?(other)
    end
  end
else
  require 'volt/reactive/bit_vector'

  # The ruby implementation
  class Bloom
    attr_reader :bit_vector

    def initialize
      @bit_vector = BitVector.new(432)
    end

    def add(key)
      @bit_vector.add(key)

      return self
    end

    def bloom_in?(bloom)
      return @bit_vector.and(bloom.bit_vector).equals(bloom.bit_vector)
    end

    def in?(key)
      return bloom_in?(Bloom.new.add(key))
    end

    def &(other)
      return Bloom.new(@bit_vector.and(other.bit_vector))
    end
  end
end