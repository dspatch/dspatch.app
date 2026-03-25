use dspatch_router::ws_client::ExponentialBackoff;

#[test]
fn exponential_backoff_progression() {
    let mut backoff = ExponentialBackoff::new(
        std::time::Duration::from_secs(1),
        std::time::Duration::from_secs(30),
    );
    let d1 = backoff.next_delay();
    assert_eq!(d1, std::time::Duration::from_secs(1));

    let d2 = backoff.next_delay();
    assert_eq!(d2, std::time::Duration::from_secs(2));

    let d3 = backoff.next_delay();
    assert_eq!(d3, std::time::Duration::from_secs(4));

    for _ in 0..10 {
        backoff.next_delay();
    }
    let d_capped = backoff.next_delay();
    assert!(d_capped <= std::time::Duration::from_secs(30));
}

#[test]
fn backoff_reset() {
    let mut backoff = ExponentialBackoff::new(
        std::time::Duration::from_secs(2),
        std::time::Duration::from_secs(60),
    );
    backoff.next_delay();
    backoff.next_delay();
    backoff.reset();
    assert_eq!(backoff.next_delay(), std::time::Duration::from_secs(2));
}
