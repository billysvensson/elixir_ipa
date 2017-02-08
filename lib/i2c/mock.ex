defmodule I2c.Mock do
  use GenServer

  @behaviour I2c

  defmodule State do
    @moduledoc false
    defstruct devname: nil,
              address: 0,
              value: ""
  end

  # Public API
  def start_link(devname, address, opts \\ []) do
    opts = Keyword.put(opts, :name, I2c.server_ref(devname, address))
    GenServer.start_link(__MODULE__, {devname, address}, opts)
  end

  def release(devname, address) do
    GenServer.cast(I2c.server_ref(devname, address), :release)
  end

  def read(devname, address, count) do
    GenServer.call(I2c.server_ref(devname, address), {:read, count})
  end

  def write(devname, address, data) do
    GenServer.call(I2c.server_ref(devname, address), {:write, data})
  end

  def write_read(devname, address, write_data, read_count) do
    GenServer.call(I2c.server_ref(devname, address), {:wrrd, write_data, read_count})
  end

  # GenServer callbacks
  def init({devname, address}) do
    state = %State{address: address, devname: devname}
    {:ok, state}
  end

  def handle_call({:read, _count}, _from, %State{value: value} = state) do
    {:reply, {:ok, value}, state}
  end
  def handle_call({:write, data}, _from, state) do
    state = %State{state | value: data}
    {:reply, :ok, state}
  end
  def handle_call({:wrrd, write_data, _read_count}, _from, %State{value: value} =  state) do
    state = %State{state | value: write_data}
    {:reply, {:ok, value}, state}
  end

  def handle_cast(:release, state) do
    {:stop, :normal, state}
  end

end
