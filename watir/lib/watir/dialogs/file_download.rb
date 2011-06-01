module Watir

  module FileDownloadMethods
    def initialize(*args)
      if IE.version_parts.first.to_i == 9
        raise NotImplementedError, "File downloads using #{self.class} are not yet supported in IE9"
      end
    end

    def set(filename)
      click_no_wait
      save_file_button.click
      set_file_name filename
      save_button.click
    end
    alias :value= :set

    def open
      click_no_wait
      open_file_button.click
    end

    # File Download Dialog
    def file_download_window
      @file_download_window ||= ::RAutomation::Window.new(:title => 'File Download', :text => /save this file/)
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
      @save_window ||=  ::RAutomation::Window.new(:title=>'Save As')
      @save_window
    end

    def set_file_name(path_to_file)
      save_as_window.text_field(:class => 'Edit').set path_to_file
    end

    def save_button
      save_as_window.button(:value=>'&Save')
    end

  end

  class FileDownloadLink < Watir::Link
    include FileDownloadMethods
  end

  class FileDownloadButton < Watir::Button
    include FileDownloadMethods
  end

end
