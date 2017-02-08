defmodule Circuit.Ads1115 do
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct devname: nil,
              address: nil,
              inputs: nil
  end

  defmodule Config do
    @moduledoc false
    defstruct mode: :default,
              max_volts: :default,
              data_rate: :default
  end

  # Public API
  def start_link(devname, address_pin, opts \\ []) do
    opts = Keyword.put(opts, :name, server_ref(devname, address_pin))
    GenServer.start_link(__MODULE__, {devname, address_pin}, opts)
  end

  def config(devname, address_pin, input, mode, max_volts, data_rate) do
    GenServer.call(server_ref(devname, address_pin),
                   {:config, input, mode, max_volts, data_rate})
  end

  def value(devname, address_pin, input) do
    GenServer.call(server_ref(devname, address_pin), {:value, input})
  end

  # GenServer callbacks
  def init({devname, address_pin}) do
    address = to_hex(:address, address_pin)
    {:ok, _} = I2c.Prod.start_link(devname, address)
    state = %State{devname: devname,
                   address: address,
                   inputs: %{anc0: %Config{},
                             anc1: %Config{},
                             anc2: %Config{},
                             anc3: %Config{}}}
    {:ok, state}
  end

  def handle_call({:config, input, mode, max_volts, data_rate}, _from,
                  %State{inputs: inputs} = state) do
    max_value = round(Float.ceil(max_value(max_volts)))
    config = %Config{mode: mode, max_volts: max_volts, data_rate: data_rate}
    inputs = Map.put(inputs, input, config)
    state = %State{state | inputs: inputs}
    {:reply, {:ok, max_value}, state}
  end

  def handle_call({:value, input}, _from,
                  %State{devname: devname, address: address, inputs: inputs} = state) do
    %Config{mode: mode, max_volts: max_volts, data_rate: data_rate} = Map.get(inputs, input)
    value = read_value(devname, address, input, mode, max_volts, data_rate)
    {:reply, {:ok, value}, state}
  end

  # Private helper functions
  defp server_ref(devname, address_pin) do
    {:via, :gproc, {:n, :l, {__MODULE__, devname, address_pin}}}
  end

  defp read_value(devname, address, input, mode, max_volts, data_rate) do
    pointer_register = <<1>>
    config_register = <<to_binary(:os, mode) :: bitstring,
                        to_binary(:mux, input) :: bitstring,
                        to_binary(:pga, max_volts) :: bitstring,
                        to_binary(:mode, mode) :: bitstring,
                        to_binary(:dr, data_rate) :: bitstring,
                        to_binary(:comp, :default) :: bitstring>>
    write_config = <<pointer_register :: bitstring, config_register :: bitstring>>
    :ok = I2c.Prod.write(devname, address, write_config)
    :ok = read_status(devname, address)
    {:ok, <<value::16>>} = I2c.Prod.write_read(devname, address, <<0>>, 2)
    value
  end

  defp read_status(devname, address) do
    {:ok, data} = I2c.Prod.read(devname, address, 2)
    case data do
      <<1::1, _::bitstring>> -> :ok
      <<0::1, _::bitstring>> ->
        Process.sleep(10)
        read_status(devname, address)
    end
  end

  defp to_hex(:address, :gnd) do
    0x48
  end
  defp to_hex(:address, :vdd) do
    0x49
  end
  defp to_hex(:address, :sda) do
    0x4A
  end
  defp to_hex(:address, :scl) do
    0x4B
  end

  defp to_binary(:os, :default) do
    <<1::1>>
  end
  defp to_binary(:os, :continious) do
    <<0::1>>
  end
  defp to_binary(:os, :single_shot) do
    <<1::1>>
  end

  defp to_binary(:mux, :default) do
    <<100::3>>
  end
  defp to_binary(:mux, :anc0) do
    <<100::3>>
  end
  defp to_binary(:mux, :anc1) do
    <<101::3>>
  end
  defp to_binary(:mux, :anc2) do
    <<110::3>>
  end
  defp to_binary(:mux, :anc3) do
    <<111::3>>
  end

  defp to_binary(:pga, :default) do
    <<010::3>>
  end
  defp to_binary(:pga, max_volts) when max_volts <= 0.256 do
    <<101::3>>
  end
  defp to_binary(:pga, max_volts) when max_volts <= 0.512 do
    <<100::3>>
  end
  defp to_binary(:pga, max_volts) when max_volts <= 1.024 do
    <<011::3>>
  end
  defp to_binary(:pga, max_volts) when max_volts <= 2.048 do
    <<010::3>>
  end
  defp to_binary(:pga, max_volts) when max_volts <= 4.096 do
    <<001::3>>
  end
  defp to_binary(:pga, max_volts) when max_volts <= 6.144 do
    <<000::3>>
  end

  defp to_binary(:mode, :default) do
    <<1::1>>
  end
  defp to_binary(:mode, :continious) do
    <<0::1>>
  end
  defp to_binary(:mode, :single_shot) do
    <<1::1>>
  end

  defp to_binary(:dr, :default) do
    <<100::3>>
  end
  defp to_binary(:dr, data_rate) when data_rate <= 8 do
    <<000::3>>
  end
  defp to_binary(:dr, data_rate) when data_rate <= 16 do
    <<001::3>>
  end
  defp to_binary(:dr, data_rate) when data_rate <= 32 do
    <<010::3>>
  end
  defp to_binary(:dr, data_rate) when data_rate <= 64 do
    <<011::3>>
  end
  defp to_binary(:dr, data_rate) when data_rate <= 128 do
    <<100::3>>
  end
  defp to_binary(:dr, data_rate) when data_rate <= 250 do
    <<101::3>>
  end
  defp to_binary(:dr, data_rate) when data_rate <= 475 do
    <<110::3>>
  end
  defp to_binary(:dr, data_rate) when data_rate <= 860 do
    <<111::3>>
  end

  defp to_binary(:comp, :default) do
    <<00101::5>>
  end

  defp max_value(:default) do
    32767
  end
  defp max_value(max_volts) when max_volts <= 0.256 do
    (32767 / 0.256) * max_volts
  end
  defp max_value(max_volts) when max_volts <= 0.512 do
    (32767 / 0.512) * max_volts
  end
  defp max_value(max_volts) when max_volts <= 1.024 do
    (32767 / 1.024) * max_volts
  end
  defp max_value(max_volts) when max_volts <= 2.048 do
    (32767 / 2.048) * max_volts
  end
  defp max_value(max_volts) when max_volts <= 4.096 do
    (32767 / 4.096) * max_volts
  end
  defp max_value(max_volts) when max_volts <= 6.144 do
    (32767 / 6.144) * max_volts
  end

end
