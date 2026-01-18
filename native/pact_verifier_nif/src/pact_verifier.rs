use pact_verifier::PactSource;
use rustler::{Decoder, NifStruct};

#[derive(NifStruct)]
#[module = "ProviderInfo"]
pub struct NifProviderInfo {
    /// Provider Name
    pub name: String,
    /// Provider protocol, defaults to HTTP
    #[deprecated(note = "Use transports instead")]
    pub protocol: String,
    /// Hostname of the provider
    pub host: String,
    /// Port the provider is running on, defaults to 8080
    #[deprecated(note = "Use transports instead")]
    pub port: Option<u16>,
    /// Base path for the provider, defaults to /
    #[deprecated(note = "Use transports instead")]
    pub path: String,
    /// Transports configured for the provider
    pub transports: Vec<NifProviderTransport>,
}

#[derive(NifStruct)]
#[module = "ProviderTransport"]
pub struct NifProviderTransport {
    /// Protocol Transport
    pub transport: String,
    /// Port to use for the transport
    pub port: Option<u16>,
    /// Base path to use for the transport (for protocols that support paths)
    pub path: Option<String>,
    /// Transport scheme to use. Will default to HTTP
    pub scheme: Option<String>,
}

#[rustler::nif(name = "verify_provider")]
pub fn verify_provider(
    provider_info: NifProviderInfo,
    source: Vec<PactSource>,
    filter: FilterInfo,
    consumers: Vec<String>,
    verification_options: &VerificationOptions<F>,
    publish_options: Option<&PublishOptions>,
    provider_state_executor: &Arc<S>,
    metrics_data: Option<VerificationMetrics>,
) -> Result<bool> {
    Ok(false)
}

impl Decoder<'a> for PactSource {
    fn decode(term: rustler::Term<'a>) -> rustler::NifResult<Self> {
        todo!()
    }
}
