module Sane
  class Device
    def initialize(handle)
      @handle = handle
    end

    def close
      Sane.close(@handle)
    end
  end
end
