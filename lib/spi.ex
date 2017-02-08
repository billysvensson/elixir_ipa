defmodule Spi do
  use GenServer

  @moduledoc """
  This module enables Elixir programs to interact with hardware that's connected
  via a SPI bus.
  """

  @type spi_option ::
    {:mode, 0..3} |
    {:bits_per_word, 0..16} |  # 0 is interpreted as 8-bits
    {:speed_hz, pos_integer} |
    {:delay_us, non_neg_integer}

  # Public API
  @doc """
  Start and link a SPI GenServer.

  SPI bus options include:
   * `mode`: This specifies the clock polarity and phase to use. (0)
   * `bits_per_word`: bits per word on the bus (8)
   * `speed_hz`: bus speed (1000000)
   * `delay_us`: delay between transations (10)

  Parameters:
   * `devname` is the Linux device name for the bus (e.g., "spidev0.0")
   * `spi_opts` is a keyword list to configure the bus
   * `opts` are any options to pass to GenServer.start_link
  """
  @callback start_link(binary, [spi_option], [term]) :: {:ok, pid}

  @doc """
  Stop the GenServer and release the SPI resources.
  """
  @callback release(binary) :: :ok

  @doc """
  Perform a SPI transfer. The `data` should be a binary containing the bytes to
  send. Since SPI transfers simultaneously send and receive, the return value
  will be a binary of the same length.
  """
  @callback transfer(binary, binary) :: {:ok, binary} | {:error, term}

  @spec server_ref(binary) :: tuple
  def server_ref(devname) do
    {:via, :gproc, {:n, :l, {__MODULE__, devname}}}
  end

end
