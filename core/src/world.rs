use serde::{Deserialize, Serialize};

use crate::components::{Faction, Fleet, Personality, Relationship, ResourceBundle, StarSystem};
use crate::systems::update_economy;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorldState {
    pub turn: u32,
    pub factions: Vec<Faction>,
    pub star_systems: Vec<StarSystem>,
    pub fleets: Vec<Fleet>,
    pub relationships: Vec<Relationship>,
}

impl WorldState {
    pub fn sample() -> Self {
        Self {
            turn: 1,
            factions: vec![Faction {
                id: 1,
                name: "喵星文明".to_string(),
                leader_name: "喵因斯坦".to_string(),
                personality: Personality {
                    aggression: 4.0,
                    paranoia: 5.0,
                    greed: 5.0,
                    loyalty: 6.0,
                    rationality: 9.0,
                },
                resources: ResourceBundle::new(500.0, 420.0, 360.0, 380.0),
                military_power: 90.0,
            }],
            star_systems: vec![StarSystem {
                id: 1,
                name: "喵星".to_string(),
                owner_id: Some(1),
                food: 6.0,
                minerals: 4.0,
                industry: 4.0,
                energy: 4.0,
            }],
            fleets: vec![Fleet {
                id: 1,
                owner_id: 1,
                current_system_id: 1,
                power: 40.0,
            }],
            relationships: vec![],
        }
    }

    pub fn process_turn(&mut self) {
        self.turn += 1;
        for faction in &mut self.factions {
            update_economy(faction, 5.0, 3.0, 2.0, 2.0);
        }
    }
}
