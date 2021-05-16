defmodule AuthorizerTest do
  use ExUnit.Case
  doctest Authorizer

  test "process transactions after creating account should process successfully and apply validations" do
    operations = [
      %{"transaction" => %{"amount" => 10, "merchant" => "Mc Donalds", "time" => "2019-02-13T08:00:00.000Z"}},
      %{"account" => %{"active-card" => true, "available-limit" => 100}},
      %{"account" => %{"active-card" => true, "available-limit" => 100}},
      %{"transaction" => %{"amount" => 10, "merchant" => "Mc Donalds", "time" => "2019-02-13T09:00:00.000Z"}},
      %{"transaction" => %{"amount" => 10, "merchant" => "Mc Donalds", "time" => "2019-02-13T09:00:01.000Z"}},
      %{"transaction" => %{"amount" => 50, "merchant" => "Burger King", "time" => "2019-02-13T10:00:00.000Z"}},
      %{"transaction" => %{"amount" => 90, "merchant" => "Habib's", "time" => "2019-02-13T11:00:00.000Z"}},
      %{"transaction" => %{"amount" => 20, "merchant" => "Bobs", "time" => "2019-02-13T12:00:00.000Z"}},
      %{"transaction" => %{"amount" => 5, "merchant" => "Bobs", "time" => "2019-02-13T13:00:01.000Z"}},
      %{"transaction" => %{"amount" => 5, "merchant" => "Habib's", "time" => "2019-02-13T12:00:02.000Z"}},
      %{"transaction" => %{"amount" => 5, "merchant" => "Mc Donalds", "time" => "2019-02-13T12:00:03.000Z"}}
    ]

    expected_result = [
      %{account: nil, violations: ["account-not-initialized"]},
      %{account: %Account{available_limit: 100, active_card: true}, violations: []},
      %{account: %Account{available_limit: 100, active_card: true}, violations: ["account-already-initialized"]},
      %{account: %Account{available_limit: 90, active_card: true}, violations: []},
      %{account: %Account{available_limit: 90, active_card: true}, violations: ["double-transaction"]},
      %{account: %Account{available_limit: 40, active_card: true}, violations: []},
      %{account: %Account{available_limit: 40, active_card: true}, violations: ["insufficient-limit"]},
      %{account: %Account{available_limit: 20, active_card: true}, violations: []},
      %{account: %Account{available_limit: 15, active_card: true}, violations: []},
      %{account: %Account{available_limit: 10, active_card: true}, violations: []},
      %{account: %Account{available_limit: 10, active_card: true}, violations: ["high-frequency-small-interval"]}
    ]

    assert Authorizer.authorize(operations) == expected_result
  end

  test "process transactions for inactive card" do
    operations = [
      %{"account" => %{"active-card" => false, "available-limit" => 100}},
      %{"transaction" => %{"amount" => 10, "merchant" => "Mc Donalds", "time" => "2019-02-13T09:00:00.000Z"}},
      %{"transaction" => %{"amount" => 50, "merchant" => "Burger King", "time" => "2019-02-13T10:00:00.000Z"}},
    ]

    expected_result = [
      %{account: %Account{available_limit: 100, active_card: false}, violations: []},
      %{account: %Account{available_limit: 100, active_card: false}, violations: ["card-not-active"]},
      %{account: %Account{available_limit: 100, active_card: false}, violations: ["card-not-active"]},
    ]

    assert Authorizer.authorize(operations) == expected_result
  end

end
