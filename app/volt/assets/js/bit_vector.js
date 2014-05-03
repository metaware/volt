// Test if the browser has Uint32 arrays
var hasUint32Array = typeof Uint32Array !== 'undefined';

/* BitVector emulates working with a block of memory's bits directly *
 * Takes the number of bits, will be rounded up to a multiple of 32  */
function BitVector(size, skipClear) {
  var bucketCount = ((size-1) >> 5) + 1;
  this.bitCount = bucketCount * 32;
  // TODO: Don't hard code 10 hash count
  this.hashCount = 10;

  if (hasUint32Array) {
    this.buckets = new Uint32Array(new ArrayBuffer(bucketCount * 4));
  } else {
    this.buckets = new Array(bucketCount);
  }

  if (!skipClear) {
    this.clear();
  }
}

// Zero out the bit vector
BitVector.prototype.clear = function() {
  for (var i=0;i < this.buckets.length;i++) {
    this.buckets[i] = 0;
  }
};

// Sets the bits as a bloom filter would
BitVector.prototype.add = function(value) {
  for (var i=0;i < this.hashCount;i++) {
    var index = murmurhash3_32_gc(value, i) % this.bitCount;

    // Set the bit
    this.set(index);
  }
};

// Set the bit to 1 at the index (zero indexed)
BitVector.prototype.set = function(index) {
  this.buckets[index >> 5] |= (1 << index);
};

// Set the bit at the index to 0 (zero indexed)
BitVector.prototype.unset = function(index) {
  this.buckets[index >> 5] &= (0xFF ^ (1 << index));
};

// Gets the bit at the index
BitVector.prototype.get = function(index) {
  return (this.buckets[index >> 5] & (1 << index)) !== 0;
};

// Takes a second BitVector of the same size returns a new
// BitVector that is the bitwise AND of the two.
BitVector.prototype.and = function(other) {
  var result = new BitVector(this.bitCount);
  var result_buckets = result.buckets;
  var this_buckets = this.buckets;
  var other_buckets = other.buckets;

  for (var i=0;i < this.buckets.length;i++) {
    result_buckets[i] = this_buckets[i] & other_buckets[i];
  }

  return result;
};

// Takes a second BitVector of the same size returns a new
// BitVector that is the bitwise OR of the two.
BitVector.prototype.or = function(other) {
  var result = new BitVector(this.bitCount);
  var result_buckets = result.buckets;
  var this_buckets = this.buckets;
  var other_buckets = other.buckets;

  for (var i=0;i < this.buckets.length;i++) {
    result_buckets[i] = this_buckets[i] | other_buckets[i];
  }

  return result;
};


// Takes a second BitVector of the same size returns a new
// BitVector that is the bitwise XOR of the two.
BitVector.prototype.xor = function(other) {
  var result = new BitVector(this.bitCount);
  var result_buckets = result.buckets;
  var this_buckets = this.buckets;
  var other_buckets = other.buckets;

  for (var i=0;i < this.buckets.length;i++) {
    result_buckets[i] = this_buckets[i] ^ other_buckets[i];
  }

  return result;
};

BitVector.prototype.equals = function(other) {
  var this_buckets = this.buckets;
  var other_buckets = other.buckets;

  for (var i=0;i < this.buckets.length;i++) {
    if (this_buckets[i] != other_buckets[i]) {
      // Didn't match, stop there
      return false;
    }
  }

  // All matched, true
  return true;
};


BitVector.prototype.toString = function() {
  var bits = [];
  for (var i=0;i < this.buckets.length * 32;i++) {
    if (this.get(i)) {
      bits.push(1);
    } else {
      bits.push(0);
    }
  }

  return "{" + bits.join('') + "}";
};

