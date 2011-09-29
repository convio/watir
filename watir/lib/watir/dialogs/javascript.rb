module Watir

  class JavascriptDialog
    WINDOW_TITLES = ['Message from webpage', 'Windows Internet Explorer','Microsoft Internet Explorer']

    def initialize(container, opts={})
      @container = container
      @opts = opts
    end

    def exists?
      javascript_dialog_window.exists?
    end

    def button(value)
      javascript_dialog_window.button(:value => value)
    end

    def close
      javascript_dialog_window.close
    end

    def text
      javascript_dialog_window.text
    end

    def javascript_dialog_window
      @container.page_container.activate
      @window ||= ::RAutomation::Window.new(:title => @opts[:title] || /^(#{WINDOW_TITLES.join('|')})$/)
    end

  end
end





