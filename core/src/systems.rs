use crate::components::{Faction, Relationship};

pub fn update_economy(faction: &mut Faction, food: f64, minerals: f64, industry: f64, energy: f64) {
    faction.resources.food += food;
    faction.resources.minerals += minerals;
    faction.resources.industry += industry;
    faction.resources.energy += energy;
}

pub fn war_utility(
    aggression: f64,
    paranoia: f64,
    greed: f64,
    rationality: f64,
    expected_gain: f64,
    war_cost: f64,
    enemy_power: f64,
    territory_value: f64,
) -> f64 {
    expected_gain * aggression / 10.0
        - war_cost * rationality / 10.0
        - enemy_power * (1.0 + paranoia / 10.0)
        + territory_value * greed / 10.0
}

pub fn apply_trade_event(relationship: &mut Relationship, value: f64) {
    relationship.trust = (relationship.trust + value * 0.5).clamp(-100.0, 100.0);
    relationship.utility = (relationship.utility + value * 0.3).clamp(-100.0, 100.0);
    relationship.affinity = (relationship.affinity + value * 0.2).clamp(-100.0, 100.0);
}
