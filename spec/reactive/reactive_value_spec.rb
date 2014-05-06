require 'volt/reactive/reactive_value'

class TestTriggerable
  include Triggerable
end

class TestMethodScope
  include Triggerable

  def a
    0
  end

  def b
    1
  end

  def method_scope(method_name)
    puts "MS: #{method_name.inspect}"
    return method_name
  end
end

describe ReactiveValue do
  before do
    $event_registry = EventRegistry.new
  end

  # it "should trigger an event on its self" do
  #   a = ReactiveValue.new(5)
  #   count = 0
  #   listener = a.on('changed') { count += 1 }
  #   expect(count).to eq(0)
  #
  #   a.trigger!('changed')
  #   $event_registry.flush!
  #
  #   expect(count).to eq(1)
  # end
  #
  # it "should not trigger an event after the listener has been removed" do
  #   a = ReactiveValue.new(5)
  #   count = 0
  #   listener = a.on('changed') { count += 1 }
  #   expect(count).to eq(0)
  #
  #   listener.remove
  #
  #   a.trigger!('changed')
  #   $event_registry.flush!
  #
  #   expect(count).to eq(0)
  # end
  #
  # it "should update current values" do
  #   a = ReactiveValue.new(0)
  #   expect(a.cur).to eq(0)
  #
  #   a.cur = 1
  #   expect(a.cur).to eq(1)
  # end
  #
  # it "should track dependencies and trigger on dependants" do
  #   a = ReactiveValue.new(1)
  #   b = a + 5
  #
  #   count = 0
  #   b.on('changed') { count += 1}
  #   expect(count).to eq(0)
  #
  #   a.trigger!('changed')
  #   $event_registry.flush!
  #
  #   expect(count).to eq(1)
  # end
  #
  # it "should trigger up through nested reactive values" do
  #   a = ReactiveValue.new(1)
  #   b = ReactiveValue.new(a)
  #
  #   count = 0
  #   b.on('changed') { count += 1 }
  #   expect(count).to eq(0)
  #
  #   a.trigger!('changed')
  #   $event_registry.flush!
  #   expect(count).to eq(1)
  # end
  #
  # it "should trigger from a triggerable object" do
  #   a = TestTriggerable.new
  #   b = ReactiveValue.new(a)
  #
  #   count = 0
  #   b.on('changed') { count += 1 }
  #   expect(count).to eq(0)
  #
  #   a.trigger!('changed')
  #   $event_registry.flush!
  #
  #   expect(count).to eq(1)
  # end

  it "should trigger on a scope" do
    test_method_scope = TestMethodScope.new
    a = ReactiveValue.new(test_method_scope).a
    # b = ReactiveValue.new(test_method_scope).b

    count_a = 0
    count_b = 0
    a.on('changed') { count_a += 1 }
    # b.on('changed') { count_b += 1 }
    expect(count_a).to eq(0)
    # expect(count_b).to eq(0)

    test_method_scope.trigger_for_scope!(:a, 'changed')
    $event_registry.flush!

    expect(count_a).to eq(1)
    # expect(count_b).to eq(0)
  end
end