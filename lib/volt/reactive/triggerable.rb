require 'volt/reactive/bloom'

# The triggerable module can be included in any class to allow it to
# trigger events.

module Triggerable

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