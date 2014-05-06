require 'volt/reactive/trigger_set'

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
      @klass.remove_listener(@event, self)

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
  def on(event, event_registry=nil, &block)
    event = event.to_sym

    unless event_registry
      # No provided event registry, setup a global event registry if needed
      $event_registry = EventRegistry.new unless defined?($event_registry)

      # Use the global event registry
      event_registry = $event_registry
      # ::Object.send(:raise, "No current event registry")
    end

    # Create a listener for the event
    listener = Listener.new(self, event, block)

    unless @listeners
      @listeners = {}

      # First time an event is added for this object
      event_registry.register(event, trigger_set, self)
    end

    @listeners[event] ||= []
    @listeners[event] << listener

    return listener
  end

  # Removes a registered event listener
  def remove_listener(event, listener)
    # Delete the listener
    @listeners[event].delete(listener)

    # Clear the event array if empty
    @listeners.delete(event) if @listeners[event].size == 0

    # Clear listeners if empty
    @listeners = nil if @listeners.size == 0
  end
end