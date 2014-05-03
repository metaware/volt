require 'volt/reactive/triggerable'
require 'volt/reactive/eventable'

class ReactiveValue < BasicObject
  include Triggerable
  include Eventable

  def initialize(getter, setter=nil, scope=nil, parents=[])
    @getter = getter
    @setter = setter
    @scope = scope
    @parents = parents
  end

  def cur
    return @getter.call
  end

  def pretty_inspect
    inspect
  end

  def inspect
    "@#{cur.inspect}"
  end
end