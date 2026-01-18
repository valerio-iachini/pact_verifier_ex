defmodule Pact.Native.PactVerifier do
  @moduledoc false
  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :pact_consumer_ex,
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
       @enforce_keys [:inner]
       defstruct [:inner]

      @type t :: %__MODULE__{
        inner: reference()
      }
    end

    defmodule ProviderTransport do
       @moduledoc """
       ProviderInfo
       """
       @enforce_keys [:inner]
       defstruct [:inner]

      @type t :: %__MODULE__{
        inner: reference()
      }
    end

end
