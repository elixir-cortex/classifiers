defmodule ClassifiersTest.Perceptron.Average do
  use ExUnit.Case

  setup do
    classifier = Classifiers.Perceptron.Average.new
    
    "average_perceptron_train.csv"
    |> Fixture.csv(num_pipes: 1)
    |> Classifiers.Perceptron.Average.fit(classifier, epochs: 1)

    testfile = "average_perceptron_test.csv"
               |> Fixture.csv(num_pipes: 1)


    {:ok, classifier: classifier, testfile: testfile}
  end

  defp get_classifier(pid) do
    Agent.get pid, fn c -> c end
  end

  test "fitting generates averaged weights for the given features", context do
    %{ weights: %{ "democrat" => w } } = context[:classifier] |> get_classifier
    assert w |> Map.size == 48
    assert w |> Map.values |> Enum.sum |> Float.round(3) == 0.367
  end

  test "fitting generates edges for the given features", context do
    %{ edges: %{ "republican" => e } } = context[:classifier] |> get_classifier
    assert e |> Map.size == 48
    assert e |> Map.values |> Enum.sum == 8
  end

  test "predict_one works correctly", context do
    prediction = context[:testfile]
                 |> Enum.take(1)
                 |> List.first
                 |> Classifiers.Perceptron.Average.predict_one(context[:classifier])

    assert prediction == "democrat"
  end

  test "predict works correctly", context do
    predictions = context[:testfile]
                  |> Classifiers.Perceptron.Average.predict(context[:classifier])
                  |> Enum.to_list
    assert predictions == 
      ~w(democrat democrat democrat republican democrat democrat republican democrat republican republican) 
  end

end
