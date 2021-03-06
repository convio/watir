module Watir
  
  class InputElement < Element #:nodoc:all
    def locate
      locator_or_element = @container.input_element_locator(@how, @what, self.class::INPUT_TYPES, self.class)
      @o = locator_or_element.is_a?(WIN32OLE) ? locator_or_element : locator_or_element.locate
    end
    def initialize(container, how, what)
      set_container container
      @how = how
      @what = what
      super(nil)
    end

    def value=(x)
      case x
        when Regexp
        set(x)
      else
        set(x.to_s)
      end
    end
  end

  #
  # Input: Select
  #
  
  # This class is the way in which select boxes are manipulated.
  # Normally a user would not need to create this object as it is returned by the Watir::Container#select_list method
  class SelectList < InputElement
    #:stopdoc:
    INPUT_TYPES = ["select-one", "select-multiple"]
    #exposed to Option class
    attr_accessor :o
    #:startdoc:

    # This method clears the selected items in the select box
    def clear
      assert_exists
      highlight(:set)
      wait = false
      @o.each do |selectBoxItem|
        if selectBoxItem.selected
          selectBoxItem.selected = false
          wait = true
        end
      end
      @container.wait if wait
      highlight(:clear)
    end

    
    # This method selects an item, or items in a select box, by text.
    # Raises NoValueFoundException   if the specified value is not found.
    #  * item   - the thing to select, string or reg exp
    def select(item)
      case item
        when Array
        item.each { |i| select_item_in_select_list(:text, i) }
      else
        select_item_in_select_list(:text, item)
      end
    end
    alias :set :select
       
    # Selects an item, or items in a select box, by value.
    # Raises NoValueFoundException   if the specified value is not found.
    #  * item   - the value of the thing to select, string, reg exp
    def select_value(item)
      select_item_in_select_list(:value, item)
    end
    
    # BUG: Should be private
    # Selects something from the select box
    #  * name  - symbol  :value or :text - how we find an item in the select box
    #  * item  - string or reg exp - what we are looking for
    def select_item_in_select_list(attribute, value) #:nodoc:
      assert_exists
      highlight(:set)
      found = false

      value = value.to_s unless [Regexp, String].any? { |e| value.kind_of? e }

      @container.log "Setting box #{@o.name} to #{attribute.inspect} => #{value.inspect}"
      @o.each do |option| # items in the list
        if value.matches(option.invoke(attribute.to_s))
          if option.selected
            found = true
            break
          else
            option.selected = true
            dispatch_event("onChange")
            @container.wait
            found = true
            break
          end
        end
      end

      unless found
        raise NoValueFoundException, "No option with #{attribute.inspect} of #{value.inspect} in this select element"
      end
      highlight(:clear)
    end
    
    # Returns array of all text items displayed in a select box
    # An empty array is returned if the select box has no contents.
    # Raises UnknownObjectException if the select box is not found
    def options 
      assert_exists
      @container.log "There are #{@o.length} items"
      returnArray = []
      @o.each { |thisItem| returnArray << thisItem.text }
      return returnArray
    end
    
    # Returns array of the selected text items in a select box
    # Raises UnknownObjectException if the select box is not found.
    def selected_options
      assert_exists
      returnArray = []
      @container.log "There are #{@o.length} items"
      @o.each do |thisItem|
        if thisItem.selected
          @container.log "Item (#{thisItem.text}) is selected"
          returnArray << thisItem.text
        end
      end
      return returnArray
    end

    # Does the SelectList include the specified option (text)?
    def include? text_or_regexp
      getAllContents.grep(text_or_regexp).size > 0
    end

    # Is the specified option (text) selected? Raises exception of option does not exist.
    def selected? text_or_regexp
      unless includes? text_or_regexp
        raise UnknownObjectException, "Option #{text_or_regexp.inspect} not found."
      end

      getSelectedItems.grep(text_or_regexp).size > 0
    end

    # this method provides the access to the <tt><option></tt> item in select_list
    #
    # Usage example:
    #
    # Given the following html:
    #
    #   <select  id="gender">
    #     <option value="U">Unknown</option>
    #     <option value="M" selected>Male</option>
    #     <option value="F">Female</option>
    #   </select>
    #
    # get the +value+ attribute of option with visible +text+ 'Female'
    #   browser.select_list(:id, 'gender').option(:text, 'Female').value #=> 'F'
    # or find out if the +value+ 'M' is selected
    #   browser.select_list(:id, 'gender').option(:value, 'M').selected #=> true
    #
    #  * attribute  - Symbol :value, :text or other attribute - how we find an item in the select box
    #  * value  - string or reg exp - what we are looking for
    def option(attribute, value)
      assert_exists
      Option.new(self, attribute, value)
    end
  end
  
  module OptionAccess
    # text of SelectList#option
    def text
      @option.text
    end
    # value of SelectList#option
    def value
      @option.value
    end
    # return true if SelectList#option is selected, else false
    def selected
      @option.selected
    end
  end
  
  class OptionWrapper #:nodoc:all
    include OptionAccess
    def initialize(option)
      @option = option
    end
  end
  
  # An item in a select list.
  # Normally a user would not need to create this object as it is returned by the Watir::SelectList#option method
  class Option
    include OptionAccess
    include Watir::Exception
    def initialize(select_list, attribute, value)
      @select_list = select_list
      @how = attribute
      @what = value
      @option = nil
      
      unless [:text, :value, :label].include? attribute
        raise MissingWayOfFindingObjectException,
                    "Option does not support attribute #{@how}"
      end
      @select_list.o.each do |option| # items in the list
        if value.matches(option.invoke(attribute.to_s))
          @option = option
          break
        end
      end
      
    end
    def assert_exists
      unless @option
        raise UnknownObjectException,
                    "Unable to locate an option using #{@how} and #{@what}"
      end
    end
    private :assert_exists
    
    # select the accessed option in select_list
    def select
      assert_exists
      @select_list.select_item_in_select_list(@how, @what)
    end
  end
  
  # 
  # Input: Button
  #
  
  # Returned by the Watir::Container#button method
  class Button < InputElement
    #:stopdoc:
    INPUT_TYPES = ["button", "submit", "image", "reset"]
    #:startdoc:

    def value=(x)
      click if x
    end
  end

  #
  # Input: Text
  #
  
  # This class is the main class for Text Fields
  # Normally a user would not need to create this object as it is returned by the Watir::Container#text_field method
  class TextField < InputElement
    #:stopdoc:
    INPUT_TYPES = ["text", "password", "textarea"]
    
    def_wrap_guard :size

    # Returns true or false if the text field is read only.
    #   Raises UnknownObjectException if the object can't be found.
    def_wrap :readonly?, :readOnly

    #:startdoc:
    
    # return number of maxlength attribute
    def maxlength
      assert_exists unless @o
      begin
        ole_object.invoke('maxlength').to_i
      rescue WIN32OLERuntimeError
        0
      end
    end
        
    
    def text_string_creator
      n = []
      n << "length:".ljust(TO_S_SIZE) + self.size.to_s
      n << "max length:".ljust(TO_S_SIZE) + self.maxlength.to_s
      n << "read only:".ljust(TO_S_SIZE) + self.readonly?.to_s
      n
    end
    private :text_string_creator
    
    def to_s
      assert_exists
      r = string_creator
      r += text_string_creator
      r.join("\n")
    end
    
    def assert_not_readonly #:nodoc:
      if self.readonly?
        raise ObjectReadOnlyException, 
          "Textfield #{@how} and #{@what} is read only."
      end
    end
    
    # Returns true if the text field contents is matches the specified target,
    # which can be either a string or a regular expression.
    #   Raises UnknownObjectException if the object can't be found
    #--
    # I vote for deprecating this
    # we should use text_field().text.include?(some) or text.match(/some/) instead of this method
    def verify_contains(target) #:nodoc:
      assert_exists
      if target.kind_of? String
        return true if self.value == target
      elsif target.kind_of? Regexp
        return true if self.value.match(target) != nil
      end
      return false
    end
    
    # Drag the entire contents of the text field to another text field
    #  19 Jan 2005 - It is added as prototype functionality, and may change
    #   * destination_how   - symbol, :id, :name how we identify the drop target
    #   * destination_what  - string or regular expression, the name, id, etc of the text field that will be the drop target
    def drag_contents_to(destination_how, destination_what)
      assert_exists
      destination = @container.text_field(destination_how, destination_what)
      unless destination.exists?
        raise UnknownObjectException, "Unable to locate destination using #{destination_how } and #{destination_what } "
      end
      
      @o.focus(0)
      @o.select(0)
      value = self.value
      
      dispatch_event("onSelect")
      dispatch_event("ondragstart")
      dispatch_event("ondrag")
      destination.dispatch_event("onDragEnter")
      destination.dispatch_event("onDragOver")
      destination.dispatch_event("ondrop")
      
      dispatch_event("ondragend")
      destination.value = destination.value + value.to_s
      self.value = ""
    end
    
    # Clears the contents of the text box.
    #   Raises UnknownObjectException if the object can't be found
    #   Raises ObjectDisabledException if the object is disabled
    #   Raises ObjectReadOnlyException if the object is read only
    def clear
      assert_exists
      assert_enabled
      assert_not_readonly
      
      highlight(:set)
      
      @o.scrollIntoView
      @o.focus(0)
      @o.select(0)
      dispatch_event("onSelect")
      @o.value = ""
      dispatch_event("onKeyPress")
      dispatch_event("onChange")
      @container.wait
      highlight(:clear)
    end
    
    # Appends the specified string value to the contents of the text box.
    #   Raises UnknownObjectException if the object cant be found
    #   Raises ObjectDisabledException if the object is disabled
    #   Raises ObjectReadOnlyException if the object is read only
    def append(value)
      assert_exists
      assert_enabled
      assert_not_readonly
      
      highlight(:set)
      @o.scrollIntoView
      @o.focus(0)
      type_by_character(value)
      highlight(:clear)
    end
    
    # Sets the contents of the text box to the specified text value
    #   Raises UnknownObjectException if the object cant be found
    #   Raises ObjectDisabledException if the object is disabled
    #   Raises ObjectReadOnlyException if the object is read only
    def set(value)
      assert_exists
      assert_enabled
      assert_not_readonly

      highlight(:set)
      @o.scrollIntoView
      if type_keys
	      @o.focus(0)
	      @o.select(0)
	      dispatch_event("onSelect")
	      dispatch_event("onKeyPress")
	      @o.value = ""
	      type_by_character(value)
	      dispatch_event("onChange")
	      dispatch_event("onBlur")
	    else
				@o.value = limit_to_maxlength(value)
	    end
      highlight(:clear)
    end

    # Sets the value of the text field directly.
    # It causes no events to be fired or exceptions to be raised,
    # so generally shouldn't be used.
    # It is preffered to use the set method.
    def value=(v)
      assert_exists
      @o.value = v.to_s
    end

    def requires_typing #:nodoc:
    	@type_keys = true
    	self
    end
    def abhors_typing #:nodoc:
    	@type_keys = false
    	self
    end

    private

    # Type the characters in the specified string (value) one by one.
    # It should not be used externally.
    #   * value - string - The string to enter into the text field
    def type_by_character(value)
      value = limit_to_maxlength(value)
      characters_in(value) do |c|
        sleep @container.typingspeed
        @o.value = @o.value.to_s + c
        dispatch_event("onKeyDown")
        dispatch_event("onKeyPress")
        dispatch_event("onKeyUp")
      end
    end
    
    # Supports double-byte characters
    def characters_in(value, &blk) 
      if RUBY_VERSION =~ /^1\.8/
        index = 0
        while index < value.length 
          len = value[index] > 128 ? 2 : 1
          yield value[index, len]
          index += len
        end 
      else
        value.each_char(&blk)
      end
    end
    
    # Return the value (a string), limited to the maxlength of the element.
    def limit_to_maxlength(value)
      return value if @o.invoke('type') =~ /textarea/i # text areas don't have maxlength
      if value.length > maxlength
        value = value[0 .. maxlength - 1]
        @container.log " Supplied string is #{value.length} chars, which exceeds the max length (#{maxlength}) of the field. Using value: #{value}"
      end
      value
    end
  end
  
  # this class can be used to access hidden field objects
  # Normally a user would not need to create this object as it is returned by the Watir::Container#hidden method
  class Hidden < TextField
    #:stopdoc:
    INPUT_TYPES = ["hidden"]
    #:startdoc:
    
    # set is overriden in this class, as there is no way to set focus to a hidden field
    def set(n)
      self.value = n
    end
    
    # override the append method, so that focus isnt set to the hidden object
    def append(n)
      self.value = self.value.to_s + n.to_s
    end
    
    # override the clear method, so that focus isnt set to the hidden object
    def clear
      self.value = ""
    end
    
    # this method will do nothing, as you cant set focus to a hidden field
    def focus
    end
    
    # Hidden element is never visible - returns false.
    def visible?
      assert_exists
      false
    end
    
  end

  # This class contains common methods to both radio buttons and check boxes.
  # Normally a user would not need to create this object as it is returned by the Watir::Container#checkbox or by Watir::Container#radio methods
  #--
  # most of the methods available to this element are inherited from the Element class
  class RadioCheckCommon < InputElement
    def locate #:nodoc:
      if @value
        case @how
          when Hash
            @how.update(:value => @value)
          else
            @how = {@how=>@what, :value => @value}
            @what = nil
        end
      end
      locator_or_element = @container.input_element_locator(@how, @what, self.class::INPUT_TYPES, self.class)
      @o = locator_or_element.is_a?(WIN32OLE) ? locator_or_element : locator_or_element.locate
    end
    def initialize(container, how, what, value=nil)
      super container, how, what
      @value = value
    end

    def inspect
      '#<%s:0x%x located=%s how=%s what=%s value=%s>' % [self.class, hash*2, !!ole_object, @how.inspect, @what.inspect, @value.inspect]
    end
    
    # This method determines if a radio button or check box is set.
    # Returns true if set/checked; false if not set/checked.
    # Raises UnknownObjectException if its unable to locate an object.
    def set? 
      assert_exists
      return @o.checked
    end
    alias checked? set?
    
    def radio_value=(x)
      @value = x
    end

  end
  
  #--
  #  this class makes the docs better
  #++
  # This class is the watir representation of a radio button.
  # Normally a user would not need to create this object as it is returned by the Watir::Container#radio method
  class Radio < RadioCheckCommon
    INPUT_TYPES = ["radio"]
    # This method clears a radio button. One of them will almost always be set.
    # Returns true if set or false if not set.
    #   Raises UnknownObjectException if its unable to locate an object
    #         ObjectDisabledException IF THE OBJECT IS DISABLED
    def clear
      assert_exists
      assert_enabled
      highlight(:set)
      @o.checked = false
      highlight(:clear)
      highlight(:clear)
    end
    
    # This method sets the radio list item.
    #   Raises UnknownObjectException  if it's unable to locate an object
    #         ObjectDisabledException  if the object is disabled
    def set
      assert_exists
      assert_enabled
      highlight(:set)
      @o.scrollIntoView
      @o.checked = true
      click
      highlight(:clear)
    end

    # Sets (click) the button corresponding to the specified value.
    def value=(x)
      copy = self.dup
      copy.radio_value = x
      copy.set
    end

    # Is there a button matching the current specifiers for the provided value?
    def valueIsSet?(x)
      copy = self.dup
      copy.radio_value = x
      copy.exists? && copy.isSet?
    end

    # Returns the value that the current button-group is set for.
    def selected_value
      copy = checked_button
      copy.value
    end

    # Returns the button matching the current specifiers that is actually checked
    def checked_button
      copy = self.dup
      if copy.how.is_a? Symbol
        copy.how = {copy.how => copy.what}
        copy.what = nil
      end
      copy.how.merge!(:checked => true)
      copy
    end
    private :checked_button

    def text
      assert_exists
      begin
        if in_table?
          text = sibling_text(parent_cell)
        else
          text = sibling_text(ole_object)
        end
      rescue
        ''
      end
      text.strip
    end

    def sibling_text(x)
      assert_exists
      text = ''
      element = x
      while element
        text << element.innerText rescue ''
        break if text.strip != ''
        element = element.nextSibling
      end
      text
    end

    def in_table?
      assert_exists
      element = ole_object
      while element && element = element.parentElement
        return true if element.nodeName == 'TABLE'
      end
      false
    end

    def parent_cell
      assert_exists
      element = ole_object
      while element && element = element.parentElement
        return element if element.nodeName == 'TD' || element.nodeName == 'TH'
      end
    end
    
  end

  # This class is the watir representation of a check box.
  # Normally a user would not need to create this object as it is returned by the Watir::Container#checkbox method
  class CheckBox < RadioCheckCommon
    INPUT_TYPES = ["checkbox"]
    # This method checks or unchecks the checkbox.
    # With no arguments supplied it sets the checkbox.
    # Setting false argument unchecks/clears the checkbox.
    #   Raises UnknownObjectException if it's unable to locate an object
    #         ObjectDisabledException if the object is disabled
    def set(value=true)
      assert_exists
      assert_enabled
      highlight :set
      current_value = @o.checked
      unless value == current_value
        click
      end
      highlight :clear
    end
    
    # Clears a check box.
    #   Raises UnknownObjectException if its unable to locate an object
    #         ObjectDisabledException if the object is disabled
    def clear
      set false
    end

    def value=(x)
      x ? set : clear
    end

    Watir::Container.module_eval do
      remove_method :check_boxs

      def checkboxes(how={}, what=nil)
        CheckBoxes.new(self, how, what)
      end

      remove_method :check_box

      def checkbox(how={}, what=nil)
        CheckBox.new(self, how, what)
      end
    end
  end

end
