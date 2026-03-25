use dspatch_router::wire::*;
use serde_json::json;

#[test]
fn serialize_auth_package() {
    let pkg = WirePackage::auth("test-key");
    let j = pkg.to_json();
    assert_eq!(j["type"], "connection.auth");
    assert_eq!(j["api_key"], "test-key");
}

#[test]
fn serialize_register_package() {
    let pkg = WirePackage::register("router", "container_router");
    let j = pkg.to_json();
    assert_eq!(j["type"], "connection.register");
    assert_eq!(j["name"], "router");
    assert_eq!(j["role"], "container_router");
}

#[test]
fn serialize_heartbeat() {
    let instances = vec![
        HeartbeatInstance { instance_id: "lead-0".into(), state: "idle".into() },
    ];
    let pkg = WirePackage::heartbeat(instances);
    let j = pkg.to_json();
    assert_eq!(j["type"], "connection.heartbeat");
    assert_eq!(j["instances"][0]["instance_id"], "lead-0");
}

#[test]
fn parse_inbound_user_input() {
    let raw = json!({
        "type": "agent.event.user_input",
        "instance_id": "lead-0",
        "text": "hello",
    });
    let pkg = WirePackage::from_json(raw).unwrap();
    assert_eq!(pkg.package_type(), "agent.event.user_input");
    assert_eq!(pkg.instance_id(), Some("lead-0"));
}

#[test]
fn parse_inbound_spawn_instance() {
    let raw = json!({
        "type": "connection.spawn_instance",
        "agent_key": "coder",
        "instance_id": "coder-0",
    });
    let pkg = WirePackage::from_json(raw).unwrap();
    assert_eq!(pkg.package_type(), "connection.spawn_instance");
}

#[test]
fn output_package_roundtrip() {
    let raw = json!({
        "type": "agent.output.message",
        "instance_id": "lead-0",
        "id": "msg-1",
        "role": "assistant",
        "content": "Hello",
        "is_delta": false,
        "turn_id": "t1",
        "ts": 1234567890
    });
    let pkg = WirePackage::from_json(raw.clone()).unwrap();
    let reserialized = pkg.to_json();
    assert_eq!(reserialized["type"], raw["type"]);
    assert_eq!(reserialized["instance_id"], raw["instance_id"]);
}
