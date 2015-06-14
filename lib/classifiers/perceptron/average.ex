defmodule Classifiers.Perceptron.Average do
  defstruct weights: %{},
            edges: %{},
            count: 0,
            epoch: 0

  @stream_chunks 10

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
  def fit(stream, pid, options \\ [epochs: 5]) do
    1..options[:epochs] |> Enum.each fn epoch ->
      stream |> Stream.chunk(@stream_chunks) |> Enum.each fn chunk ->
        Agent.get_and_update pid, &update(&1, chunk, epoch)
      end
    end
  end

  @doc """
    Predict the class for one set of features.
  """
  def predict_one(row, pid) do
    features = row |> Enum.with_index |> Enum.map(fn {a, b} -> {a, b} end)
    classifier(pid) |> make_prediction(features, false)
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

  defp update(classifier, chunk, epoch) do
    c = chunk |> Enum.reduce classifier, fn row, classifier ->
      { label, features } = row |> split_label_and_features

      classifier = case classifier |> make_prediction(features, true) do
        nil ->
          %{
            classifier |
            edges: classifier |> calculate_edges(label, features)
          }
        ^label ->
          classifier
        prediction ->
          %{
            classifier |
            edges: classifier |> calculate_edges(label, features, prediction)
          }
      end

      %{ 
        classifier |
        count: classifier.count + 1,
        epoch: epoch,
        weights: classifier |> calculate_weights
      }
    end

    {:ok, c}
  end

  defp split_label_and_features(row) do
    label = row |> List.last
    features = row |> Enum.drop(-1)
                   |> Enum.with_index
                   |> Enum.map(fn {a, b} -> {a,b} end)

    { label, features }
  end

  defp make_prediction(%{edges: edges}, _, true) when map_size(edges) == 0 do
  end
  defp make_prediction(%{edges: edges}, features, true) do
    {p, _} = edges |> Enum.max_by fn { _, edge } ->
      features |> Enum.reduce(0, fn feature, weight -> weight + Map.get(edge, feature, 0) end)
    end

    p
  end
  defp make_prediction(%{weights: weights}, features, false) do
    {p, _} = weights |> Enum.max_by fn { _, weight } ->
      features |> Enum.reduce(0, fn feature, w -> w + Map.get(weight, feature, 0) end)
    end

    p
  end

  defp calculate_edges(%{edges: edges}, label, features) do
    edges |> Map.put(
      label, features |> Enum.into(%{}, &({&1, 1}))
    )
  end
  defp calculate_edges(%{edges: edges}, label, features, prediction) do
    edges |> Map.update(
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
  end

  defp calculate_weights(%{edges: edges, weights: feature_weights, count: count}) do
    edges |> Enum.reduce(
      feature_weights, fn { label, edges }, weights ->
        target = weights |> Map.get(label, %{})
        target = edges |> Enum.reduce(target, fn { feature, edge }, target ->
          target |> Map.update(feature, 0, fn weight -> 
            (count * weight + edge) / (count + 1)
          end)
        end)

        weights |> Map.update(label, %{}, fn w -> w |> Map.merge(target) end)
      end
    )
  end

  defp classifier(pid) do
    Agent.get pid, fn c -> c end
  end

end
