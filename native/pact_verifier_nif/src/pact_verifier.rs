use std::{collections::HashMap, sync::Arc};

use pact_models::{
    bodies::OptionalBody,
    prelude::{Generators, HttpAuth, MatchingRules},
    v4::http_parts::HttpRequest,
};
use pact_verifier::{
    callback_executors::HttpRequestProviderStateExecutor, metrics::VerificationMetrics,
    pact_broker::Link, ConsumerVersionSelector, FilterById, FilterInfo, NullRequestFilterExecutor,
    PactSource, ProviderInfo, ProviderTransport, PublishOptions, VerificationOptions,
};
use rustler::{NifResult, NifStruct, NifTaggedEnum};

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.ProviderInfo"]
pub struct ExProviderInfo {
    pub name: String,
    #[deprecated(note = "Use transports instead")]
    pub protocol: String,
    pub host: String,
    #[deprecated(note = "Use transports instead")]
    pub port: Option<u16>,
    #[deprecated(note = "Use transports instead")]
    pub path: String,
    pub transports: Vec<ExProviderTransport>,
}

impl From<ExProviderInfo> for ProviderInfo {
    #![allow(deprecated)]
    fn from(value: ExProviderInfo) -> Self {
        Self {
            name: value.name,
            protocol: value.protocol,
            host: value.host,
            port: value.port,
            path: value.path,
            transports: value.transports.into_iter().map(Into::into).collect(),
        }
    }
}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.ProviderTransport"]
pub struct ExProviderTransport {
    pub transport: String,
    pub port: Option<u16>,
    pub path: Option<String>,
    pub scheme: Option<String>,
}

impl From<ExProviderTransport> for ProviderTransport {
    fn from(value: ExProviderTransport) -> Self {
        Self {
            transport: value.transport,
            port: value.port,
            path: value.path,
            scheme: value.scheme,
        }
    }
}

#[derive(NifTaggedEnum)]
pub enum ExHttpAuth {
    User(ExUserAuth),
    Token(ExTokenAuth),
    None,
}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.HttpAuth.UserAuth"]
pub struct ExUserAuth {
    username: String,
    password: Option<String>,
}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.HttpAuth.TokenAuth"]
pub struct ExTokenAuth {
    value: String,
}

impl From<ExHttpAuth> for HttpAuth {
    fn from(value: ExHttpAuth) -> Self {
        match value {
            ExHttpAuth::User(ExUserAuth { username, password }) => {
                HttpAuth::User(username, password)
            }
            ExHttpAuth::Token(ExTokenAuth { value }) => HttpAuth::Token(value),
            ExHttpAuth::None => HttpAuth::None,
        }
    }
}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.Link"]
pub struct ExLink {
    pub name: String,
    pub href: Option<String>,
    pub templated: bool,
    pub title: Option<String>,
}

impl From<ExLink> for Link {
    fn from(value: ExLink) -> Self {
        Self {
            name: value.name,
            href: value.href,
            templated: value.templated,
            title: value.title,
        }
    }
}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.ConsumerVersionSelector"]
pub struct ExConsumerVersionSelector {
    pub consumer: Option<String>,
    pub tag: Option<String>,
    pub fallback_tag: Option<String>,
    pub latest: Option<bool>,
    pub deployed_or_released: Option<bool>,
    pub deployed: Option<bool>,
    pub released: Option<bool>,
    pub environment: Option<String>,
    pub main_branch: Option<bool>,
    pub branch: Option<String>,
    pub matching_branch: Option<bool>,
    pub fallback_branch: Option<String>,
}

impl From<ExConsumerVersionSelector> for ConsumerVersionSelector {
    fn from(value: ExConsumerVersionSelector) -> Self {
        Self {
            consumer: value.consumer,
            tag: value.tag,
            fallback_tag: value.fallback_tag,
            latest: value.latest,
            deployed_or_released: value.deployed_or_released,
            deployed: value.deployed,
            released: value.released,
            environment: value.environment,
            main_branch: value.main_branch,
            branch: value.branch,
            matching_branch: value.matching_branch,
            fallback_branch: value.fallback_branch,
        }
    }
}

#[derive(NifTaggedEnum)]
pub enum ExPactSource {
    Unknown,
    File(String),
    Dir(String),
    Url(String, Option<ExHttpAuth>),
    BrokerUrl(String, String, Option<ExHttpAuth>, Vec<ExLink>),
    BrokerWithDynamicConfiguration {
        provider_name: String,
        broker_url: String,
        enable_pending: bool,
        include_wip_pacts_since: Option<String>,
        provider_tags: Vec<String>,
        provider_branch: Option<String>,
        selectors: Vec<ExConsumerVersionSelector>,
        auth: Option<ExHttpAuth>,
        links: Vec<ExLink>,
    },
    String(String),
    WebhookCallbackUrl {
        pact_url: String,
        broker_url: String,
        auth: Option<ExHttpAuth>,
    },
}

impl From<ExPactSource> for PactSource {
    fn from(value: ExPactSource) -> Self {
        match value {
            ExPactSource::Unknown => PactSource::Unknown,
            ExPactSource::File(s) => PactSource::File(s),
            ExPactSource::Dir(s) => PactSource::Dir(s),
            ExPactSource::Url(url, auth) => PactSource::URL(url, auth.map(Into::into)),
            ExPactSource::BrokerUrl(url, provider, auth, links) => PactSource::BrokerUrl(
                url,
                provider,
                auth.map(Into::into),
                links.into_iter().map(Into::into).collect(),
            ),
            ExPactSource::BrokerWithDynamicConfiguration {
                provider_name,
                broker_url,
                enable_pending,
                include_wip_pacts_since,
                provider_tags,
                provider_branch,
                selectors,
                auth,
                links,
            } => PactSource::BrokerWithDynamicConfiguration {
                provider_name,
                broker_url,
                enable_pending,
                include_wip_pacts_since,
                provider_tags,
                provider_branch,
                selectors: selectors.into_iter().map(Into::into).collect(),
                auth: auth.map(Into::into),
                links: links.into_iter().map(Into::into).collect(),
            },
            ExPactSource::String(s) => PactSource::String(s),
            ExPactSource::WebhookCallbackUrl {
                pact_url,
                broker_url,
                auth,
            } => PactSource::WebhookCallbackUrl {
                pact_url,
                broker_url,
                auth: auth.map(Into::into),
            },
        }
    }
}

#[allow(clippy::enum_variant_names)]
#[derive(NifTaggedEnum)]
pub enum ExFilterById {
    InteractionId(String),
    InteractionKey(String),
    InteractionDesc(String),
}

impl From<ExFilterById> for FilterById {
    fn from(value: ExFilterById) -> Self {
        match value {
            ExFilterById::InteractionId(id) => FilterById::InteractionId(id),
            ExFilterById::InteractionKey(key) => FilterById::InteractionKey(key),
            ExFilterById::InteractionDesc(desc) => FilterById::InteractionDesc(desc),
        }
    }
}

#[derive(NifTaggedEnum)]
pub enum ExFilterInfo {
    None,
    Description(String),
    State(String),
    DescriptionAndState(String, String),
    InteractionIds(Vec<ExFilterById>),
}

impl From<ExFilterInfo> for FilterInfo {
    fn from(value: ExFilterInfo) -> Self {
        match value {
            ExFilterInfo::None => FilterInfo::None,
            ExFilterInfo::Description(description) => FilterInfo::Description(description),
            ExFilterInfo::State(state) => FilterInfo::State(state),
            ExFilterInfo::DescriptionAndState(description, state) => {
                FilterInfo::DescriptionAndState(description, state)
            }
            ExFilterInfo::InteractionIds(ex_filter_by_ids) => {
                FilterInfo::InteractionIds(ex_filter_by_ids.into_iter().map(Into::into).collect())
            }
        }
    }
}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.PublishOptions"]
pub struct ExPublishOptions {
    pub provider_version: Option<String>,
    pub build_url: Option<String>,
    pub provider_tags: Vec<String>,
    pub provider_branch: Option<String>,
}

impl From<ExPublishOptions> for PublishOptions {
    fn from(value: ExPublishOptions) -> Self {
        Self {
            provider_version: value.provider_version,
            build_url: value.build_url,
            provider_tags: value.provider_tags,
            provider_branch: value.provider_branch,
        }
    }
}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.VerificationMetrics"]
pub struct ExVerificationMetrics {
    pub test_framework: String,
    pub app_name: String,
    pub app_version: String,
}

impl From<ExVerificationMetrics> for VerificationMetrics {
    fn from(value: ExVerificationMetrics) -> Self {
        Self {
            test_framework: value.test_framework,
            app_name: value.app_name,
            app_version: value.app_version,
        }
    }
}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.HttpRequest"]
pub struct ExHttpRequest {
    pub method: String,
    pub path: String,
    pub query: Option<HashMap<String, Vec<Option<String>>>>,
    pub headers: Option<HashMap<String, Vec<String>>>,
    // TODO: implement following fields
    //    pub body: OptionalBody,
    //    pub matching_rules: MatchingRules,
    //    pub generators: Generators,
}

impl From<HttpRequest> for ExHttpRequest {
    fn from(value: HttpRequest) -> Self {
        Self {
            method: value.method,
            path: value.path,
            query: value.query,
            headers: value.headers,
        }
    }
}

impl From<ExHttpRequest> for HttpRequest {
    fn from(value: ExHttpRequest) -> Self {
        Self {
            method: value.method,
            path: value.path,
            query: value.query,
            headers: value.headers,
            body: OptionalBody::Empty,
            // TODO: implment the following field
            matching_rules: MatchingRules {
                rules: HashMap::new(),
            },
            generators: Generators::default(),
        }
    }
}

// TODO
//#[derive(NifStruct)]
//#[module = "Pact.PactVerifier.RequestFilter"]
//pub struct ExRequestFilter {
//    pid: LocalPid,
//}
//
//impl Debug for ExRequestFilter {
//    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
//        f.debug_struct("ExRequestFilter").finish()
//    }
//}
//
//impl RequestFilterExecutor for ExRequestFilter {
//    fn call(
//        self: std::sync::Arc<Self>,
//        request: &pact_models::v4::http_parts::HttpRequest,
//    ) -> pact_models::v4::http_parts::HttpRequest {
//        let (_tx, rx) = mpsc::channel::<ExHttpRequest>();
//        let mut msg_env = OwnedEnv::new();
//        let _ = msg_env.send_and_clear(&self.pid, |env| {
//            (
//                rustler::Atom::from_str(env, "request").unwrap(),
//                env.make_ref(),
//                Into::<ExHttpRequest>::into(request.clone()),
//            )
//        });
//
//        match rx.recv() {
//            Ok(filtered_request) => Into::<HttpRequest>::into(filtered_request),
//            Err(_) => request.clone(), // fallback
//        }
//    }
//
//    fn call_non_http(
//        &self,
//        request_body: &pact_models::prelude::OptionalBody,
//        metadata: &HashMap<String, Either<serde_json::Value, Bytes>>,
//    ) -> (
//        pact_models::prelude::OptionalBody,
//        HashMap<String, Either<serde_json::Value, Bytes>>,
//    ) {
//        todo!()
//    }
//}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.VerificationOptions"]
pub struct ExVerificationOptions {
    //pub request_filter: Option<ExRequestFilter>,
    pub disable_ssl_verification: bool,
    pub request_timeout: u64,
    pub custom_headers: HashMap<String, String>,
    pub coloured_output: bool,
    pub no_pacts_is_error: bool,
    pub exit_on_first_failure: bool,
    pub run_last_failed_only: bool,
}

impl From<ExVerificationOptions> for VerificationOptions<NullRequestFilterExecutor> {
    fn from(value: ExVerificationOptions) -> Self {
        Self {
            request_filter: None,
            disable_ssl_verification: value.disable_ssl_verification,
            request_timeout: value.request_timeout,
            custom_headers: value.custom_headers,
            coloured_output: value.coloured_output,
            no_pacts_is_error: value.no_pacts_is_error,
            exit_on_first_failure: value.exit_on_first_failure,
            run_last_failed_only: value.run_last_failed_only,
        }
    }
}

#[derive(NifStruct)]
#[module = "Pact.PactVerifier.HttpRequestProviderStateExecutor"]
pub struct ExHttpRequestProviderStateExecutor {
    pub state_change_url: Option<String>,
    pub state_change_teardown: bool,
    pub state_change_body: bool,
    pub reties: u8,
}

impl From<ExHttpRequestProviderStateExecutor> for HttpRequestProviderStateExecutor {
    fn from(value: ExHttpRequestProviderStateExecutor) -> Self {
        Self {
            state_change_url: value.state_change_url,
            state_change_teardown: value.state_change_teardown,
            state_change_body: value.state_change_body,
            reties: value.reties,
        }
    }
}

#[allow(clippy::too_many_arguments)]
#[rustler::nif(name = "verify_provider", schedule = "DirtyIo")]
pub fn verify_provider(
    provider_info: ExProviderInfo,
    source: Vec<ExPactSource>,
    filter: ExFilterInfo,
    consumers: Vec<String>,
    verification_options: ExVerificationOptions,
    publish_options: Option<ExPublishOptions>,
    provider_state_executor: ExHttpRequestProviderStateExecutor,
    metrics_data: Option<ExVerificationMetrics>,
) -> NifResult<bool> {
    pact_verifier::verify_provider(
        provider_info.into(),
        source.into_iter().map(Into::into).collect(),
        filter.into(),
        consumers,
        &verification_options.into(),
        publish_options.map(Into::into).as_ref(),
        &Arc::new(Into::<HttpRequestProviderStateExecutor>::into(
            provider_state_executor,
        )),
        metrics_data.map(Into::into),
    )
    .map_err(|e| {
        rustler::Error::RaiseTerm(Box::new((
            "invalid_interaction_builder_reference",
            format!("{e:?}"),
        )))
    })
}
