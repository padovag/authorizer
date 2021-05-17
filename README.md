# Authorizer
An account authorizer simulator made with [**Elixir**](https://elixir-lang.org/getting-started/introduction.html). 
This project contains modules that process a bank account transactions according to the documentation below, and a mix task that process said operations from an input file.


## Installing and Running
* Install elixir to your system. Run `brew install elixir` if you're using MacOs, otherwise check [the installation guide](https://elixir-lang.org/install.html).
* Install the dependencies with `mix deps.get`
* Run the code through the mix task `mix authorizer [FILE_PATH]`

## Input
Run the mix task passing as a parameter a txt file containing a list of json structured operations as shown below.
The operations should be ordered by datetime, so they should be executed as ordered in the file.
```
{"account": {"active-card": true, "available-limit": 100}}
{"transaction": {"merchant": "Ebanx", "amount": 5, "time": "2019-02-13T09:00:00.000Z"}}
{"transaction": {"merchant": "Burger King", "amount": 20, "time": "2019-02-13T10:00:00.000Z"}}
{"transaction": {"merchant": "Burger King", "amount": 20, "time": "2019-02-13T10:00:01.000Z"}}
{"transaction": {"merchant": "Habbib's", "amount": 90, "time": "2019-02-13T11:00:00.000Z"}}
{"transaction": {"merchant": "McDonald's", "amount": 30, "time": "2019-02-13T12:00:00.000Z"}}
``` 

## Output
The application will process each line from the input file and return if there are any broken validation rule. For the input above it should return as following:
```
{"violations":[],"account":{"available_limit":100,"active_card":true}}
{"violations":[],"account":{"available_limit":95,"active_card":true}}
{"violations":[],"account":{"available_limit":75,"active_card":true}}
{"violations":["double-transaction"],"account":{"available_limit":75,"active_card":true}}
{"violations":["insufficient-limit"],"account":{"available_limit":75,"active_card":true}}
{"violations":[],"account":{"available_limit":45,"active_card":true}}
```

## Violations
* `account-not-initialized`: trying to process a transaction without having created an account
* `card-not-active`: trying to transaction with an inactive card
* `account-already-initialized`: trying to create an account twice. An operation to create an account can only be sent once and accounts cannot be recreated.
* `insufficient-limit`: trying to process a transaction with a higher amount than the account's funds
* `high-frequency-small-interval`: trying to process more than 3 transactions within 2 minutes
* `double-transction`: trying to process two transactions with the same amount for the same merchant within 2 minutes

## About the project
This project was developed using Elixir. It's structured as following:

```
root
├── lib
│   ├── manager
│   │   ├── account_manager.ex
│   │   └── transaction_manager.ex
│   ├── mix
│   │   └── authorizer.ex
│   ├── account.ex
│   ├── authorizer.ex
│   └── transaction.ex
└── test
    └── authorizer_test.exs
```

* **manager:** this directory contains the Elixir modules that implement the [GenServer behaviour](https://hexdocs.pm/elixir/GenServer.html). GenServers are Elixir processes that can be used to keep state. 
    * **AccountManager:** used to keep the account state between transactions, besides validating and effectively processing them, updating the account state.
    * **TransactionManager:** used to register the transactions made. This structure is mainly created and used aiming to validate transaction velocity rules. 
* **mix/authorizer:** module that implements the [Mix.Task behaviour](https://hexdocs.pm/mix/Mix.Task.html). This task was created to make easier to compile and run the application with one single command, already calling the main application module and passing as a parameter the file with the operations to be processed.
* **account.ex:** defines the struct for an account and its keys
* **authorizer.ex:** the main application module. This process the file lines and calls the correct function for each operation, from AccountManager.
* **transaction.ex:** defines the struct for a transaction, defining its keys, like the merchant, amount and datetime. 


## Testing
Tests were created using ExUnit framework.
* Run tests using `mix test`
