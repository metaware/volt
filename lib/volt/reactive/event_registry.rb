require 'volt/reactive/hash_with_reactive_tracking'

class EventRegistry
  def initialize
    @events = {}
    @trigger_queue = []
  end

  def register(event, object)
    @events[event] ||= HashWithReactiveTracking.new

    @events[event][object] = object.trigger_set
  end

  def update(object)
    @events.each_pair do |event, hash|
      if hash[object]
        # Set to an updated trigger_set
        hash[object] = object.trigger_set
      end
    end
  end

  def unregister(event, object)
    @events[event].delete(object)

    @events.delete(event) if @events[event].size == 0
  end

  # Queues a trigger for later
  def queue_trigger!(trigger_id, event, *args, &block)
    @trigger_queue << [trigger_id, event, args, block]

    if Volt.client?
      # On the client, we just flush after a timeout
      if @flush_timer
        `clearTimeout(this.flush_timer);`
      end

      @flush_timer = `setTimeout(function() {`
        flush!
      `}, 0);`
    end
  end

  # Triggers all queued_triggers
  def flush!
    trigger_queue = @trigger_queue

    # Clear the current trigger queue
    @trigger_queue = []

    trigger_queue.each do |trigger_id, event, args, block|
      objects = find_objects_for_trigger(trigger_id, event)

      objects.each do |object|
        object.sync_trigger!(event, *args, &block)

        # Update the trigger set
        # TODO: This should be queued, then called with some caching enabled
        update(object)
      end
    end

    # Call again if more events have been queued
    flush! if @trigger_queue.size > 0
  end

  # Goes through the TriggerSet's for an event and returns each the associated object
  # with this event in its trigger set.
  def find_objects_for_trigger(trigger_id, event)
    matches = []

    if (event = @events[event])
      event.each_pair do |object, trigger_set|
        # Check if the registered trigger_set has this trigger_id in it.
        if trigger_set.has_trigger?(trigger_id)
          matches << object
        end
      end
    end

    return matches
  end
end


