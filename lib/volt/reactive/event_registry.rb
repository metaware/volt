class EventRegistry
  def initialize
    @events = {}
    @trigger_queue = []
  end

  def register(event, trigger_set, object)
    @events[event] ||= {}
    @events[event][object] = trigger_set
  end

  def unregister(event, object)
    @events[event].delete(object)

    @events.delete(event) if @events[event].size == 0
  end

  # Queues a trigger for later
  def queue_trigger!(trigger_id, event, *args, &block)
    @trigger_queue << [trigger_id, event, args, block]
  end

  # Triggers all queued_triggers
  def flush!
    @trigger_queue.each do |trigger_id, event, args, block|
      objects = find_objects_for_trigger(trigger_id, event)

      objects.each do |object|
        object.sync_trigger(event, *args, &block)
      end
    end
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

    return matched
  end
end