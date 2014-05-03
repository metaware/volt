require 'volt/reactive/bloom'

describe Bloom do
  it "should work with keys" do
    @bloom = Bloom.new

    # Test one
    expect(@bloom.in?('one')).to eq(false)
    @bloom.add('one')
    expect(@bloom.in?('one')).to eq(true)

    # Test two
    expect(@bloom.in?('two')).to eq(false)
    @bloom.add('two')
    expect(@bloom.in?('two')).to eq(true)

    expect(@bloom.in?('three')).to eq(false)
  end
end