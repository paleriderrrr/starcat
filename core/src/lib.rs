mod components;
mod systems;
mod world;

pub use components::*;
pub use systems::*;
pub use world::*;

use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn create_world_state() -> JsValue {
    serde_wasm_bindgen::to_value(&WorldState::sample()).unwrap_or(JsValue::NULL)
}

#[wasm_bindgen]
pub fn process_world_turn(input: JsValue) -> JsValue {
    let mut world: WorldState = serde_wasm_bindgen::from_value(input).unwrap_or_else(|_| WorldState::sample());
    world.process_turn();
    serde_wasm_bindgen::to_value(&world).unwrap_or(JsValue::NULL)
}
