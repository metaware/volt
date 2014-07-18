require 'spec_helper'
require 'volt/models'

describe Model do
  before do
    $event_registry = EventRegistry.new
  end

  describe "basic hash like storage" do
    it "should allow _ methods to be used to store values without predefining them" do
      a = Model.new
      a._stash = 'yes'

      expect(a._stash).to eq('yes')
    end

    it "should update other values off the same model" do
      a = ReactiveValue.new(Model.new)
      count = 0
      a._name.on('changed') { count += 1 }
      expect(count).to eq(0)

      a._name = 'Bob'
      $event_registry.flush!
      expect(count).to eq(1)
    end

    it "should let you bind before something is defined" do
      a = ReactiveValue.new(Model.new)

      b = a._one + 5
      expect(b.cur.class).to eq(NoMethodError)

      count = 0
      b.on('changed') { count += 1 }
      expect(count).to eq(0)

      a._one = 1
      $event_registry.flush!

      expect(count).to eq(1)
      expect(b.cur).to eq(6)
    end

    it "should trigger changed once when a new value is assigned." do
      a = ReactiveValue.new(Model.new)

      count = 0
      a._blue.on('changed') { count += 1 }

      a._blue = 'one'
      $event_registry.flush!
      expect(count).to eq(1)

      a._blue = 'two'
      $event_registry.flush!
      expect(count).to eq(2)
    end

    it "should not call changed on other attributes" do
      a = ReactiveValue.new(Model.new)

      blue_count = 0
      green_count = 0
      a._blue.on('changed') { blue_count += 1 }
      a._green.on('changed') { green_count += 1}
      expect(blue_count).to eq(0)
      expect(green_count).to eq(0)

      a._green = 'one'
      $event_registry.flush!
      expect(blue_count).to eq(0)
      expect(green_count).to eq(1)

      a._blue = 'two'
      $event_registry.flush!
      expect(blue_count).to eq(1)
      expect(green_count).to eq(1)

    end

    it "should call change through arguments" do
      a = ReactiveValue.new(Model.new)
      a._one = 1
      a._two = 2

      c = a._one + a._two
      $event_registry.flush!

      count = 0
      c.on('changed') { count += 1 }
      expect(count).to eq(0)
      expect(c.cur).to eq(3)

      a._two = 5
      $event_registry.flush!
      expect(count).to eq(1)
      expect(c.cur).to eq(6)
    end


    it "should change the size and length when an item gets added" do
      model = ReactiveValue.new(Model.new)

      model._items << {_name: 'One'}
      size = model._items.size
      length = model._items.length
      $event_registry.flush!

      count_size = 0
      count_length = 0
      size.on('changed') { count_size += 1 }
      length.on('changed') { count_length += 1 }
      expect(count_size).to eq(0)
      expect(count_length).to eq(0)

      model._items << {_name: 'Two'}
      $event_registry.flush!

      expect(count_size).to eq(1)
      expect(count_length).to eq(1)
    end


    it "should add doubly nested arrays" do
      model = ReactiveValue.new(Model.new)

      model._items << {_name: 'Cool', _lists: []}
      model._items[0]._lists << {_name: 'worked'}
      expect(model._items[0]._lists[0]._name.cur).to eq('worked')
    end
  end

  describe "wrapping values" do

    it "should make pushed subarrays into ArrayModels" do
      model = ReactiveValue.new(Model.new)

      model._items << {_name: 'Test', _lists: []}
      expect(model._items[0]._lists.cur.class).to eq(ArrayModel)
    end

  end

  describe "storing reactive values" do
    it "should allow a reactive value to be assigned as a value in a model" do
      model = ReactiveValue.new(Model.new)
      rv = ReactiveValue.new(10)

      model._cool = rv

      expect(model._cool.cur).to eq(10)

      rv.cur = 20

      expect(model._cool.cur).to eq(20)
    end
  end

  describe "events" do

    it "should let you register events before it expands" do
      a = ReactiveValue.new(Model.new)
      count = 0
      a._something.on('changed') { count += 1 }
      expect(count).to eq(0)

      a._something = 20
      $event_registry.flush!
      expect(count).to eq(1)
    end

    it "should trigger a size change when a new property is assigned" do
      a = ReactiveValue.new(Model.new)
      a._one = 1
      $event_registry.flush!

      count = 0
      a.size.on('changed') { count += 1 }
      expect(count).to eq(0)
      expect(a.size.cur).to eq(1)

      a._two = 2
      $event_registry.flush!

      expect(count).to eq(1)

      expect(a.size.cur).to eq(2)
    end


    # it "should trigger changed through concat" do
    #   model = ReactiveValue.new(Model.new)
    #
    #   concat = model._one + model._two
    #   $event_registry.flush!
    #
    #   count = 0
    #   concat.on('changed') { count += 1 }
    #   expect(count).to eq(0)
    #
    #   model._one = 'one'
    #   $event_registry.flush!
    #   expect(count).to eq(1)
    #
    #   model._two = 'two'
    #   $event_registry.flush!
    #   expect(count).to eq(2)
    #
    #   expect(concat.cur).to eq('onetwo')
    # end


    it "should trigger changed for any indicies after a deleted index" do
      model = ReactiveValue.new(Model.new)

      model._items << {_name: 'One'}
      model._items << {_name: 'Two'}
      model._items << {_name: 'Three'}
      $event_registry.flush!

      count = 0
      model._items[2].on('changed') { count += 1 }
      expect(count).to eq(0)

      puts "--------"
      model._items.delete_at(1)
      puts "---------"
      $event_registry.flush!
      expect(count).to eq(1)
    end
  end
end