require 'volt/reactive/eventable'
require 'volt/reactive/triggerable'

class EventableTest
  include Eventable
  include Triggerable
end

describe Eventable do
  before do
    @event_klass = EventableTest.new
    $event_registry = EventRegistry.new
  end

  it "should setup a listener" do
    listener = @event_klass.on('changed') { }

    expect(listener.class).to eq(Eventable::Listener)
  end

  it "should trigger the callback" do
    count = 0
    listener = @event_klass.on('changed') { count += 1 }

    expect(count).to eq(0)
    @event_klass.trigger!('changed')
    $event_registry.flush!
    expect(count).to eq(1)
  end
end