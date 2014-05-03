# The eventable module can be included on any object that can register
# events.

module Eventable
  # The Listener class tracks a bound event.  An instance is returned when
  # an event is registered with .on  The Listener can be removed by calling
  # .remove
  class Listener
    def initialize(klass, event, callback)
      @klass = klass
      @event = event
      @callback = callback
    end

    # Removes the event listener
    def remove
      @klass.remove_listener(@event)

      # Clear
      @klass = nil
      @event = nil
      @callback = nil
    end

    # Calls the callback
    def call(*args, &block)
      @callback.call(*args, &block)
    end

    def inspect
      "<Listener:#{object_id} event=#{@event}>"
    end
  end

  # Register an event
  def on(event, &block)
    listener = Listener.new(self, event, block)

    @listeners ||= {}
    @listeners[event] ||= []
    @listeners[event] << listener

    return listener
  end
end