module Watir

  module FileDownloadMethods
    def set(x)
      click_no_wait
      # workaround till I can figure out how to save the file to a path
      if IE.version_parts.first.to_i == 9
        Watir::Wait.until{ @container.rautomation.child(:class=> /Notification/).exists?}
        # Super hacky but this window is very non-standard and I'm unable to get
        # to the buttons. So instead, send TAB, TAB, DOWN ARROW, A (Save As)
        @container.rautomation.send_raw_keys 0x09, 0x09, 0x28, 0x41
      else
        save_file_button.click
      end
      set_file_name x
      save_button.click
    end
    alias :value= :set

    def open
      click_no_wait
      open_file_button.click
    end

    # File Download Dialog
    def file_download_window
      @file_download_window ||= wait_for_window('File Download', /save this file/)
      @file_download_window
    end

    def save_file_button
      file_download_window.button(:value => '&Save')
    end

    def open_file_button
      file_download_window.button(:value => 'Open')
    end

    # Save As Dialog
    def save_as_window
      @save_window ||= wait_for_window('Save As')
      @save_window
    end

    def set_file_name(path_to_file)
      save_as_window.text_field(:class => 'Edit').set path_to_file
    end

    def save_button
      save_as_window.button(:value=>'&Save')
    end

    def wait_for_window(title, text=nil)
      args = {:title => title}
      args.update(:text => text) if text
      window = nil
      Watir::Wait.until {
        window = ::RAutomation::Window.new(args)
        window.exists?
      }
      window
    end

  end

  class FileDownloadLink < Watir::Link
    include FileDownloadMethods
  end

  class FileDownloadButton < Watir::Button
    include FileDownloadMethods
  end

end
