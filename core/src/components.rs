use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceBundle {
    pub food: f64,
    pub minerals: f64,
    pub industry: f64,
    pub energy: f64,
}

impl ResourceBundle {
    pub fn new(food: f64, minerals: f64, industry: f64, energy: f64) -> Self {
        Self { food, minerals, industry, energy }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Personality {
    pub aggression: f64,
    pub paranoia: f64,
    pub greed: f64,
    pub loyalty: f64,
    pub rationality: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Faction {
    pub id: u32,
    pub name: String,
    pub leader_name: String,
    pub personality: Personality,
    pub resources: ResourceBundle,
    pub military_power: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StarSystem {
    pub id: u32,
    pub name: String,
    pub owner_id: Option<u32>,
    pub food: f64,
    pub minerals: f64,
    pub industry: f64,
    pub energy: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Fleet {
    pub id: u32,
    pub owner_id: u32,
    pub current_system_id: u32,
    pub power: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Relationship {
    pub faction_a_id: u32,
    pub faction_b_id: u32,
    pub trust: f64,
    pub utility: f64,
    pub fear: f64,
    pub affinity: f64,
}
