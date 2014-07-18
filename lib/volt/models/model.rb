require 'volt/reactive/reactive_tags'

class Model
  include ReactiveTags

  attr_reader :path, :parent, :attributes


  def initialize(attributes={}, options={})
    self.attributes = attributes

    self.options = options
  end

  # Update the options
  def options=(options)
    @options = options
    @parent = options[:parent]
    @path = options[:path] || []
    @class_paths = options[:class_paths]
    # setup_persistor(options[:persistor])
  end

  def attributes=(values, trigger=false)
    @attributes = {}

    values.each_pair do |key, value|
      assign_attribute(key, value, true)
    end

    trigger!('changed') if trigger
  end
  alias_method :assign, :attributes=

  def inspect
    "<#{self.class.to_s}:#{object_id} #{attributes.inspect}>"
  end

  tag_all_methods do
    pass_reactive! do |method_name|
      method_name[0] == '_' && method_name[-1] == '='
    end
  end
  def method_missing(method_name, *args, &block)
    if method_name[0] == '_'
      if method_name[-1] == '='
        # Assigning an attribute with =
        assign_attribute(method_name[0..-2], args[0])
      else
        read_attribute(method_name)
      end
    else
      # Call method directly on attributes.  (since they are
      # not using _ )
      @attributes.send(method_name, *args, &block)
    end
  end

  # Do the assignment to a model and trigger a changed event
  def assign_attribute(property_name, value, skip_trigger=false)
    property_name = property_name.to_sym

    reactive = value.reactive?
    if !reactive && (value.is_a?(Hash) || value.is_a?(Array))
      # Clear existing value
      @attributes.delete(property_name)

      # Read the property and assign its attributes
      self.read_attribute(property_name).assign(value, false)
    else
      # Assign directly
      @attributes[property_name] = value
    end

    trigger_by_attribute!('changed', property_name) unless skip_trigger
  end

  # Read looks up the property, or creates it if it does not exist.
  # TODO: A read to a property that is not used can create objects that
  # are not cleaned up, this will be fixed in future releases.
  def read_attribute(method_name)
    return @attributes[method_name] ||= begin
      new_options = @options.dup.merge(parent: self, path: path + [method_name])

      if method_name.plural?
        # create a new array model
        ArrayModel.new([], new_options)
      else
        # create a regular model
        Model.new({}, new_options)
      end
    end
  end

  # Models behave like hashes, so hash properties contain their own scope (updating one should
  # not affect the others)
  def method_scope(method_name, *args)
    if method_name && method_name[0] == '_'
      return method_name.to_s.gsub('=', '').to_sym
    end

    return nil
  end

  def trigger_by_attribute!(event_name, attribute, *passed_args)
    trigger_for_scope!([attribute], event_name, *passed_args)
    trigger_for_scope!([nil], event_name, *passed_args)
  end
end