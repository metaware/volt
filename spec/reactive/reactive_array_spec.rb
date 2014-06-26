require 'volt/reactive/reactive_array'

describe ReactiveArray do
  before do
    $event_registry = EventRegistry.new
  end

  it "should trigger a changed event on an element when a cell is changed" do
    a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

    count = 0
    a[0].on('changed') { count += 1 }
    expect(count).to eq(0)

    a[0] = 5
    $event_registry.flush!
    expect(count).to eq(1)

    a[1] = 20
    $event_registry.flush!
    expect(count).to eq(1)
  end

  it "should trigger a change event on any ReactiveValues derived from items in the array" do
    a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

    array_one_item = a[4]

    changed = false
    array_one_item.on('changed') { changed = true }
    expect(changed).to eq(false)

    a.insert(3,21,22)
    $event_registry.flush!

    expect(changed).to eq(true)
  end

  it "should respond to size" do
    a = ReactiveArray.new([1,2,3])
    expect(a.respond_to?(:size)).to eq(true)
  end

  it "should trigger on non-lookup methods when changing a cell" do
    a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

    count = 0
    a.size.on('changed') { count += 1 }
    a.last.on('changed') { count += 1 }
    expect(count).to eq(0)
    a[0] = 5

    $event_registry.flush!

    expect(count).to eq(1)
  end

  describe "passing indexes" do
    it "should pass the index the item was inserted at" do
      model = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      count = 0
      model.on('added') do |index|
        count += 1
        expect(index).to eq(2)
      end

      expect(count).to eq(0)

      model.insert(2, 20)
      $event_registry.flush!

      expect(count).to eq(1)
    end

    it "should pass the index the item was inserted at with multiple inserted objects" do
      model = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      received = []
      model.on('added') do |index|
        received << index
      end

      model.insert(2, 20, 30)
      $event_registry.flush!

      expect(received).to eq([2, 3])
    end
  end

  it "should trigger size changes when an index is set beyond the current size" do

  end

  it "should trigger changed on methods of an array model that involve just one cell" do
    model = ReactiveValue.new(ReactiveArray.new)

    model << 1
    model << 2
    model << 3

    max = model.max
    expect(max.cur).to eq(3)
    $event_registry.flush!

    count = 0
    max.on('changed') { count += 1 }
    expect(count).to eq(0)

    model[0] = 10
    $event_registry.flush!

    expect(count).to eq(1)
    expect(max.cur).to eq(10)
  end

  it "should not trigger changed events on cells that are not being updated" do
    model = ReactiveValue.new(ReactiveArray.new)

    model << 1
    model << 2
    model << 3

    $event_registry.flush!

    index_0_count = 0
    last_count = 0
    sum_count = 0
    model[0].on('changed') { index_0_count += 1 }
    model.last.on('changed') { last_count += 1 }
    model.sum.on('changed') { sum_count += 1 }

    model[1] = 20
    $event_registry.flush!

    expect(index_0_count).to eq(0)
    expect(sum_count).to eq(1)
    expect(last_count).to eq(1)

    expect(model[0].cur).to eq(1)
    expect(model[1].cur).to eq(20)
    expect(model[2].cur).to eq(3)
    expect(model.last.cur).to eq(3)
    expect(model.sum.cur).to eq(24)

    model[2] = 100
    $event_registry.flush!

    expect(last_count).to eq(2)
  end

  it "should trigger updates when appending" do
    [:size, :length, :count, :last].each do |attribute|
      a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      count = 0
      val = a.send(attribute)
      old_value = val.cur
      val.on('changed') { count += 1 }
      expect(count).to eq(0)

      added_count = 0
      a.on('added') { added_count += 1 }
      expect(added_count).to eq(0)

      a << 4
      $event_registry.flush!

      expect(val.cur).to eq(old_value + 1)
      expect(count).to eq(1)
      expect(added_count).to eq(1)
    end
  end

  describe "real world type specs" do
    it "should let you add in another array" do
      a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      # Make sure pos[2] doesn't trigger changed
      pos_2 = a[2]
      pos_2_changed = 0
      pos_2.on('changed') { pos_2_changed += 1 }
      expect(pos_2).to eq(0)

      # Make sure pos_4 changes
      pos_4 = a[4]
      expect(pos_4.cur).to eq(nil)
      pos_4_changed = 0
      pos_4.on('changed') { pos_4_changed += 1 }

      count = 0
      a.on('added') { count += 1 }

      a += [4,5,6]
      $event_registry.flush!

      expect(a.cur).to eq([1,2,3,4,5,6])
      expect(pos_2_changed).to eq(0)
      expect(pos_4_changed).to eq(1)
      expect(pos_4).to eq(1)
      expect(count).to eq(3)
    end

    it "should trigger changed with a negative index assignment" do
      a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      count_0 = 0
      count_1 = 0

      a[0].on('changed') { count_0 += 1 }
      a[1].on('changed') { count_1 += 1 }

      a[-2] = 50
      $event_registry.flush!

      expect(count_0).to eq(0)
      expect(count_1).to eq(1)
    end

    it "should not trigger on other indicies" do
      a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      count = 0
      a[0].on('changed') { count += 1 }
      expect(count).to eq(0)

      a[1] = 5
      $event_registry.flush!

      expect(count).to eq(0)
    end

    it "should trigger from a reactive value stored in a cell" do
      a = ReactiveValue.new(2)
      b = ReactiveValue.new(ReactiveArray.new([1,2,3]))

      count = 0
      b[1].on('changed') { count += 1 }
      expect(count).to eq(0)

      a.trigger!('changed')
      $event_registry.flush!
      expect(count).to eq(0)

      b[1] = a
      $event_registry.flush!
      expect(count).to eq(1)

      a.trigger!('changed')
      $event_registry.flush!
      expect(count).to eq(2)

      a.cur = 10
      $event_registry.flush!
      expect(count).to eq(3)

      expect(b[1].cur).to eq(10)
    end
  end

  describe "concat, diff" do
    # it "should concat two arrays and trigger added/removed through" do
    #   a = ReactiveValue.new(ReactiveArray.new([1,2,3]))
    #   b = ReactiveValue.new(ReactiveArray.new([1,2,3]))
    #
    #   c = a + b
    #   $event_registry.flush!
    #
    #   count_b = 0
    #   count_c = 0
    #   # c.on('added') { count += 1 }
    #   b.on('changed') { count_b += 1 }
    #   c.on('changed') { count_c += 1 }
    #   expect(count_b).to eq(0)
    #   expect(count_c).to eq(0)
    #
    #   b << 4
    #   $event_registry.flush!
    #
    #   expect(count_b).to eq(1)
    #   expect(count_c).to eq(1)
    # end
  end

  describe "array methods" do
    it "should handle compact with events" do
      a = ReactiveValue.new(ReactiveArray.new([1,2,nil,3]))

      count = 0
      last_position = nil
      compact = a.compact
      compact.on('changed') { count += 1 }
      expect(count).to eq(0)

      a << 4
      $event_registry.flush!

      expect(count).to eq(1)
    end
  end

  it "should trigger removed when deleting" do
    a = ReactiveValue.new(ReactiveArray.new([1,2,3]))

    removed = 0
    index = nil
    a.on('removed') do |index|
      removed += 1
      expect(index).to eq(1)
    end

    expect(removed).to eq(0)

    a.delete_at(1)
    $event_registry.flush!

    expect(removed).to eq(1)
    expect(a.cur).to eq([1,3])
  end
end
