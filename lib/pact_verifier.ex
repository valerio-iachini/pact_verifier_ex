defmodule Pact.PactVerifier do
  @moduledoc false
  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :pact_verifier_ex,
    crate: "pact_verifier_nif",
    base_url: "https://github.com/valerio-iachini/pact_verifier_ex/releases/download/v#{version}",
    force_build: System.get_env("PACT_VERIFIER_EX_FORCE_BUILD") == "true",
    version: version,
    targets: [
      "aarch64-apple-darwin",
      "aarch64-unknown-linux-gnu",
      "arm-unknown-linux-gnueabihf",
      "riscv64gc-unknown-linux-gnu",
      "x86_64-apple-darwin",
      "x86_64-pc-windows-gnu",
      "x86_64-pc-windows-msvc",
      "x86_64-unknown-linux-gnu"
    ]

  defmodule ProviderInfo do
    @moduledoc """
    Information about the Provider to verify.

    Fields:
    - name: Provider Name
    - protocol: Provider protocol, defaults to HTTP (deprecated, use transports instead)
    - host: Hostname of the provider
    - port: Port the provider is running on, defaults to 8080 (deprecated, use transports instead)
    - path: Base path for the provider, defaults to / (deprecated, use transports instead)
    - transports: Transports configured for the provider
    """
    @enforce_keys [:name, :protocol, :host, :port, :path, :transports]
    defstruct [
      :name, # Provider Name
      :protocol, # Provider protocol, defaults to HTTP (deprecated, use transports instead)
      :host, # Hostname of the provider
      :port, # Port the provider is running on, defaults to 8080 (deprecated, use transports instead)
      :path, # Base path for the provider, defaults to / (deprecated, use transports instead)
      :transports # Transports configured for the provider
    ]

    @type t :: %__MODULE__{
            name: String.t(),
            protocol: String.t(),
            host: String.t(),
            port: nil | integer(),
            path: String.t(),
            transports: [Pact.PactVerifier.ProviderTransport.t()]
          }

    @doc """
    Create a default provider info struct.
    """
    @spec default() :: __MODULE__.t()
    def default() do
      %__MODULE__{
        name: "provider",
        protocol: "http",
        host: "localhost",
        port: 8080,
        path: "/",
        transports: []
      }
    end
  end

  defmodule ProviderTransport do
    @moduledoc """
    Information about the Provider transport to verify.

    Fields:
    - transport: Protocol Transport
    - port: Port to use for the transport
    - path: Base path to use for the transport (for protocols that support paths)
    - scheme: Transport scheme to use. Will default to HTTP
    """
    @enforce_keys [:transport]
    defstruct [
      :transport, # Protocol Transport
      :port, # Port to use for the transport
      :path, # Base path to use for the transport (for protocols that support paths)
      :scheme # Transport scheme to use. Will default to HTTP
    ]

    @type t :: %__MODULE__{
            transport: String.t(),
            port: nil | integer(),
            path: nil | String.t(),
            scheme: nil | String.t()
          }

    @doc """
    Create a default provider transport struct.
    """
    @spec default() :: __MODULE__.t()
    def default() do
      %__MODULE__{
        transport: "http",
        port: 8080,
        path: nil,
        scheme: "http"
      }
    end

    @doc """
    Calculate a base URL for the transport.

    ## Parameters
    - provider_transport: The transport struct
    - hostname: The hostname to use

    ## Returns
    - The base URL as a string
    """
    @spec base_url(provider_transport :: __MODULE__.t(), hostname :: String.t()) :: String.t()
    def base_url(%{scheme: scheme, port: port, path: path}, hostname) do
      scheme = scheme || "http"
      path = path || ""

      case port do
        nil -> "#{scheme}://#{hostname}#{path}"
        _ -> "#{scheme}://#{hostname}:#{port}#{path}"
      end
    end
  end

  defmodule HttpAuth do
    @moduledoc """
    HttpAuth
    """
    @type t ::
            {:user, String.t(), nil | String.t()}
            | {:token, String.t()}
            | :none

    @spec default() :: __MODULE__.t()
    def default(), do: {:user, "", nil}

    @spec user(username :: String.t(), password :: nil | String.t()) :: __MODULE__.t()
    def user(username, password \\ nil), do: {:user, username, password}

    @spec token(token :: String.t()) :: __MODULE__.t()
    def token(token), do: {:token, token}
  end

  defmodule Link do
    @moduledoc """
    Link
    """
    @enforce_keys [:name, :templated]
    defstruct [
      :name,
      :href,
      :templated,
      :title
    ]

    @type t :: %__MODULE__{
            name: String.t(),
            href: nil | String.t(),
            templated: boolean(),
            title: nil | String.t()
          }

    @spec default() :: __MODULE__.t()
    def default() do
      %__MODULE__{
        name: "link",
        href: nil,
        templated: false,
        title: nil
      }
    end
  end

  defmodule ConsumerVersionSelector do
    @moduledoc """
    Structure to represent a consumer version selector for filtering pacts to verify.

    ## Fields
    * `consumer` - Application name to filter the results on. Allows a selector to only be applied to a certain consumer.
    * `tag` - Tag name(s) of the consumer versions to get the pacts for. Recommended to use `branch` in preference now.
    * `fallback_tag` - Fallback tag if tag doesn’t exist. Name of the tag to fallback to if the specified `tag` does not exist.
    * `latest` - Only select the latest (if false, selects all pacts for a tag). Used with the tag property.
    * `deployed_or_released` - Applications that have been deployed or released. Returns pacts for all versions of the consumer that are currently deployed or released and supported in any environment.
    * `deployed` - Applications that have been deployed. Returns pacts for all versions of the consumer that are currently deployed to any environment.
    * `released` - Applications that have been released. Returns pacts for all versions of the consumer that are released and currently supported in any environment.
    * `environment` - Name of the environment containing the consumer versions for which to return the pacts.
    * `main_branch` - Applications with the default branch set in the broker. Returns pacts for the configured `mainBranch` of each consumer.
    * `branch` - Branch name of the consumer versions to get the pacts for.
    * `matching_branch` - Applications that match the provider version branch sent during verification. When true, returns the latest pact for any branch with the same name as the specified `provider_version_branch`.
    * `fallback_branch` - Fallback branch if branch doesn’t exist. Name of the branch to fallback to if the specified branch does not exist.
    """
    @enforce_keys [:consumer, :tag, :fallback_tag, :latest, :deployed_or_released, :deployed, :released, :environment, :main_branch, :branch, :matching_branch, :fallback_branch]
    defstruct [
      :consumer,
      :tag,
      :fallback_tag,
      :latest,
      :deployed_or_released,
      :deployed,
      :released,
      :environment,
      :main_branch,
      :branch,
      :matching_branch,
      :fallback_branch
    ]

    @type t :: %__MODULE__{
            consumer: nil | String.t(),
            tag: nil | String.t(),
            fallback_tag: nil | String.t(),
            latest: nil | boolean(),
            deployed_or_released: nil | boolean(),
            deployed: nil | boolean(),
            released: nil | boolean(),
            environment: nil | String.t(),
            main_branch: nil | boolean(),
            branch: nil | String.t(),
            matching_branch: nil | boolean(),
            fallback_branch: nil | String.t()
          }
  end

  defmodule PactSource do
    @moduledoc """
    Source for loading pacts.

    ## Variants
    * `Unknown` - Unknown pact source.
    * `File` - Load the pact from a pact file.
    * `Dir` - Load all the pacts from a directory.
    * `URL` - Load the pact from a URL.
    * `BrokerUrl` - Load all pacts with the provider name from the pact broker URL.
    * `BrokerWithDynamicConfiguration` - Load pacts with the newer pacts for verification API. Includes provider name, broker URL, pending/wip options, selectors, auth, and links.
    * `String` - Load the Pact from some JSON (used for testing purposes).
    * `WebhookCallbackUrl` - Load the given pact with the URL via a webhook callback.
    """
    defmodule BrokerDynamicConfig do
      @moduledoc false
      defstruct [
        :provider_name,
        :broker_url,
        :enable_pending,
        :include_wip_pacts_since,
        :provider_tags,
        :provider_branch,
        :selectors,
        :auth,
        :links
      ]

      @type t :: %__MODULE__{
              provider_name: String.t(),
              broker_url: String.t(),
              enable_pending: boolean(),
              include_wip_pacts_since: nil | String.t(),
              provider_tags: [String.t()],
              provider_branch: nil | String.t(),
              selectors: [Pact.PactVerifier.ConsumerVersionSelector.t()],
              auth: nil | Pact.PactVerifier.HttpAuth.t(),
              links: [Pact.PactVerifier.Link.t()]
            }
    end

    @type t ::
            :unknown
            | {:file, String.t()}
            | {:dir, String.t()}
            | {:url, String.t(), nil | Pact.PactVerifier.HttpAuth.t()}
            | {:broker_url, String.t(), String.t(), nil | Pact.PactVerifier.HttpAuth.t(), [Pact.PactVerifier.Link.t()]}
            | {:broker_with_dynamic_configuration, BrokerDynamicConfig.t()}
            | {:string, String.t()}
            | {:webhook_callback_url,
               %{pact_url: String.t(), broker_url: String.t(), auth: nil | Pact.PactVerifier.HttpAuth.t()}}

    @spec file(String.t()) :: t()
    def file(path), do: {:file, path}

    @spec dir(String.t()) :: t()
    def dir(path), do: {:dir, path}

    @spec url(String.t(), nil | Pact.PactVerifier.HttpAuth.t()) :: t()
    def url(url, auth \\ nil), do: {:url, url, auth}

    @spec broker_url(String.t(), String.t(), nil | Pact.PactVerifier.HttpAuth.t(), [Pact.PactVerifier.Link.t()]) :: t()
    def broker_url(provider_name, broker_url, auth \\ nil, links \\ []),
      do: {:broker_url, provider_name, broker_url, auth, links}

    @spec broker_with_dynamic_configuration(BrokerDynamicConfig.t()) :: t()
    def broker_with_dynamic_configuration(opts = %BrokerDynamicConfig{}) do
      {:broker_with_dynamic_configuration, opts}
    end

    @spec string(String.t()) :: t()
    def string(contract), do: {:string, contract}

    @spec webhook_callback_url(String.t(), String.t(), nil | Pact.PactVerifier.HttpAuth.t()) :: t()
    def webhook_callback_url(pact_url, broker_url, auth \\ nil),
      do: {:webhook_callback_url, %{pact_url: pact_url, broker_url: broker_url, auth: auth}}
  end

  defmodule FilterById do
    @moduledoc """
    Filter information used to filter the interactions that are verified by ID.

    ## Variants
    * `InteractionId` - Filter by matching interaction ID.
    * `InteractionKey` - Filter by matching interaction key.
    * `InteractionDesc` - Filter by matching interaction description.
    """
    @type t ::
            {:interaction_id, String.t()}
            | {:interaction_key, String.t()}
            | {:interaction_desc, String.t()}

    @spec interaction_id(String.t()) :: t()
    def interaction_id(id), do: {:interaction_id, id}

    @spec interaction_key(String.t()) :: t()
    def interaction_key(key), do: {:interaction_key, key}

    @spec interaction_desc(String.t()) :: t()
    def interaction_desc(desc), do: {:interaction_desc, desc}
  end

  defmodule FilterInfo do
    @moduledoc """
    Filter information used to filter the interactions that are verified.

    ## Variants
    * `None` - No filter, all interactions will be verified.
    * `Description` - Filter on the interaction description.
    * `State` - Filter on the interaction provider state.
    * `DescriptionAndState` - Filter on both the interaction description and provider state.
    * `InteractionIds` - Filter on the list of interaction IDs.
    """
    @type t ::
            :none
            | {:description, String.t()}
            | {:state, String.t()}
            | {:description_and_state, String.t(), String.t()}
            | {:interaction_ids, [FilterById.t()]}

    @spec none() :: t()
    def none, do: :none

    @spec description(String.t()) :: t()
    def description(desc), do: {:description, desc}

    @spec state(String.t()) :: t()
    def state(state), do: {:state, state}

    @spec description_and_state(String.t(), String.t()) :: t()
    def description_and_state(desc, state), do: {:description_and_state, desc, state}

    @spec interaction_ids([FilterById.t()]) :: t()
    def interaction_ids(ids), do: {:interaction_ids, ids}
  end

  defmodule PublishOptions do
    @moduledoc """
    Options for publishing results to the Pact Broker.

    ## Fields
    * `provider_version` - Provider version being published.
    * `build_url` - Build URL to associate with the published results.
    * `provider_tags` - Tags to use when publishing results.
    * `provider_branch` - Provider branch used when publishing results.
    """
    defstruct [
      :provider_version,
      :build_url,
      :provider_tags,
      :provider_branch
    ]

    @type t :: %__MODULE__{
            provider_version: nil | String.t(),
            build_url: nil | String.t(),
            provider_tags: [String.t()],
            provider_branch: nil | String.t()
          }

    @spec default() :: __MODULE__.t()
    def default() do
      %__MODULE__{
        provider_version: nil,
        build_url: nil,
        provider_tags: [],
        provider_branch: nil
      }
    end
  end

  defmodule VerificationMetrics do
    @moduledoc """
    Structure for providing metrics and metadata about the verification process.

    This struct is used to supply information about the test framework, application name, and application version
    to the verifier. These metrics may be published to the Pact Broker or used for reporting and analytics.

    ## Fields
    * `test_framework` - The name of the test framework being used (e.g., ExUnit, ESpec).
    * `app_name` - The name of the application running the verification.
    * `app_version` - The version of the application running the verification.
    """
    defstruct [
      :test_framework,
      :app_name,
      :app_version
    ]

    @type t :: %__MODULE__{
            test_framework: String.t(),
            app_name: String.t(),
            app_version: String.t()
          }
  end

  defmodule HttpRequest do
    @moduledoc """
    Structure representing an HTTP request used during provider verification.

    This struct is used to model HTTP requests sent to the provider or for state change callbacks during the verification process.

    ## Fields
    * `method` - The HTTP method (e.g., GET, POST, PUT, DELETE).
    * `path` - The request path (relative to the provider base URL).
    * `query` - Optional map of query parameters.
    * `headers` - Optional map of HTTP headers to include in the request.
    """
    defstruct [
      :method,
      :path,
      :query,
      :headers
    ]

    @type t :: %__MODULE__{
            method: String.t(),
            path: String.t(),
            query: nil | map(),
            headers: nil | map()
          }
  end
  defmodule VerificationOptions do
    @moduledoc """
    Options to use when running the verification.

    ## Fields
    * `request_filter` - Request filter callback.
    * `disable_ssl_verification` - Ignore invalid/self-signed SSL certificates.
    * `request_timeout` - Timeout in ms for verification requests and state callbacks.
    * `custom_headers` - Custom headers to be added to the requests to the provider.
    * `coloured_output` - If coloured output should be used (using ANSI escape codes).
    * `no_pacts_is_error` - If no pacts are found to verify, then this should be an error.
    * `exit_on_first_failure` - Exit verification run on first failure.
    * `run_last_failed_only` - Only execute the interactions that failed on the previous verifier run.
    """
    defstruct [
      :request_filter,
      :disable_ssl_verification,
      :request_timeout,
      :custom_headers,
      :coloured_output,
      :no_pacts_is_error,
      :exit_on_first_failure,
      :run_last_failed_only
    ]

    @type t :: %__MODULE__{
            #request_filter: nil,
            disable_ssl_verification: boolean(),
            request_timeout: integer(),
            custom_headers: map(),
            coloured_output: boolean(),
            no_pacts_is_error: boolean(),
            exit_on_first_failure: boolean(),
            run_last_failed_only: boolean()
          }

    @spec default() :: __MODULE__.t()
    def default() do
      %__MODULE__{
        #request_filter: nil,
        disable_ssl_verification: false,
        request_timeout: 5000,
        custom_headers: %{},
        coloured_output: true,
        no_pacts_is_error: true,
        exit_on_first_failure: false,
        run_last_failed_only: false
      }
    end
  end

  defmodule HttpRequestProviderStateExecutor do
    @moduledoc """
    Executor for provider state changes using HTTP requests.

    This struct configures how provider state changes are executed via HTTP requests during verification.
    It allows specifying the URL to call for state changes, whether to perform teardown calls after verification,
    whether to include the state change in the request body, and how many times to retry the state change call on failure.

    ## Fields
    * `state_change_url` - The URL to call for provider state changes. If not set, no state change requests will be made.
    * `state_change_teardown` - If true, a teardown request will be made after verification to clean up provider state.
    * `state_change_body` - If true, the state change will be sent in the request body as JSON. If false, it will be sent as query parameters.
    * `reties` - The number of times to retry the state change request if it fails.
    """
    defstruct [
      :state_change_url,
      :state_change_teardown,
      :state_change_body,
      :reties
    ]

    @type t :: %__MODULE__{
            state_change_url: nil | String.t(),
            state_change_teardown: boolean(),
            state_change_body: boolean(),
            reties: integer()
          }

    @spec default() :: __MODULE__.t()
    def default() do
      %__MODULE__{
        state_change_url: nil,
        state_change_teardown: false,
        state_change_body: true,
        reties: 3
      }
    end
  end

  @doc """
  Verifies a provider against one or more pacts.

  This function runs the verification process for a provider, using the specified provider information, pact sources,
  filters, consumers, verification options, publish options, provider state executor, and optional metrics data.
  It returns true if all verifications succeed, or false if any verification fails.

  ## Parameters
  - `provider_info` - Information about the provider to verify (see `ProviderInfo`).
  - `source` - List of pact sources to verify against (see `PactSource`).
  - `filter` - Filter information to select which interactions to verify (see `FilterInfo`).
  - `consumers` - List of consumer names to restrict verification to.
  - `verification_options` - Options to control the verification process (see `VerificationOptions`).
  - `publish_options` - Options for publishing verification results to a Pact Broker (see `PublishOptions`).
  - `provider_state_executor` - Executor for provider state changes (see `HttpRequestProviderStateExecutor`).
  - `metrics_data` - Optional metrics data to include with the verification (see `VerificationMetrics`).

  ## Returns
  - `true` if all verifications succeed, `false` otherwise.

  This function is a NIF binding to the Rust implementation and will raise if the NIF is not loaded.
  """
  @spec verify_provider(
          provider_info :: ProviderInfo.t(),
          source :: list(PactSource.t()),
          filter :: FilterInfo.t(),
          consumers :: list(String.t()),
          verification_options :: VerificationOptions.t(),
          publish_options :: PublishOptions.t() | nil,
          provider_state_executor :: HttpRequestProviderStateExecutor.t(),
          metrics_data :: VerificationMetrics.t() | nil
        ) :: bool()
  def verify_provider(
        _provider_info,
        _source,
        _filter,
        _consumers,
        _verification_options,
        _publish_options,
        _provider_state_executor,
        _metrics_data
      ),
      do: :erlang.nif_error(:nif_not_loaded)
end
