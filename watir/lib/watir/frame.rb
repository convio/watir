module Watir
  class Frame < Element
    include PageContainer
    TAG = ['FRAME', 'IFRAME']

    attr_accessor :document, :ole_document

    # Find the frame denoted by how and what in the container and return its ole_object
    def locate
      @o, @document = @container.locator_for(FrameLocator, @how, @what).locate
    end

    def __ole_inner_elements
      begin
        Watir::Wait.until {document.body}
        document.body.all
      rescue WIN32OLERuntimeError
        raise FrameAccessDeniedException, "IE will not allow access to this frame for security reasons. You can work around this with ie.goto(frame.src)"
      end
    end

    def initialize(container, how, what)
      set_container container
      @how = how
      @what = what
      copy_test_config container
    end
    
    def document
      assert_exists
      if @document
        @document
      else
        raise FrameAccessDeniedException, "IE will not allow access to this frame for security reasons. You can work around this with ie.goto(frame.src)"
      end
    end

    def document_mode
      document.documentMode
    end

    def attach_command
      @container.page_container.attach_command + ".frame(#{@how.inspect}, #{@what.inspect})".gsub('"','\'')
    end


  end
end
