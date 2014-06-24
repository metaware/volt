require 'volt/models'

describe Model do
  before do
    $event_registry = EventRegistry.new
  end

  it "should create a buffer from an ArrayModel" do
    page = ReactiveValue.new(Model.new)

    page._items = []
  end
end