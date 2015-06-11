defmodule Classifiers.Perceptron.Average do
  defstruct weights: %{},
            edges: %{},
            count: 0,
            epoch: 0

  @doc """
    Get a new classifier pid.
  """
  def new do
    {:ok, pid} = Agent.start_link fn ->
      %Classifiers.Perceptron.Average{}
    end

    pid
  end

  @doc """
    Fit a stream of data to an existing classifier.
    Currently expects input in the form of a stream of maps as the following:
     [ feature_1, feature_2, ... feature_n, class ]
  """
  def fit(stream, pid) do
    stream |> Stream.chunk(10) |> Enum.each fn chunk ->
      Agent.get_and_update pid, fn classifier ->
        c = chunk |> Enum.reduce classifier, fn row, classifier ->
          label = row |> List.last
          features = row |> Enum.drop(-1)
                         |> Enum.with_index
                         |> Enum.map(fn {a, b} -> {a,b} end)

          classifier = case classifier |> make_prediction(features, true) do
            nil ->
              %{ 
                classifier | edges: classifier.edges |> Map.put(
                  label, features |> Enum.into(%{}, &({&1, 1}))
                )
              }
            ^label ->
              classifier
            prediction ->
              %{
                classifier | edges: classifier.edges |> Map.update(
                  label, %{}, fn current ->
                    features |> Enum.reduce(
                      current, fn feature, current ->
                        current |> Map.update(feature, 0, &(&1 + 1))
                      end
                    )
                  end 
                ) |> Map.update(
                  prediction, %{}, fn current ->
                    features |> Enum.reduce(
                      current, fn feature, current ->
                        current |> Map.update(feature, 0, &(&1 - 1))
                      end
                    )
                  end 
                )
              }
          end

          %{ classifier |
             count: classifier.count + 1,
             weights: classifier.edges |> Enum.reduce(
                classifier.weights, fn { label, edges }, weights ->
                  target = weights |> Map.get(label, %{})
                  target = edges |> Enum.reduce(target, fn { feature, edge }, target ->
                    target |> Map.update(feature, 0, fn weight -> 
                      (classifier.count * weight + edge) / (classifier.count + 1)
                    end)
                  end)

                  weights |> Map.update(label, %{}, fn w -> w |> Map.merge(target) end)
                end
              )
          }
        end

        {:ok, c}
      end
    end
  end

  @doc """
    Predict the class for one set of features.
  """
  def predict_one(features, pid) do
  end

  @doc """
    Predict the classes for a stream of features
  """
  def predict(stream, pid) do
    c = classifier(pid)
    stream |> Stream.transform(0, fn row, acc ->
      features = row |> Enum.with_index |> Enum.map(fn {a, b} -> {a, b} end)

      { [ c |> make_prediction(features, false) ], acc + 1 } 
    end)
  end

  defp make_prediction(%{edges: edges}, features, true) when map_size(edges) == 0 do
  end
  defp make_prediction(%{edges: edges}, features, true) do
    {p, _} = edges |> Enum.max_by fn { label, edge } ->
      features |> Enum.reduce(0, fn feature, weight -> weight + Map.get(edge, feature, 0) end)
    end

    p
  end
  defp make_prediction(%{weights: weights}, features, false) do
    {p, _} = weights |> Enum.max_by fn { label, weight } ->
      features |> Enum.reduce(0, fn feature, w -> w + Map.get(weight, feature, 0) end)
    end

    p
  end

  defp classifier(pid) do
    Agent.get pid, fn c -> c end
  end

end
