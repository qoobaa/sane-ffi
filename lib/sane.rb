class Sane
  include Singleton

  attr_reader :version

  def self.open
    instance.send(:init)
    yield instance
  ensure
    instance.send(:exit)
  end

  def devices
    get_devices.map { |device| Device.new(device) }
  end

  private

  def not_initialized?
    version.nil?
  end

  def initialized?
    !not_initialized?
  end

  def init
    ensure_not_initialized!
    version_code = FFI::MemoryPointer.new(:int)
    check_status!(API.sane_init(version_code, FFI::Pointer::NULL))
    @version = version_code.read_int
  end

  def exit
    ensure_initialized!
    API.sane_exit
    @version = nil
  end

  def get_devices
    ensure_initialized!
    devices_pointer_pointer = FFI::MemoryPointer.new(:pointer)
    check_status!(API.sane_get_devices(devices_pointer_pointer, 0))
    devices_pointer = devices_pointer_pointer.read_pointer
    [].tap do |result|
      until devices_pointer.read_pointer.null?
        result << API::Device.new(devices_pointer.read_pointer).to_hash
        devices_pointer += FFI.type_size(:pointer)
      end
    end
  end

  def open(device_name)
    ensure_initialized!
    device_handle_pointer = FFI::MemoryPointer.new(:pointer)
    check_status!(API.sane_open(device_name, device_handle_pointer))
    device_handle_pointer.read_pointer
  end

  def close(device_handle)
    ensure_initialized!
    API.sane_close(device_handle)
  end

  def get_option_descriptor(device_handle, option)
    ensure_initialized!
    result = API.sane_get_option_descriptor(device_handle, option)
    API::OptionDescriptor.new(result).to_hash
  end

  def get_option(device_handle, option)
    ensure_initialized!
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
    ensure_initialized!
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

  def start(handle)
    ensure_initialized!
    API.sane_start(handle)
  end

  def read(handle, size = 64 * 1024)
    ensure_initialized!
    data_pointer = FFI::MemoryPointer.new(:char, size)
    length_pointer = FFI::MemoryPointer.new(:int)
    check_status!(API.sane_read(handle, data_pointer, size, length_pointer))
    data_pointer.read_string(length_pointer.read_int)
  end

  def strstatus(status)
    ensure_initialized!
    API.sane_strstatus(status)
  end

  def get_parameters(handle)
    ensure_initialized!
    parameters_pointer = FFI::MemoryPointer.new(API::Parameters.size)
    check_status!(API.sane_get_parameters(handle, parameters_pointer))
    API::Parameters.new(parameters_pointer).to_hash
  end

  def ensure_not_initialized!
    raise "SANE library is already initialized" if initialized?
  end

  def ensure_initialized!
    raise "SANE library is not initialized" if not_initialized?
  end

  def check_status!(status)
    raise Error.new(strstatus(status), status) unless status == :good
  end
end
