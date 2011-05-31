module Sane
  class << self
    def init
      version_code = FFI::MemoryPointer.new(:int)
      check_status!(API.sane_init(version_code, FFI::Pointer::NULL))
      version_code.read_int
    end

    def exit
      API.sane_exit
    end

    def get_devices
      devices_pointer = FFI::MemoryPointer.new(:pointer)
      check_status!(API.sane_get_devices(devices_pointer, 0))
      devices = devices_pointer.read_pointer
      [].tap do |result|
        until devices.read_pointer.null?
          result << API::Device.new(devices.read_pointer)
          devices += FFI.type_size(:pointer)
        end
      end
    end

    def open(device_name)
      device_handle_pointer = FFI::MemoryPointer.new(:pointer)
      check_status!(API.sane_open(device_name.to_s, device_handle_pointer))
      device_handle_pointer.read_pointer
    end

    def close(device_handle)
      API.sane_close(device_handle)
    end

    def get_option_descriptor(device_handle, option)
      result = API.sane_get_option_descriptor(device_handle, option)
      API::OptionDescriptor.new(result)
    end

    def get_option(device_handle, option)
      descriptor = get_option_descriptor(device_handle, option)

      case descriptor[:type]
      when :string
        value_pointer = FFI::MemoryPointer.new(:pointer)
      when :bool, :int, :fixed
        value_pointer = FFI::MemoryPointer.new(:int)
      else
        return nil
      end

      check_status!(API.sane_control_option(device_handle, option, :get_value, value_pointer, FFI::Pointer::NULL))

      case descriptor[:type]
      when :string
        value_pointer.read_string
      when :bool
        !value_pointer.read_int.zero?
      when :int, :fixed
        value_pointer.read_int
      end
    end

    def set_option(device_handle, option, value)
      descriptor = get_option_descriptor(device_handle, option)

      case descriptor[:type]
      when :string
        value_pointer = FFI::MemoryPointer.from_string(value)
      when :int, :fixed
        value_pointer = FFI::MemoryPointer.new(:int).write_int(value)
      when :bool
        value_pointer = FFI::MemoryPointer.new(:int).write_int(value ? 1 : 0)
      else
        return nil
      end

      check_status!(API.sane_control_option(device_handle, option, :set_value, value_pointer, FFI::Pointer::NULL))

      case descriptor[:type]
      when :string
        value_pointer.read_string
      when :bool
        !value_pointer.read_int.zero?
      when :int, :fixed
        value_pointer.read_int
      end
    end

    def check_status!(status)
      raise Error.new(API.sane_strstatus(status), status) if status != :good
    end
  end
end
