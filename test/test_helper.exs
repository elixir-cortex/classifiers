"support"
|> Path.expand(__DIR__)
|> Path.join("**/*.exs")
|> Path.wildcard
|> Enum.map(&Code.require_file/1)

ExUnit.start

