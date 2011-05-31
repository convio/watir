# Remove this once the new rautomation is released (> 0.5.1)
require 'rautomation'

module RAutomation
  module Adapter
    module WinFfi
      class Window
        def send_raw_keys(*keys)
          keys.each do |key|
            wait_until do
              activate
              active?
            end
            Functions.send_key(key, 0, 0, nil)
            Functions.send_key(key, 0, Constants::KEYEVENTF_KEYUP, nil)
          end
        end
      end
    end
  end
end
