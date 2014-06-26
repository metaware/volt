require 'volt/controllers/reactive_accessors'
require 'volt/reactive/reactive_tags'

class Page
  class Window
    include ReactiveAccessors
    include ReactiveTags

    reactive_accessor :height, :width

    def initialize
      `$(window).resize(function() {`
        update
      `});`

      update
    end

    def update
      win = `$(window)`
      self.height = `win.height()`
      self.width = `win.width()`
    end
  end

  def self.window
    @window ||= ReactiveValue.new(Window.new)
  end
end