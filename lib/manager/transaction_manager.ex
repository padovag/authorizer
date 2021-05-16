defmodule TransactionManager do
  use GenServer

  # client

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  def register(transaction = %Transaction{}) do
    GenServer.call(__MODULE__, {:register, transaction})
  end

  def get_from_interval(start_from = %DateTime{}, interval_in_seconds) do
    GenServer.call(__MODULE__, {:get_from_interval, start_from, interval_in_seconds})
  end

  # server

  def handle_call({:register, transaction = %Transaction{time: time}}, _from, state) do
    new_state = Map.put(state, time, transaction)
    {:reply, new_state, new_state}
  end

  def handle_call({:get_from_interval, start_from, interval_in_seconds}, _from, state) do
    transactions_from_interval = state
    |> Enum.reverse()
    |> Enum.map(fn {time, transactions} -> {convert_to_time(time), transactions} end)
    |> Enum.filter(fn {datetime, _transactions} -> DateTime.diff(start_from, datetime) <= interval_in_seconds end)

    {:reply, transactions_from_interval, state}
  end

  defp convert_to_time(time) do
    {:ok, datetime, _} = DateTime.from_iso8601(time)
    datetime
  end

end
