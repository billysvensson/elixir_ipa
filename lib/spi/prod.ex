defmodule Spi.Prod do
  use GenServer

  @behaviour Spi

  defmodule State do
    @moduledoc false
    defstruct port: nil,
              devname: nil
  end

  # Public API
  def start_link(devname, spi_opts \\ [], opts \\ []) do
    opts = Keyword.put(opts, :name, Spi.server_ref(devname))
    GenServer.start_link(__MODULE__, {devname, spi_opts}, opts)
  end

  def release(devname) do
    GenServer.cast(Spi.server_ref(devname), :release)
  end

  def transfer(devname, data) do
    GenServer.call(Spi.server_ref(devname), {:transfer, data})
  end

  # GenServer callbacks
  def init({devname, spi_opts}) do
    mode = Keyword.get(spi_opts, :mode, 0)
    bits_per_word = Keyword.get(spi_opts, :bits_per_word, 8)
    speed_hz = Keyword.get(spi_opts, :speed_hz, 1_000_000)
    delay_us = Keyword.get(spi_opts, :delay_us, 10)

    executable = :code.priv_dir(:elixir_ipa) ++ '/ipa'
    port = Port.open({:spawn_executable, executable},
      [{:args, ["spi",
                "/dev/#{devname}",
                Integer.to_string(mode),
                Integer.to_string(bits_per_word),
                Integer.to_string(speed_hz),
                Integer.to_string(delay_us)]},
       {:packet, 2},
       :use_stdio,
       :binary,
       :exit_status])
    state = %State{port: port, devname: devname}
    {:ok, state}
  end

  def handle_call({:transfer, data}, _from, state) do
    response = call_port(state, :transfer, data)
    {:reply, response, state}
  end

  def handle_cast(:release, state) do
    {:stop, :normal, state}
  end

  # Private helper functions
  defp call_port(state, command, arguments) do
    msg = {command, arguments}
    send state.port, {self(), {:command, :erlang.term_to_binary(msg)}}
    receive do
      {_, {:data, response}} ->
        {:ok, :erlang.binary_to_term(response)}
        _ -> :error
    end
  end
end
