require 'volt/reactive/triggerable'
require 'volt/reactive/eventable'
require 'volt/reactive/event_registry'
require 'volt/extra_core/extra_core'
require 'volt/reactive/destructive_methods'
require 'volt/reactive/reactive_tags'
require 'volt/reactive/array_extensions'
require 'volt/reactive/string_extensions'

class Object
  def cur
    self
  end

  def reactive?
    false
  end
end

class ReactiveValue < BasicObject
  include ::Triggerable
  include ::Eventable

  # Methods we should skip wrapping the results in
  # We skip .hash because in uniq it has .to_int called on it, which needs to
  # return a Fixnum instance.
  # :hash -   needs something where .to_int can be called on it and it will
  #           return an int
  # :methods- needs to return a straight up array to work with irb tab completion
  # :eql?   - needed for .uniq to work correctly
  # :to_ary - in some places ruby expects to get an array back from this method
  SKIP_METHODS = [:id, :object_id, :hash, :methods, :eql?, :respond_to?, :respond_to_missing?, :to_ary, :to_int]#, :instance_of?, :kind_of?, :to_s, :to_str]

  # Methods provided by ReactiveValue
  PROVIDED_METHODS = [:trigger_set, :on, :remove_listener, :try, :reactive?, :cur, :cur=, :inspect, :object_trigger_id, :trigger!, :sync_trigger!]

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

  # Not 100% sure why, but we need to define this directly, it doesn't call
  # on method missing
  def ==(val)
    method_missing(:==, val)
  end

  # TODO: this is broke in opal
  def !
    method_missing(:!)
  end

  def cur(shallow=false)
    if ::Proc === @getter
      result = @getter.call
    else
      result = @getter
    end

    result = result.cur if !shallow && result.reactive?

    return result
  end

  def cur=(val)
    @getter = val

    # Trigger a changed event
    trigger!('changed')
  end

  # Returns a bloom with every trigger id in it that this ReactiveValue
  # depends on.
  # parent[0].method_trigger_id(method, *args) + object_trigger_id + parents.each(&:trigger_set) + cur.trigger_set
  # TODO: This will do N+1 by calling .cur at each step of the way.
  def trigger_set
    source_trigger_sets = [object_trigger_id]

    # All parents should be reactive, so we can just call trigger_set on them
    source_trigger_sets += @parents.map(&:trigger_set)

    # Add the trigger id for the method that this ReactiveValue was created from.
    # This lets us be alerted when the resulting value of the method may change.
    if @called_with && (method_name = @called_with[0])
      source_trigger_sets << @parents[0].method_trigger_id(method_name, *@called_with[1])
    end

    # Try to get the trigger set from the current value.
    # TODO: Should use shallow cur and get trigger set without try?
    current_obj_shallow = self.cur(true)

    if current_obj_shallow.respond_to?(:trigger_set)
      source_trigger_sets << current_obj_shallow.trigger_set
    end

    # Combine into one trigger set
    return source_trigger_sets.compact.reduce(:+)
  end

  # A reactive value's method trigger id (for a method) is just that of its current
  # value's.
  def method_trigger_id(name, *args)
    current_obj = self.cur
    if current_obj.respond_to?(:method_trigger_id)
      return current_obj.method_trigger_id(name, *args)
    else
      return nil
    end
  end


  # TODO: Will call cur more than once
  def respond_to?(name, include_private=false)
    PROVIDED_METHODS.include?(name) || cur.respond_to?(name, include_private)
  end


  # def respond_to_missing?(name, include_private=false)
  #   cur.respond_to?(name)
  # end

  # When a method is called on a ReactiveValue, instead of evaluating, a new ReactiveValue is
  # returned, which can have its .cur value called to evaluate the method.  This allows to build
  # up computation graphs that can be evaluated and re-evaluated at any time.
  def method_missing(method_name, *args, &block)
    # Unroll send into a direct call
    if method_name == :send
      method_name, *args = args
    end

    # For some methods, we pass directly to the current object.  This
    # helps ReactiveValue's be well behaved ruby citizens.
    # Also skip if this is a destructive method
    if SKIP_METHODS.include?(method_name) || __is_destructive?(method_name)
      current_obj = self.cur

      # Unwrap arguments if the method doesn't want reactive values
      pass_args = __unwrap_if_pass_reactive(args, method_name, current_obj)

      return current_obj.__send__(method_name, *pass_args, &block)
    end

    return __new_reactive_from_method_call(method_name, *args, &block)
  end

  # With returns a new ReactiveValue whose cur is the result of running the passed
  # in block.  Any reactive value's that with depends on should be passed in as arguments
  # and they will be listened for changes also.
  def with(*other_values, &block)
    getter = ::Proc.new do
      cur_val = self.cur
      block.call(cur_val)
    end

    # Add the ReactiveValue we're building from
    parents = [self]

    # Add any reactive arguments as parents
    other_values.select(&:reactive?).each do |arg|
      parents << arg
    end

    return ::ReactiveValue.new(getter, nil, nil, parents)
  end


  # Coerce lets ReactiveValue's work seamlessly with mathmatical operations.
  # For example ReactiveValue.new(5) + 10 will return ReactiveValue.new(15)
  def coerce(other)
    if other.reactive?
      return [other, self]
    else
      wrapped_object = ::ReactiveValue.new(other, [])
      return [wrapped_object, self]
    end
  end


  def __new_reactive_from_method_call(method_name, *args, &block)
    getter = ::Proc.new do
      current_obj = self.cur
      # Unwrap arguments if the method doesn't want reactive values
      pass_args = __unwrap_if_pass_reactive(args, method_name, current_obj)

      current_obj.__send__(method_name, *pass_args, &block)
    end

    # Add the ReactiveValue we're building from
    parents = [self]

    # Add any reactive arguments as parents
    args.select(&:reactive?).each do |arg|
      parents << arg
    end

    called_with = [method_name, args]
    return ::ReactiveValue.new(getter, nil, called_with, parents)
  end

  def __is_destructive?(method_name)
    last_char = method_name[-1]
    if last_char == '=' && method_name[-2] != '='
      # Method is an assignment (and not a comparator ==)
      return true
    elsif method_name.size > 1 && last_char == '!' || last_char == '<'
      # Method is tagged as destructive, or is a push ( << )
      return true
    elsif ::DestructiveMethods.might_be_destructive?(method_name)
      # Method may be destructive, check if it actually is on the current value
      # TODO: involves a call to cur
      return __check_tag(method_name, :destructive, self.cur)
    else
      return false
    end
  end

  def __unwrap_if_pass_reactive(args, method_name, current_obj)
    # Check to see if the method we're calling wants to receive reactive values.
    pass_reactive = __check_tag(method_name, :pass_reactive, current_obj)

    # Unwrap arguments if the method doesn't want reactive values
    return pass_reactive ? args : args.map{|v| v.cur }
  end

  # Method calls can be tagged so the reactive value knows
  # how to handle them.  This lets you check the state of
  # the tags.
  def __check_tag(method_name, tag_name, current_obj)
    if current_obj.respond_to?(:reactive_method_tag)
      tag = current_obj.reactive_method_tag(method_name, tag_name)

      unless tag
        # Get the tag from the all methods if its not directly specified
        tag = current_obj.reactive_method_tag(:__all_methods, tag_name)
      end

      # Evaluate now if its a proc
      tag = tag.call(method_name) if tag.class == ::Proc

      return tag
    end

    return nil
  end

  def pretty_inspect
    inspect
  end

  def inspect
    "@#{cur.inspect}"
  end
end