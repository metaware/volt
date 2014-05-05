require 'volt/reactive/reactive_value'

describe ReactiveValue do
  before do
    $event_registry = EventRegistry.new
  end

  it "should trigger an event on its self" do
    a = ReactiveValue.new(5)
    count = 0
    listener = a.on('changed') { count += 1 }
    expect(count).to eq(0)

    a.trigger!('changed')
    $event_registry.flush!

    expect(count).to eq(1)
  end

  it "should not trigger an event after the listener has been removed" do
    a = ReactiveValue.new(5)
    count = 0
    listener = a.on('changed') { count += 1 }
    expect(count).to eq(0)

    listener.remove

    a.trigger!('changed')
    $event_registry.flush!

    expect(count).to eq(0)
  end

  it "should update current values" do
    a = ReactiveValue.new(0)
    expect(a.cur).to eq(0)

    a.cur = 1
    expect(a.cur).to eq(1)
  end

  it "should track dependencies and trigger on dependants" do
    a = ReactiveValue.new(1)
    b = a + 5

    count = 0
    b.on('changed') { count += 1}
    expect(count).to eq(0)

    a.trigger!('changed')
    $event_registry.flush!

    expect(count).to eq(1)
  end

  it "should trigger up through nested reactive values" do
    a = ReactiveValue.new(1)
    b = ReactiveValue.new(a)

    count = 0
    b.on('changed') { count += 1 }
    expect(count).to eq(0)

    a.trigger!('changed')
    $event_registry.flush!
    expect(count).to eq(1)
  end
end