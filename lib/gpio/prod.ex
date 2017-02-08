defmodule Gpio.Prod do
  use GenServer

  @behaviour Gpio

  defmodule State do
    @moduledoc false
    defstruct port: nil,
              pin: nil,
              direction: nil,
              callbacks: [],
              condition: nil
  end

  # Public API
  def start_link(pin, pin_direction, opts \\ []) do
    opts = Keyword.put(opts, :name, Gpio.server_ref(pin))
    GenServer.start_link(__MODULE__, [pin, pin_direction], opts)
  end

  def release(pin) do
    GenServer.cast(Gpio.server_ref(pin), :release)
  end

  def write(pin, value) when is_integer(value) do
    GenServer.call(Gpio.server_ref(pin), {:write, value})
  end

  def read(pin) do
    GenServer.call(Gpio.server_ref(pin), :read)
  end

  def set_int(pin, direction) do
    GenServer.call(Gpio.server_ref(pin), {:set_int, direction, self()})
  end

  # GenServer callbacks
  def init([pin, pin_direction]) do
    executable = :code.priv_dir(:elixir_ipa) ++ '/ipa'
    port = Port.open({:spawn_executable, executable},
    [{:args, ["gpio", "#{pin}", Atom.to_string(pin_direction)]},
      {:packet, 2},
      :use_stdio,
      :binary,
      :exit_status])
    state = %State{port: port, pin: pin, direction: pin_direction}
    {:ok, state}
  end

  def handle_call(:read, _from, %State{direction: :input} = state) do
    response = call_port(state, :read, [])
    {:reply, response, state}
  end
  def handle_call({:write, value}, _from, %State{direction: :output} = state) do
    {:ok, response} = call_port(state, :write, value)
    {:reply, response, state}
  end
  def handle_call({:set_int, direction, requestor}, _from, %State{direction: :input} = state) do
    true = Gpio.pin_interrupt_condition?(direction)
    {:ok, response} = call_port(state, :set_int, direction)
    new_callbacks = Gpio.insert_unique(state.callbacks, requestor)
    state = %State{state | callbacks: new_callbacks}
    {:reply, response, state}
  end

  def handle_cast(:release, state) do
    {:stop, :normal, state}
  end

  def handle_info({_, {:data, <<?n, message::binary>>}}, state) do
    msg = :erlang.binary_to_term(message)
    handle_port(msg, state)
  end

  defp call_port(state, command, arguments) do
    msg = {command, arguments}
    send state.port, {self(), {:command, :erlang.term_to_binary(msg)}}
    receive do
      {_, {:data, <<?r,response::binary>>}} ->
        {:ok, :erlang.binary_to_term(response)}
    after
      1_000 -> :timeout
    end
  end

  defp handle_port({:gpio_interrupt, condition}, %State{condition: condition} = state) do
    {:noreply, state}
  end
  defp handle_port({:gpio_interrupt, condition}, state) do
    msg = {:gpio_interrupt, state.pin, condition}
    Enum.each(state.callbacks, &(send(&1, msg)))
    state = %State{state | condition: condition}
    {:noreply, state}
  end

end
