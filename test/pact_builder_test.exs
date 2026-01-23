defmodule Pact.Builders.PactBuilderTest do
  alias Pact.PactVerifier

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

    match _ do
      send_resp(conn, 404, "not found")
    end

    def start_link(port) do
      {:ok, _} = Plug.Cowboy.http(__MODULE__, [], port: port)
    end
  end

  setup do
    port = 4001
    {:ok, _pid} = AliceService.start_link(port)
    {:ok, port: port}
  end

  test "verifies provider using pact-one.json", %{port: port} do
    provider_info = %{PactVerifier.ProviderInfo.default() | name: "Alice Service", port: port}

    pact_path = Path.expand("../test/pact-one.json", __DIR__)
    source = [Pact.PactVerifier.PactSource.file(pact_path)]

    filter = Pact.PactVerifier.FilterInfo.none()

    consumers = []

    verification_options = Pact.PactVerifier.VerificationOptions.default()

    publish_options = nil

    provider_state_executor = Pact.PactVerifier.HttpRequestProviderStateExecutor.default()

    metrics_data = nil

    result =
      Pact.PactVerifier.verify_provider(
        provider_info,
        source,
        filter,
        consumers,
        verification_options,
        publish_options,
        provider_state_executor,
        metrics_data
      )

    assert result == true
  end
end
