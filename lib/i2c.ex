defmodule I2c do
  use GenServer

  @moduledoc """
  This module allows Elixir code to communicate with devices on an I2C bus.
  """

  @type i2c_address :: 0..127

  # Public API
  @doc """
  Start and link the I2c GenServer.

  `devname` is the I2C bus name (e.g., "i2c-1")
  `address` is the device's 7-bit address on the I2C bus

  Note that `address` can be confusing when reading a datasheet
  since sometimes the datasheet mentions the 8-bit address. For an 8-bit
  address the least significant bit indicates whether the access is for a
  read or a write. Microcontrollers like those on Arduinos often use the 8-bit
  address. To convert an 8-bit address to a 7-bit one, divide the address by
  two.

  All calls to `read/2`, `write/2`, and `write_read/3` access the device
  specified by `address`. Some I2C devices can be switched into different
  modes where they respond to an alternate address. Rather than having to
  create a second `I2c` process, see `read_device/3` and related routines.
  """
  @callback start_link(binary, i2c_address, [term]) :: {:ok, pid}

  @doc """
  Stop the GenServer and release all resources.
  """
  @callback release(binary, i2c_address) :: :ok

  @doc """
  Initiate a read transaction on the I2C bus of `count` bytes.
  """
  @callback read(binary, i2c_address, integer) :: {:ok, binary} | {:error, term}

  @doc """
  Write the specified `data` to the device.
  """
  @callback write(binary, i2c_address, binary) :: :ok | {:error, term}

  @doc """
  Write the specified `data` to the device and then read
  the specified number of bytes.
  """
  @callback write_read(binary, i2c_address, binary, integer) :: {:ok, binary} | {:error, term}

  @spec server_ref(binary, i2c_address) :: tuple
  def server_ref(devname, address) when is_integer(address) and address >= 0 and address <= 127 do
    {:via, :gproc, {:n, :l, {__MODULE__, devname, address}}}
  end

end
