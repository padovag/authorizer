# Authorizer
An account authorizer simulator made with [**Elixir**](https://elixir-lang.org/getting-started/introduction.html). 
This project contains modules that process a bank account transactions according to the documentation below, and a mix task that process said operations from an input file.


## Installing and Running
* Install elixir to your system. Run `brew install elixir` if you're using MacOs, otherwise check [the installation guide](https://elixir-lang.org/install.html).
* Install the dependencies with `mix deps.get`
* Run the code through the mix task `mix authorizer [FILE_PATH]`

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
