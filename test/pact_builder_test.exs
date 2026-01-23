defmodule Pact.Builders.PactBuilderTest do
  alias Pact.PactVerifier.ProviderInfo
  alias Pact.PactVerifier.FilterInfo
  alias Pact.PactVerifier.VerificationOptions
  alias Pact.PactVerifier.PactSource
  alias Pact.PactVerifier.HttpRequestProviderStateExecutor

  use ExUnit.Case

  defmodule AliceService do
    use Plug.Router

    plug(:match)
    plug(:dispatch)

    get "/mallory" do
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, "\"That is some good Mallory.\"")
    end

    get "/reports/report001.csv" do
      conn
      |> put_resp_content_type("text/csv")
      |> send_resp(200, "Name,100,2000-01-01\n")
    end

    match _ do
      send_resp(conn, 404, "not found")
    end

    def start_link(port) do
      {:ok, _} = Plug.Cowboy.http(__MODULE__, [], port: port)
    end
  end

  setup_all do
    port = 4001
    {:ok, _pid} = AliceService.start_link(port)
    {:ok, port: port}
  end

  test "test verify_provider", %{port: port} do
    pact_path = Path.expand("../test/pacts/pact-one.json", __DIR__)

    result =
      Pact.PactVerifier.verify_provider(
        %{ProviderInfo.default() | name: "Alice Service", port: port},
        [PactSource.file(pact_path)],
        FilterInfo.none(),
        [],
        VerificationOptions.default(),
        nil,
        HttpRequestProviderStateExecutor.default(),
        nil
      )

    assert result == true
  end

  test "plugins", %{port: port} do
    pact_path = Path.expand("../test/pacts/pact-csv.json", __DIR__)

    result =
      Pact.PactVerifier.verify_provider(
        %{ProviderInfo.default() | name: "CsvServer", port: port},
        [PactSource.file(pact_path)],
        FilterInfo.none(),
        [],
        VerificationOptions.default(),
        nil,
        HttpRequestProviderStateExecutor.default(),
        nil
      )

    assert result == true
  end
end
