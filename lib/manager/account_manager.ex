defmodule AccountManager do
  use GenServer

  # client

  def start_link() do
    GenServer.start_link(__MODULE__, %{account: nil, violations: []}, name: __MODULE__)
    TransactionManager.start_link()
  end

  def init(args) do
    {:ok, args}
  end

  def create(active_card, available_limit) do
    GenServer.call(__MODULE__, {:create_account, {active_card, available_limit}})
  end

  def transaction(merchant, amount, time) do
    GenServer.call(__MODULE__, {:transaction, %Transaction{merchant: merchant, amount: amount, time: time}})
  end

  # server

  def handle_call({:create_account, parameters}, _from, state) do
    new_state = case validate_create_account(state) do
      {:error, error_message} -> %{state | violations: [error_message]}
      {:ok, :none} -> create_account(parameters)
    end

    {:reply, new_state, new_state}
  end

  def handle_call({:transaction, transaction = %Transaction{}}, _from, state) do
    new_state = case validate_transaction(transaction, state) do
      {:error, error_message} -> %{state | violations: [error_message]}
      {:ok, :none} -> process_transaction(transaction, state)
    end

    {:reply, new_state, new_state}
  end

  defp validate_create_account(_state = %{account: nil}), do: {:ok, :none}
  defp validate_create_account(_state = %{account: %Account{}}), do: {:error, "account-already-initialized"}

  defp validate_transaction(transaction, state) do
    transaction |> composite_validator([
      {&validate_account_state/1, {transaction, state}},
      {&validate_double_transaction/1, {transaction, get_last_similar_transaction(transaction)}},
      {&validate_high_frequency/1, get_last_transactions(transaction.time)}
    ])
  end

  defp composite_validator(_transaction, validators) do
    validators
    |> Enum.map(fn {validator, arguments} -> validator.(arguments) end)
    |> Enum.filter(fn validator_result -> validator_result != :ok end)
    |> build_validation_result_tuple()
  end

  defp validate_account_state({_transaction, _state = %{account: nil}}), do: "account-not-initialized"
  defp validate_account_state({_transaction, _state = %{account: %Account{active_card: false}}}), do: "card-not-active"
  defp validate_account_state({_transaction = %Transaction{amount: amount}, _state = %{account: %Account{available_limit: limit}}})
       when amount > limit, do: "insufficient-limit"
  defp validate_account_state({_transaction, _state}), do: :ok

  defp validate_double_transaction({_transaction, last_transaction}) when length(last_transaction) > 0, do: "double-transaction"
  defp validate_double_transaction({_transaction, _last_transaction}), do: :ok

  defp validate_high_frequency(last_transactions) when length(last_transactions) < 3, do: :ok
  defp validate_high_frequency(_last_transactions), do: "high-frequency-small-interval"

  defp build_validation_result_tuple([]), do: {:ok, :none}
  defp build_validation_result_tuple([error_message]), do: {:error, error_message}

  defp create_account({active_card, available_limit}) do
    %{account: %Account{active_card: active_card, available_limit: available_limit}, violations: []}
  end

  defp process_transaction(transaction = %Transaction{amount: amount}, state = %{account: %Account{available_limit: limit}}) do
    TransactionManager.register(transaction)

    available_amount = limit - amount
    state
    |> Map.update(:account, %{}, fn account -> %{account | available_limit: available_amount} end)
    |> Map.replace(:violations, [])
  end

  defp get_last_transactions(start_from) do
    {:ok, start_from_datetime, _} = DateTime.from_iso8601(start_from)
    TransactionManager.get_from_interval(start_from_datetime, _interval_in_seconds = 120)
  end

  defp get_last_similar_transaction(_transaction = %Transaction{time: start_from, merchant: merchant_to_find, amount: amount_to_find}) do
    {:ok, start_from_datetime, _} = DateTime.from_iso8601(start_from)
    TransactionManager.get_from_interval(start_from_datetime, _interval_in_seconds = 120)
    |> Enum.filter(fn {_time, %Transaction{merchant: merchant, amount: amount}} -> merchant == merchant_to_find and amount == amount_to_find end)
  end
end
