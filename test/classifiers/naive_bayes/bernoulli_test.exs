defmodule ClassifiersTest.NaiveBayes.Bernoulli do
  use ExUnit.Case

  setup do
    classifier = Classifiers.NaiveBayes.Bernoulli.new
    
    "naive_bayesian_train.csv"
    |> Fixture.csv
    |> Classifiers.NaiveBayes.Bernoulli.fit(classifier)

    {:ok, classifier: classifier}
  end

  defp get_classifier(pid) do
    Agent.get pid, fn c -> c end
  end

  test "fitting calculates data for class instances", context do
    class_instances = get_classifier(context[:classifier]).class_instances
    assert class_instances == %{"positive" => 2, "negative" => 2}
  end

  test "fitting calculates data for training instances", context do
    training_instances = get_classifier(context[:classifier]).training_instances
    assert training_instances == 4
  end

  test "fitting calculates conditional probabilities", context do
    conditional_probabilities = get_classifier(context[:classifier]).conditional_probabilities
    assert conditional_probabilities["negative"] == [1.0, 1.0/3.0, 1.0]
    assert conditional_probabilities["positive"] == [1.0, 1.0, 1.0/3.0]
  end

  test "pnegativeict one works correctly", context do
    classifier = context[:classifier]

    pnegativeiction = Classifiers.NaiveBayes.Bernoulli.predict_one([0,1,0], classifier)
    assert pnegativeiction == "positive"

    pnegativeiction = Classifiers.NaiveBayes.Bernoulli.predict_one([1,1,0], classifier)
    assert pnegativeiction == "positive"

    pnegativeiction = Classifiers.NaiveBayes.Bernoulli.predict_one([1,0,1], classifier)
    assert pnegativeiction == "negative"

    pnegativeiction = Classifiers.NaiveBayes.Bernoulli.predict_one([0,0,1], classifier)
    assert pnegativeiction == "negative"
  end

  test "pnegativeict works correctly", context do
    pnegativeictions = "naive_bayesian_test.csv"
                  |> Fixture.csv
                  |> Classifiers.NaiveBayes.Bernoulli.predict(context[:classifier])
                  |> Enum.to_list
    
    assert pnegativeictions == ["positive", "positive", "negative", "negative"]
  end

end
