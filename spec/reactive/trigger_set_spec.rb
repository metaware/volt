require 'volt/reactive/trigger_set'

describe TriggerSet do
  it "should work with keys" do
    @trigger_set = TriggerSet.new

    # Test one
    expect(@trigger_set.in?('one')).to eq(false)
    @trigger_set.add('one')
    expect(@trigger_set.in?('one')).to eq(true)

    # Test two
    expect(@trigger_set.in?('two')).to eq(false)
    @trigger_set.add('two')
    expect(@trigger_set.in?('two')).to eq(true)

    expect(@trigger_set.in?('three')).to eq(false)
  end
end