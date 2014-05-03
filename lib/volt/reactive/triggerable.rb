require 'reactive/bloom'

# The events module can be included in any class to allow it to
# register and trigger events.

module Triggerable

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

  # The default method_scope implementation, simply returns nil, meaning all
  # method's scope will be the catch all partial scope.
  def method_scope(method_name)
    return nil
  end

  # Returns a Bloom representing the trigger id for a method.
  def method_trigger_id(method_name)
    scope = method_scope(method_name)
    return Bloom.new(self.id + '/' + scope.to_s)
  end

  def object_trigger_id
    return Bloom.new(self.id)
  end

  # Schedules a trigger of event (calling the callback)
  def trigger!(event, *args, &block)

  end

  # Runs a trigger right now.
  def sync_trigger!(event, *args, &block)
    if @listeners && (event_listeners = @listeners[event])
      event_listeners.each do |event_listener|
        event_listener.call(*args, &block)
      end
    end
  end
end