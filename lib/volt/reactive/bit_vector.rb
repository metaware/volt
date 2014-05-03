require 'murmurhash3'

# A bit vector implementaiton in pure ruby.  This will be upgrade in the future,
# but is mainly here to provide compatability for the bit_vector.js used from Opal.

class BitVector
  attr_reader :bits

  def initialize(size)
    @bit_count = size
    @hash_count = 10

    @bits = 0
  end

  def set_bits(bits)
    @bits = bits
    return self
  end

  # Zero out the bit vector
  def clear
    @bits = 0
  end

  # Sets the bits as a bloom filter would
  def add(key)
    @hash_count.times do |seed|
      index = MurmurHash3::V32.str_hash(key, seed) % @bit_count

      # Set the bit
      set(index)
    end
  end

  # Set the bit to 1 at the index (zero indexed)
  def set(index)
    @bits |= (0x1 << index)
  end

  # Set the bit at the index to 0 (zero indexed)
  def unset(index)
    @bits &= ~(0x1 << index)
  end

  # Gets the bit at the index
  def get(index)
    return @bits[index]
  end

  # Takes a second BitVector of the same size returns a new
  # BitVector that is the bitwise AND of the two.
  def and(other)
    return BitVector.new(@bit_count).set_bits(@bits & other.bits)
  end

  # Takes a second BitVector of the same size returns a new
  # BitVector that is the bitwise OR of the two.
  def or(other)
    return BitVector.new(@bit_count).set_bits(@bits | other.bits)
  end

  def equals(other)
    return @bits == other.bits
  end
end