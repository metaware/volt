require 'volt/reactive/trigger_set'

# The triggerable module can be included in any class to allow it to
# trigger events.

module Triggerable

  # The default method_scope implementation, simply returns nil, meaning all
  # method's scope will be the catch all partial scope.
  def method_scope(method_name, *args)
    return nil
  end

  # Returns a TriggerSet representing the trigger id for a method.
  def method_trigger_id(method_name, *args)
    # TODO: should we serialize this a different way?
    scope = method_scope(method_name, *args)
    # puts "TS1: #{self.reactive?} - #{scope.inspect} -- #{method_name.inspect} -- #{__id__}/#{scope} -- #{TriggerSet.new("#{__id__}/#{scope}").inspect}"
    # puts "TS: #{__id__}/#{scope}"
    return TriggerSet.new("#{__id__}/#{scope}")
  end


  # The id for this reactive value specifically
  def object_trigger_id
    return @object_trigger_id ||= ::TriggerSet.new(__id__.to_s)
    # return @object_trigger_id ||= begin
    #   scope = nil
    #   TriggerSet.new("#{__id__}/#{scope}")
    # end
  end

  # On a normal object (not reactive), the only thing in its trigger set
  # is its self.
  def trigger_set
    return object_trigger_id
  end

  # Schedules a trigger of an event (calling the callback)
  def trigger!(event, *args, &block)
    puts "TRIGGER: #{event} - #{self.inspect}"
    event = event.to_sym
    $event_registry.queue_trigger!(object_trigger_id, event, *args, &block)
  end

  # Schedules the trigger of an event on a method scope.
  def trigger_for_scope!(scope, event, *args, &block)
    event = event.to_sym

    trigger_id = method_trigger_id(*scope)

    $event_registry.queue_trigger!(trigger_id, event, *args, &block)
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