defmodule Gpio.Mock do
  use GenServer

  @behaviour Gpio

  defmodule State do
    @moduledoc false
    defstruct pin: nil,
              direction: nil,
              callbacks: [],
              value: 0
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
    state = %State{pin: pin, direction: pin_direction}
    {:ok, state}
  end

  def handle_call(:read, _from, %State{direction: :input, value: value} = state) do
    {:reply, {:ok, value}, state}
  end
  def handle_call({:write, value}, _from, %State{direction: :output} = state) do
    trigger_interrupt(value, state)
    state = %State{state | value: value}
    {:reply, :ok, state}
  end
  def handle_call({:set_int, direction, requestor}, _from, %State{direction: :input} = state) do
    true = Gpio.pin_interrupt_condition?(direction)
    new_callbacks = Gpio.insert_unique(state.callbacks, requestor)
    state = %State{state | callbacks: new_callbacks}
    {:reply, :ok, state}
  end

  def handle_cast(:release, state) do
    {:stop, :normal, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp trigger_interrupt(value, %State{value: value}) do
    :ok
  end
  defp trigger_interrupt(new_value, state) do
    condition = case new_value do
      0 -> :falling
      1 -> :rising
    end
    msg = {:gpio_interrupt, state.pin, condition}
    Enum.each(state.callbacks, &(send(&1, msg)))
  end

end
