# pact_verifier_ex

`pact_verifier_ex` is an Elixir library that provides Native Implemented Function (NIF) bindings to the [`pact_verifier`](https://github.com/pact-foundation/pact-reference/tree/master/rust/pact_verifier) Rust library. It leverages [Rustler](https://github.com/rusterlium/rustler) to expose the Rust functions while maintaining the same look and feel as the original library. This library enables provider verification for Pact contracts in Elixir projects, using the official Rust implementation under the hood.

## Installation


Add to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:pact_verifier_ex, "~> 0.1.0", only: [:test]}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Usage


For example usage of the library, refer to the [`test/pact_builder_test.exs`](test/pact_builder_test.exs) file, which contains practical examples demonstrating how to verify a provider using Pact contracts and the exposed NIF functions.

## Configuration


This library uses the same environment variables as the Rust `pact_verifier` library ([Pact provider verification in Rust - Pact Docs](https://docs.pact.io/implementation_guides/rust/pact_verifier)):


## Pact Plugins

To use a plugin, install it with the [`pact-plugin-cli`](https://github.com/pact-foundation/pact-plugins/releases?q=pact+plugin+cli&expanded=true). By default, plugins are installed under `~/.pact/plugins/`. You can change this location by setting the `PACT_PLUGIN_DIR` environment variable.

See an example plugin usage in [`test/pact_builder_test.exs`](test/pact_builder_test.exs).

For more information about plugins, refer to the [Pact plugin quick start guide](https://docs.pact.io/plugins/quick_start).

## Current Status


Currently, `pact_verifier_ex` supports:

- Provider verification for HTTP and message-based pacts
- Integration with Pact plugins


Planned future enhancements include:
- Implement RequestFilter
- Implement Matching rules and generators


## Contributing

Contributions are welcome! Please open issues or submit pull requests for any enhancements or bug fixes.


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
