class Sane
  class Device
    def initialize(name)
      @name = name
      @handle = nil
    end

    def open
      @handle = Sane.open(@name) if closed?
      if block_given?
        yield self
        close
      end
    end

    def closed?
      @handle.nil?
    end

    def opened?
      !closed?
    end

    def close
      Sane.close(@handle) if opened?
      @handle = nil
    end
  end
end
