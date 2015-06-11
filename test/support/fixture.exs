defmodule Fixture do

  def path(filename) do
    Path.join("./fixtures", filename) |> Path.expand(__DIR__)
  end

  def csv(filename, options \\ []) do
    filename
    |> Fixture.path
    |> File.stream!
    |> CSV.decode(options)
  end

end
