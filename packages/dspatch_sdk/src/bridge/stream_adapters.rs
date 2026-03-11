// Copyright (c) 2026 Osman Alperen Çinar-Koraş (oakisnotree). Licensed under AGPL-3.0.

//! Stream forwarding helpers for bridging SDK watch streams to FRB.
//!
//! [`forward_stream`] spawns a tokio task that drains a domain watch stream
//! into an FRB `StreamSink`, running until the sink is closed or the stream
//! is exhausted.

use futures::Stream;
use futures::StreamExt;
use std::pin::Pin;
use std::sync::Arc;
use tokio::runtime::Runtime;

use crate::frb_generated::{SseEncode, StreamSink};

/// A boxed, pinned, Send stream — the shape our domain services return.
pub type DomainStream<T> = Pin<Box<dyn Stream<Item = T> + Send>>;

/// Forward items from a domain watch stream into an FRB StreamSink.
///
/// Spawns a tokio task on the provided runtime that reads from `stream` and
/// pushes each item into `sink`. The task exits when the stream is exhausted
/// or `sink.add()` returns an error (i.e., the Dart side closed the sink).
pub fn forward_stream<T: Send + SseEncode + 'static>(
    rt: &Arc<Runtime>,
    stream: DomainStream<T>,
    sink: StreamSink<T>,
) {
    rt.spawn(async move {
        tokio::pin!(stream);
        while let Some(item) = stream.next().await {
            if sink.add(item).is_err() {
                break;
            }
        }
    });
}
