defmodule Spi.Mock do
  use GenServer

  @behaviour Spi

  defmodule State do
    @moduledoc false
    defstruct devname: nil,
              value: nil
  end

  # Public API
  def start_link(devname, _spi_opts \\ [], opts \\ []) do
    opts = Keyword.put(opts, :name, Spi.server_ref(devname))
    GenServer.start_link(__MODULE__, devname, opts)
  end

  def release(devname) do
    GenServer.cast(Spi.server_ref(devname), :release)
  end

  def transfer(devname, data) do
    GenServer.call(Spi.server_ref(devname), {:transfer, data})
  end

  # GenServer callbacks
  def init(devname) do
    state = %State{devname: devname, value: ''}
    {:ok, state}
  end

  def handle_call({:transfer, data}, _from, %State{value: value} = state) do
    state = %State{state | value: data}
    {:reply, {:ok, value}, state}
  end

  def handle_cast(:release, state) do
    {:stop, :normal, state}
  end

end
