module Watir
  # Base class for html elements.
  # This is not a class that users would normally access.
  class Element # Wrapper
    include ElementExtensions
    include Exception
    include Container # presumes @container is defined
    attr_accessor :container

    # number of spaces that separate the property from the value in the to_s method
    TO_S_SIZE = 14

    def self.inherited subclass
      class_name = Watir::Util.demodulize(subclass.to_s)
      method_name = Watir::Util.underscore(class_name)
      Watir::Container.module_eval <<-RUBY
        def #{method_name}(how={}, what=nil)
          #{class_name}.new(self, how, what)
        end

        def #{method_name}s(how={}, what=nil)
          #{class_name}s.new(self, how, what)
        end         
      RUBY
    end

    # ole_object - the ole object for the element being wrapped
    def initialize(ole_object)
      @o = ole_object
      @original_color = nil
    end

    def locate
      return if [Element, TableBodies].include? self.class
      tag = self.class.const_defined?(:TAG) ? self.class::TAG : self.class.name.split("::").last
      @o = @container.tagged_element_locator(tag, @how, @what).locate
    end    

    # Return the ole object, allowing any methods of the DOM that Watir doesn't support to be used.
    def ole_object
      @o
    end

    def ole_object=(o)
      @o = o
    end

    def inspect
      '#<%s:0x%x located=%s how=%s what=%s>' % [self.class, hash*2, !!ole_object, @how.inspect, @what.inspect]
    end

    private
    def self.def_wrap(ruby_method_name, ole_method_name=nil)
      ole_method_name = ruby_method_name unless ole_method_name
      class_eval "def #{ruby_method_name}
                          assert_exists
                          ole_object.invoke('#{ole_method_name}')
                        end"
    end

    def self.def_wrap_guard(method_name)
      class_eval "def #{method_name}
                          assert_exists
                          begin
                            ole_object.invoke('#{method_name}')
                          rescue
                            ''
                          end
                        end"
    end


    public
    def assert_exists
      locate
      unless ole_object
        raise UnknownObjectException.new(
                Watir::Exception.message_for_unable_to_locate(@how, @what))
      end
    end

    def assert_enabled
      unless enabled?
        raise ObjectDisabledException, "object #{@how} and #{@what} is disabled"
      end
    end

    # return the name of the element (as defined in html)
    def_wrap_guard :name
    # return the id of the element
    def_wrap_guard :id
    # return whether the element is disabled
    def_wrap :disabled
    alias disabled? disabled
    # return the value of the element
    def_wrap_guard :value
    # return the title of the element
    def_wrap_guard :title

    def_wrap_guard :currentstyle
    # return current style instead of the inline style of the element
    alias style currentstyle

    def_wrap_guard :alt
    def_wrap_guard :src

    # return the type of the element
    def_wrap_guard :type # input elements only
    # return the url the link points to
    def_wrap :href # link only
    # return the ID of the control that this label is associated with
    def_wrap :for, :htmlFor # label only
    # return the class name of the element
    # raise an ObjectNotFound exception if the object cannot be found
    def_wrap :class_name, :className
    # return the unique COM number for the element
    def_wrap :unique_number, :uniqueNumber
    # Return the outer html of the object - see http://msdn.microsoft.com/workshop/author/dhtml/reference/properties/outerhtml.asp?frame=true
    def_wrap :html, :outerHTML

    def_wrap_guard :has_cell

    def has_cell x
      self.cell(:text, x).exists?
    end


    # return the text before the element
    def before_text # label only
      assert_exists
      begin
        ole_object.getAdjacentText("afterEnd").strip
      rescue
        ''
      end
    end

    # return the text after the element
    def after_text # label only
      assert_exists
      begin
        ole_object.getAdjacentText("beforeBegin").strip
      rescue
        ''
      end
    end

    # Return the innerText of the object
    # Raise an ObjectNotFound exception if the object cannot be found
    def text
      assert_exists
      return ole_object.innerText.strip
    end

    # IE9 only returns empty string for ole_object.name for non-input elements
    # so get at it through the attribute which will make the matchers work
    def name
      assert_exists
      ole_object.getAttribute('name') || ''
    end

    def __ole_inner_elements
      assert_exists
      return ole_object.all
    end

    def document
      assert_exists
      return ole_object
    end

    # Return the element immediately containing self. 
    def parent
      assert_exists
      result = Element.new(ole_object.parentelement)
      result.set_container self
      result
    end

    include Comparable

    def <=> other
      assert_exists
      other.assert_exists
      ole_object.sourceindex <=> other.ole_object.sourceindex
    end

    # Return true if self is contained earlier in the html than other. 
    alias :before? :<
    # Return true if self is contained later in the html than other. 
    alias :after? :>

    def typingspeed
      @container.typingspeed
    end

    def type_keys
      return @container.type_keys if @type_keys.nil?
      @type_keys
    end

    def activeObjectHighLightColor
      @container.activeObjectHighLightColor
    end

    # Return an array with many of the properties, in a format to be used by the to_s method
    def string_creator
      n = []
      n <<   "type:".ljust(TO_S_SIZE) + self.type
      n <<   "id:".ljust(TO_S_SIZE) +         self.id.to_s
      n <<   "name:".ljust(TO_S_SIZE) +       self.name.to_s
      n <<   "value:".ljust(TO_S_SIZE) +      self.value.to_s
      n <<   "disabled:".ljust(TO_S_SIZE) +   self.disabled.to_s
      return n
    end

    private :string_creator

    # Display basic details about the object. Sample output for a button is shown.
    # Raises UnknownObjectException if the object is not found.
    #      name      b4
    #      type      button
    #      id         b5
    #      value      Disabled Button
    #      disabled   true
    def to_s
      assert_exists
      return string_creator.join("\n")
    end

    # This method is responsible for setting and clearing the colored highlighting on the currently active element.
    # use :set   to set the highlight
    #   :clear  to clear the highlight
    # TODO: Make this two methods: set_highlight & clear_highlight
    # TODO: Remove begin/rescue blocks
    def highlight(set_or_clear)
      if set_or_clear == :set
        begin
          @original_color ||= ole_object.style.backgroundColor
          ole_object.style.backgroundColor = @container.activeObjectHighLightColor
        rescue
          @original_color = nil
        end
      else
        begin
          ole_object.style.backgroundColor = @original_color if @original_color
        rescue
          # we could be here for a number of reasons...
          # e.g. page may have reloaded and the reference is no longer valid
        ensure
          @original_color = nil
        end
      end
    end

    private :highlight

    #   This method clicks the active element.
    #   raises: UnknownObjectException  if the object is not found
    #   ObjectDisabledException if the object is currently disabled
    def click
      click!
      @container.wait
    end

    def click_if_exists
      click if exists?
    end

    def replace_method(method)
      method == 'click' ? 'click!' : method
    end
    private :replace_method

    def build_method(method_name, *args)
      arguments = args.map do |argument|
        if argument.is_a?(String)
          argument = "'#{argument}'"  
        else
          argument = argument.inspect
        end
      end
      "#{replace_method(method_name)}(#{arguments.join(',')})"
    end
    private :build_method

    def generate_ruby_code(element, method_name, *args)
      element = "#{self.class}.new(#{@page_container.attach_command}, :unique_number, #{self.unique_number})"
      method = build_method(method_name, *args)
      ruby_code = "$:.unshift(#{$LOAD_PATH.map {|p| "'#{p}'" }.join(").unshift(")});" <<
                    "require '#{File.expand_path(File.dirname(__FILE__))}/core';#{element}.#{method};"
      return ruby_code
    end
    private :generate_ruby_code

    def spawned_no_wait_command(command)
      command = "-e #{command.inspect}"
      unless $DEBUG
        "start rubyw #{command}"
      else
        puts "#no_wait command:"
        command = "ruby #{command}"
        puts command
        command
      end
    end

    private :spawned_no_wait_command

    def click!
      assert_exists
      assert_enabled

      highlight(:set)
      # Not sure why but in IE9 Document mode, passing a parameter
      # to click seems to work. Firing the onClick event breaks other tests
      # so this seems to be the safest change and also works fine in IE8
      ole_object.click(0)
      highlight(:clear)
    end

    # Flash the element the specified number of times.
    # Defaults to 10 flashes.
    def flash number=10
      assert_exists
      number.times do
        highlight(:set)
        sleep 0.05
        highlight(:clear)
        sleep 0.05
      end
      nil
    end

    # Executes a user defined "fireEvent" for objects with JavaScript events tied to them such as DHTML menus.
    #   usage: allows a generic way to fire javascript events on page objects such as "onMouseOver", "onClick", etc.
    #   raises: UnknownObjectException  if the object is not found
    #           ObjectDisabledException if the object is currently disabled
    def fire_event(event)
      assert_exists
      assert_enabled
      highlight(:set)
      dispatch_event(event)
      @container.wait
      highlight(:clear)
    end

    def dispatch_event(event)
      if IE.version_parts.first.to_i >= 9
        if @container.page_container.document_mode.to_i >= 9
          ole_object.dispatchEvent(create_event(event))
        else
          ole_object.fireEvent(event)
        end
      else
        ole_object.fireEvent(event)
      end
    end

    def create_event(event)
       event =~ /on(.*)/i
       event = $1 if $1
       event.downcase!
       # See http://www.howtocreate.co.uk/tutorials/javascript/domevents
       case event
         when 'abort', 'blur', 'change', 'error', 'focus', 'load',
              'reset', 'resize', 'scroll', 'submit', 'unload'
           event_name = :initEvent
           event_type = 'HTMLEvents'
           event_args = [event, true, true]
         when 'select'
           event_name = :initUIEvent
           event_type = 'UIEvent'
           event_args = [event, true, true, @container.page_container.document.parentWindow.window,0]
         when 'keydown', 'keypress', 'keyup'
           event_name = :initKeyboardEvent
           event_type = 'KeyboardEvent'
           # 'type', bubbles, cancelable, windowObject, ctrlKey, altKey, shiftKey, metaKey, keyCode, charCode
           event_args = [event, true, true, @container.page_container.document.parentWindow.window, false, false, false, false, 0, 0]
         when 'click', 'dblclick', 'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup',
              'contextmenu', 'drag', 'dragstart', 'dragenter', 'dragover', 'dragleave', 'dragend', 'drop', 'selectstart'
           event_name = :initMouseEvent
           event_type = 'MouseEvents'
           # 'type', bubbles, cancelable, windowObject, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget
           event_args = [event, true, true, @container.page_container.document.parentWindow.window, 1, 0, 0, 0, 0, false, false, false, false, 0, @container.page_container.document]
         else
           raise UnhandledEventException, "Don't know how to trigger event '#{event}'"
       end
       event = @container.page_container.document.createEvent(event_type)
       event.send event_name, *event_args
       event
     end

    # This method sets focus on the active element.
    #   raises: UnknownObjectException  if the object is not found
    #           ObjectDisabledException if the object is currently disabled
    def focus
      assert_exists
      assert_enabled
      ole_object.focus(0)
    end

    # Returns whether this element actually exists.
    def exists?
      begin
        locate
      rescue WIN32OLERuntimeError, UnknownObjectException
        @o = nil
      end
      !!@o
    end

    alias :exist? :exists?

    # Returns true if the element is enabled, false if it isn't.
    #   raises: UnknownObjectException  if the object is not found
    def enabled?
      assert_exists
      return ! disabled
    end

    # If any parent element isn't visible then we cannot write to the
    # element. The only realiable way to determine this is to iterate
    # up the DOM element tree checking every element to make sure it's
    # visible.
    def visible?
      # Now iterate up the DOM element tree and return false if any
      # parent element isn't visible 
      assert_exists
      object = @o
      while object
        begin
          if object.currentstyle.invoke('visibility') =~ /^hidden$/i
            return false
          end
          if object.currentstyle.invoke('display') =~ /^none$/i
            return false
          end
        rescue WIN32OLERuntimeError
        end
        object = object.parentElement
      end
      true
    end

    # Get attribute value for any attribute of the element.
    # Returns null if attribute doesn't exist.
    def attribute_value(attribute_name)
      assert_exists
      return ole_object.getAttribute(attribute_name)
    end

    def method_missing(method_name, *args, &block)
      if method_name.to_s =~ /(.*)_no_wait/ && self.respond_to?($1)
        assert_exists
        assert_enabled
        highlight(:set)
        ruby_code = generate_ruby_code(self, $1, *args)
        system(spawned_no_wait_command(ruby_code))
        highlight(:clear)
      else
        super
      end
    end

    def nextsibling
      assert_exists
      result = Element.new(ole_object.nextSibling)
      result.set_container self
      result
    end

    def prevsibling
      assert_exists
      result = Element.new(ole_object.previousSibling)
      result.set_container self
      result
    end
  end

  class ElementMapper # Still to be used
    include Container

    def initialize wrapper_class, container, how, what
      @wrapper_class = wrapper_class
      set_container
      @how = how
      @what = what
    end

    def method_missing method, *args
      locate
      @wrapper_class.new(@o).send(method, *args)
    end
  end
end  
