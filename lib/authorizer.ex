defmodule Authorizer do

  def authorize(operations) do
    AccountManager.start_link()

    operations
    |> Enum.map(&process/1)
  end

  defp process(%{"account" => %{"active-card" => active_card, "available-limit" => limit}}) do
    AccountManager.create(active_card, limit)
  end

  defp process(%{"transaction" => %{"amount" => amount, "merchant" => merchant, "time" => time}}) do
    AccountManager.transaction(merchant, amount, time)
  end
end
