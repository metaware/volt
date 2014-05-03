require 'volt/reactive/triggerable'
require 'volt/reactive/eventable'
require 'volt/reactive/event_registry'
require 'volt/extra_core/extra_core'

class ReactiveValue < BasicObject
  include ::Triggerable
  include ::Eventable

  def initialize(getter, setter=nil, called_with=nil, parents=[])
    @getter = getter
    @setter = setter
    @called_with = called_with
    @parents = parents
  end

  # Provide puts for BasicObject
  def puts(*args)
    ::Object.send(:puts, *args)
  end

  # this value is reactive
  def reactive?
    true
  end

  def cur
    if ::Proc === @getter
      return @getter.call
    else
      return @getter
    end
  end

  # Returns a bloom with every trigger id in it that this ReactiveValue
  # depends on.
  def trigger_set
    source_trigger_sets = [object_trigger_id]

    parents_trigger_sets = @parents.map do |parent|
      parent.try(:trigger_set)
    end.compact

    return source_trigger_sets.reduce(:+)
  end

  # When a method is called on a ReactiveValue, instead of evaluating, a new ReactiveValue is
  # returned, which can have its .cur value called to evaluate the method.  This allows to build
  # up computation graphs that can be evaluated and re-evaluated at any time.
  # def method_missing(method_name, *args, &block)
  #
  #
  # end

  def pretty_inspect
    inspect
  end

  def inspect
    "@#{cur.inspect}"
  end
end