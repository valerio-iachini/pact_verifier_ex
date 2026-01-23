mod pact_verifier;

use rustler::{Env, Term};
use std::env;

fn on_load(_env: Env, _: Term) -> bool {
    unsafe {
        env::set_var("RUST_BACKTRACE", "1");
    }
    env_logger::init();

    std::panic::set_hook(Box::new(|panic_info| {
        let backtrace = std::backtrace::Backtrace::force_capture();

        if let Some(s) = panic_info.payload().downcast_ref::<&str>() {
            log::error!("panic occurred: {:?}", s);
        } else if let Some(s) = panic_info.payload().downcast_ref::<String>() {
            log::error!("panic occurred: {:?}", s);
        } else {
            log::error!("panic occurred but payload is not a string");
        }

        if let Some(location) = panic_info.location() {
            log::error!(
                "panic occurred in file '{}' at line {}",
                location.file(),
                location.line()
            );
        } else {
            log::error!("panic location unknown.");
        }

        log::error!("backtrace:\n{:?}", backtrace);
    }));

    true
}

rustler::init! {"Elixir.Pact.PactVerifier", load = on_load}
