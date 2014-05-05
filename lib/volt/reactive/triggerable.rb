require 'volt/reactive/trigger_set'

# The triggerable module can be included in any class to allow it to
# trigger events.

module Triggerable

  # The default method_scope implementation, simply returns nil, meaning all
  # method's scope will be the catch all partial scope.
  def method_scope(method_name)
    return nil
  end

  # Returns a TriggerSet representing the trigger id for a method.
  def method_trigger_id(method_name)
    scope = method_scope(method_name)
    return TriggerSet.new("#{__id__}/#{scope}")
  end

  # Returns a trigger set for a method, which includes the object's trigger set,
  # and the trigger id for the method.
  # def method_trigger_set(method_name)
  #   return method_trigger_id(method_name) + trigger_set
  # end

  def object_trigger_id
    return @object_trigger_id ||= TriggerSet.new(__id__.to_s)
  end

  # On a normal object (not reactive), the only thing in its trigger set
  # is its self.
  def trigger_set
    return object_trigger_id
  end

  # Schedules a trigger of an event (calling the callback)
  def trigger!(event, *args, &block)
    event = event.to_sym
    $event_registry.queue_trigger!(object_trigger_id, event, *args, &block)
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