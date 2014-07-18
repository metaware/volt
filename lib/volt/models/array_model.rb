require 'volt/reactive/reactive_array'

class ArrayModel < ReactiveArray
  attr_reader :path, :parent

  def initialize(array=[], options={})
    self.array = array

    @options = options
    @parent = options[:parent]
    @path = options[:path] || []
  end

  def array=(array, trigger=false)
    @array = []

    array.each_with_index do |value, index|
      assign_cell(index, value, true)
    end

    trigger!('changed') if trigger
  end
  alias_method :assign, :array=


  def <<(value)
    index = @array.size

    assign_cell(index, value)
    # trigger!('changed')
  end

  # Assign through assign_cell so the values get wrapped
  alias_method :__old_assign__, :[]=
  def []=(index, value)
    assign_cell(index, value)
  end

  # Do the assignment to a model and trigger a changed event
  def assign_cell(index, value, skip_trigger=false)
    puts "ASSIGN CELL: #{index} - #{value}"
    reactive = value.reactive?
    if !reactive && value.is_a?(Hash)
      # Read the property and assign its attributes
      self.read_cell(index).assign(value, false)
    else
      # Assign directly
      # TODO: This will trigger, might want to pass skipping
      __old_assign__(index, value, skip_trigger)
    end

    # Provided by ReactiveArray
    trigger_for_index!('changed', index) unless skip_trigger
  end


  def [](index)
    read_cell(index)
  end

  # reads the cell at the specified index, if one does not exist there, one is created
  def read_cell(index)
    value = @array[index]
    return value if value

    new_options = @options.dup.merge(parent: self, path: path + [[:[], index]])

    # create a regular model
    value = Model.new({}, new_options)

    # Save back to model
    __old_assign__(index, value)

    return value
  end


end