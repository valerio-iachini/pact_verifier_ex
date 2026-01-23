defmodule Pact.Native.PactVerifier do
  @moduledoc false
  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :pact_verifier_ex,
    crate: "pact_verifier_nif",
    base_url: "https://github.com/valerio-iachini/pact_verifier_ex/releases/download/v#{version}",
    force_build: System.get_env("PACT_CONSUMER_EX_FORCE_BUILD") == "true",
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
      ProviderInfo
      """
      @enforce_keys [:name, :protocol, :host, :port, :path, :transports]
      defstruct [
        :name,
        :protocol,
        :host,
        :port,
        :path,
        :transports
      ]

      @type t :: %__MODULE__{
        name: String.t(),
        protocol: String.t(),
        host: String.t(),
        port: nil | integer(),
        path: String.t(),
        transports: [ProviderTransport.t()]
      }
    end

    defmodule ProviderTransport do
      @moduledoc """
      ProviderTransport
      """
      @enforce_keys [:transport]
      defstruct [
        :transport,
        :port,
        :path,
        :scheme
      ]

      @type t :: %__MODULE__{
        transport: String.t(),
        port: nil | integer(),
        path: nil | String.t(),
        scheme: nil | String.t()
      }
    end

    defmodule HttpAuth do
      @moduledoc """
      HttpAuth
      """
      @type t ::
        {:user, String.t(), nil | String.t()} |
        {:token, String.t()} |
        :none
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
    end

    defmodule ConsumerVersionSelector do
      @moduledoc """
      ConsumerVersionSelector
      """
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
      PactSource
      """
      @type t ::
        :unknown |
        {:file, String.t()} |
        {:dir, String.t()} |
        {:url, String.t(), nil | HttpAuth.t()} |
        {:broker_url, String.t(), String.t(), nil | HttpAuth.t(), [Link.t()]} |
        {:broker_with_dynamic_configuration, %{
          provider_name: String.t(),
          broker_url: String.t(),
          enable_pending: boolean(),
          include_wip_pacts_since: nil | String.t(),
          provider_tags: [String.t()],
          provider_branch: nil | String.t(),
          selectors: [ConsumerVersionSelector.t()],
          auth: nil | HttpAuth.t(),
          links: [Link.t()]
        }} |
        {:string, String.t()} |
        {:webhook_callback_url, %{pact_url: String.t(), broker_url: String.t(), auth: nil | HttpAuth.t()}}
    end

    defmodule FilterById do
      @moduledoc """
      FilterById
      """
      @type t ::
        {:interaction_id, String.t()} |
        {:interaction_key, String.t()} |
        {:interaction_desc, String.t()}
    end

    defmodule FilterInfo do
      @moduledoc """
      FilterInfo
      """
      @type t ::
        :none |
        {:description, String.t()} |
        {:state, String.t()} |
        {:description_and_state, String.t(), String.t()} |
        {:interaction_ids, [FilterById.t()]}
    end

    defmodule PublishOptions do
      @moduledoc """
      PublishOptions
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
    end

    defmodule VerificationMetrics do
      @moduledoc """
      VerificationMetrics
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
      HttpRequest
      """
      defstruct [
        :method,
        :path,
        :query,
        :headers
        # TODO: body, matching_rules, generators
      ]

      @type t :: %__MODULE__{
        method: String.t(),
        path: String.t(),
        query: nil | map(),
        headers: nil | map()
      }
    end

    defmodule RequestFilter do
      @moduledoc """
      RequestFilter
      """
      defstruct [
        :pid
      ]

      @type t :: %__MODULE__{
        pid: any()
      }
    end

    defmodule VerificationOptions do
      @moduledoc """
      VerificationOptions
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
        request_filter: nil | RequestFilter.t(),
        disable_ssl_verification: boolean(),
        request_timeout: integer(),
        custom_headers: map(),
        coloured_output: boolean(),
        no_pacts_is_error: boolean(),
        exit_on_first_failure: boolean(),
        run_last_failed_only: boolean()
      }
    end

    defmodule HttpRequestProviderStateExecutor do
      @moduledoc """
      HttpRequestProviderStateExecutor
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
    end

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
    def verify_provider(_description, _interaction_type),
        do: :erlang.nif_error(:nif_not_loaded)
end
