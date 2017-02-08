defmodule Gpio do

  @moduledoc """
  This is an Elixir interface to Linux GPIOs. Each GPIO is an
  independent GenServer.
  """

  @type pin_direction :: :input | :output
  @type int_direction :: :rising | :falling | :both
  @type pin :: 2..27
  @type pin_state :: 0 | 1

  @doc """
  Start and link a new GPIO GenServer. `pin` should be a valid
  GPIO pin number on the system and `pin_direction` should be
  `:input` or `:output`.
  """
  @callback start_link(pin, pin_direction, GenServer.options) :: {:ok, pid}

  @doc """
  Free the resources associated with pin and stop the GenServer.
  """
  @callback release(pin) :: :ok

  @doc """
  Write the specified value to the GPIO. The GPIO should be configured
  as an output. Valid values are `0` for logic low and `1` for logic high.
  Other non-zero values will result in logic high being output.
  """
  @callback write(pin, pin_state) :: :ok | {:error, term}

  @doc """
  Read the current value of the pin.
  """
  @callback read(pin) :: {:ok, pin_state} | {:error, term}

  @doc """
  Turn on "interrupts" on the input pin. The pin can be monitored for
  `:rising` transitions, `:falling` transitions, or `:both`. The process
  that calls this method will receive the messages.
  """
  @callback set_int(pin, int_direction) ::  :ok | {:error, term}

  def pin_interrupt_condition?(:rising), do: true
  def pin_interrupt_condition?(:falling), do: true
  def pin_interrupt_condition?(:both), do: true
  def pin_interrupt_condition?(:none), do: true

  @spec insert_unique(list, any) :: list
  def insert_unique(list, item) do
    if Enum.member?(list, item) do
      list
    else
      [item | list]
    end
  end

  @spec server_ref(pin) :: tuple
  def server_ref(pin) when is_integer(pin) and pin > 1 and pin < 28 do
    {:via, :gproc, {:n, :l, {__MODULE__, pin}}}
  end

end
