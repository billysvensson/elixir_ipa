defmodule I2c.Prod do
  use GenServer

  @behaviour I2c

  defmodule State do
    @moduledoc false
    defstruct port: nil,
              devname: nil,
              address: 0
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
    executable = :code.priv_dir(:elixir_ipa) ++ '/ipa'
    port = Port.open({:spawn_executable, executable},
      [{:args, ["i2c", "/dev/#{devname}"]},
       {:packet, 2},
       :use_stdio,
       :binary,
       :exit_status])
    state = %State{port: port, address: address, devname: devname}
    {:ok, state}
  end

  def handle_call({:read, count}, _from, state) do
    response = call_port(state, :read, state.address, count)
    {:reply, response, state}
  end
  def handle_call({:write, data}, _from, state) do
    {:ok, response} = call_port(state, :write, state.address, data)
    {:reply, response, state}
  end
  def handle_call({:wrrd, write_data, read_count}, _from, state) do
    response = call_port(state, :wrrd, state.address, {write_data, read_count})
    {:reply, response, state}
  end

  def handle_cast(:release, state) do
    {:stop, :normal, state}
  end

  # Private helper functions
  defp call_port(state, command, address, arguments) do
    msg = {command, address, arguments}
    send state.port, {self(), {:command, :erlang.term_to_binary(msg)}}
    receive do
      {_, {:data, response}} ->
        {:ok, :erlang.binary_to_term(response)}
        _ -> :error
    end
  end

end
