require 'volt/reactive/events'

class EventTest
  include Events
end

describe Events do
  before do
    @event_klass = EventTest.new
  end

  it "should setup a listener" do
    listener = @event_klass.on('changed') { }

    expect(listener.class).to eq(Events::Listener)
  end

  it "should trigger the callback" do
    count = 0
    listener = @event_klass.on('changed') { count += 1 }

    expect(count).to eq(0)
    @event_klass.trigger!('changed')
    expect(count).to eq(1)
  end
end