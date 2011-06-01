class Sane
  class Device
    def initialize(options)
      @name = options[:name]
      @vendor = options[:vendor]
      @model = options[:model]
      @type = options[:type]
      @handle = nil
    end

    def closed?
      @handle.nil?
    end

    def open?
      !closed?
    end

    def open
      ensure_closed!
      @handle = Sane.instance.send(:open, @name)
      if block_given?
        begin
          yield(self)
        ensure
          close
        end
      end
    end

    def close
      ensure_open!
      Sane.instance.send(:close, @handle)
      @handle = nil
    end

    def start
      ensure_open!
      Sane.instance.start(@handle)
    end

    def read
      ensure_open!
      Sane.instance.send(:read, @handle)
    end

    def option_count
      ensure_open!
      Sane.instance.send(:get_option, @handle, 0)
    end

    def parameters
      ensure_open!
      Sane.instance.send(:get_parameters, @handle)
    end

    def [](option)
      ensure_open!
      Sane.instance.send(:get_option, @handle, option_lookup(option))
    end

    def []=(option, value)
      ensure_open!
      Sane.instance.send(:set_option, @handle, option_lookup(option), value)
    end

    def option_descriptors
      option_count.times.map { |i| Sane.instance.send(:get_option_descriptor, @handle, i) }
    end

    def option_names
      option_descriptors.map { |option| option[:name] }
    end

    def option_values
      option_count.times.map do |i|
        begin
          self[i]
        rescue Error
          nil # we can't read values of some options (i.e. buttons), ignore them
        end
      end
    end

    def options
      result = {}
      option_count.times { |i| hash[option_names[i]] = option_values[i] }
      result
    end

    def option_lookup(option_name)
      return option_name if (0..option_count).include?(option_name)
      option_descriptors.index { |option| option[:name] == option_name.to_s } or raise(ArgumentError, "Option not found: #{option_name}")
    end

    def describe(option)
      option_descriptors[option_lookup(option)]
    end

    private

    def ensure_closed!
      raise("Device is already open") if open?
    end

    def ensure_open!
      raise("Device is closed") if closed?
    end
  end
end
