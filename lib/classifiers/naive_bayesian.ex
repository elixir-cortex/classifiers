defmodule Classifiers.NaiveBayesian do
  defstruct class_instances: %{},
            training_instances: 0,
            features: 0,
            conditional_probabilities: %{}

  @doc """
    Get a new classifier pid.
  """
  def new do
    {:ok, pid} = Agent.start_link fn ->
      %Classifiers.NaiveBayesian{}
    end

    pid
  end

  @doc """
    Fit a stream of data to an existing classifier.
    Currently expects input in the form of a stream of lists as the following:
     [ feature_1, feature_2, ... feature_n, class ]
  """
  def fit(stream, pid) do
    Agent.get_and_update pid, fn classifier ->
      {c, rows_with_term} = Enum.reduce(
        stream, { classifier, %{} },
        fn row, { classifier, rows_with_term } ->
          class = row |> List.last
          features = row |> Enum.drop(-1) |> to_binary_features

          rows_with_term = rows_with_term |>
            update_rows_with_term(
              class,
              features
            )

          classifier = classifier |> update_classifier(class, features)

          { classifier, rows_with_term }
        end
      )

      c = c |> update_classifier(rows_with_term)

      {:ok, c}
    end
  end

  @doc """
    Predict the class for one set of features.
  """
  def predict_one(features, pid) do
    pid |> classifier |> make_prediction(features)
  end

  @doc """
    Predict the classes for a stream of features
  """
  def predict(stream, pid) do
    c = pid |> classifier

    Stream.transform stream, [], fn row, acc ->
      features = row |> Enum.drop(-1) |> to_binary_features
      { [c |> make_prediction(features)], acc }
    end
  end

  defp update_rows_with_term(rows, class, features) do
    Map.update rows, class, features, fn existing ->
      Enum.zip(existing, features) |> Enum.map fn {a, b} -> a + b end
    end
  end

  defp update_classifier(classifier, class, features) do
    %{ 
      classifier |
      class_instances: Map.update(
        classifier.class_instances,
        class,
        1,
        &(&1 + 1)
      ),
      features: features |> Enum.count,
      training_instances: classifier.training_instances + 1
    }
  end

  defp update_classifier(classifier, rows_with_term) do
    %{
        classifier | 
        conditional_probabilities: Enum.reduce(
          classifier.class_instances, %{},
          fn {class, instances}, conditional_probabilities ->
            conditional_probabilities = Map.put(
              conditional_probabilities,
              class,
              Enum.map(
                rows_with_term[class],
                fn contained -> (contained + 1) / (instances + 1) end
              )
            )

            conditional_probabilities
          end
        )
    }
  end

  defp classifier(pid) do
    Agent.get pid, fn c -> c end
  end

  defp make_prediction(classifier, features) do
    {prediction, _} = Enum.max_by(
      classifier.class_instances,
      fn { class, class_count } ->
        score = :math.log(class_count / classifier.training_instances)

        features
          |> Stream.with_index
          |> Enum.reduce score, fn { feature, index }, score ->
            conditional_probability = :math.log(
              classifier.conditional_probabilities[class] |> Enum.fetch! index
            )
            case { feature, conditional_probability } do
              { 1, p } ->
                score + p
              { 0, 1 } ->
                score + :math.log(1 / class_count + 1)
              { 0, p } ->
                score + :math.log(1 - p)
            end
          end
      end
    )
    
    prediction
  end

  defp to_binary_features(row) do
    row |> Enum.map fn f ->
      case f do
        "0" -> 0
        _ -> 1
      end
    end
  end

end
