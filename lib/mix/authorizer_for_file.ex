defmodule Mix.Tasks.AuthorizerForFile do
  use Mix.Task

  def run(parameters) do
    Mix.Task.run("app.start")

    {:ok, content} = File.read(parameters)
    lines = content |> String.split("\n")
    operations = lines |> Enum.map(fn line -> Poison.decode!(line) end)

    Authorizer.authorize(operations)
    |> Enum.map(fn account -> Poison.encode!(account) end)
    |> Enum.join("\n")
    |> IO.puts()
  end

end
