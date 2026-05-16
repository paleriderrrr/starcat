extends SceneTree

const InitialDataScript = preload("res://scripts/data/InitialData.gd")
const GameLogicScript = preload("res://scripts/GameLogic.gd")
const DecisionIterationServiceScript = preload("res://scripts/services/DecisionIterationService.gd")

var _errors: Array[String] = []


func _initialize() -> void:
	var configured_options: Dictionary = {
		"player_template_id": "blue_command",
		"map_scale": "GRAND",
		"difficulty": "STANDARD",
		"opponent_count": 4
	}
	var state: Dictionary = InitialDataScript.create_initial_state(configured_options)
	_expect(str(state.get("status", "")) == "PLAYING", "initial state is playable")
	_expect(state.get("starSystems", []).size() >= 26, "grand setup creates doubled expanded map")
	_expect(state.get("hyperlanes", []).size() >= 32, "grand setup creates doubled route network")
	_expect(state.get("factions", []).size() >= 5, "grand setup creates multiple AI opponents")
	_expect(not GameLogicScript.player_faction(state).is_empty(), "player faction exists")
	_expect(not _fleet_by_id(state, "fleet_player_1").is_empty(), "player fleet exists")

	var iteration_service = DecisionIterationServiceScript.new()
	var snapshot_before: Dictionary = iteration_service.build_turn_snapshot(state, "f_player", "smoke")
	_expect(str(snapshot_before.get("kind", "")) == "TurnSnapshot", "turn snapshot kind")
	_expect(snapshot_before.get("features23", {}).size() == 23, "turn snapshot has 23 features")
	_expect(bool(iteration_service.validate_record(snapshot_before).get("ok", false)), "turn snapshot validates")

	state = GameLogicScript.explore_system(state, "fleet_player_1", "sys_polaris")
	var scouted_polaris: Dictionary = _system_by_id(state, "sys_polaris")
	_expect(str(scouted_polaris.get("visibilityLevel", "")) == "PARTIAL", "adjacent exploration only scouts")
	_expect(not bool(scouted_polaris.get("eventResolved", false)), "adjacent exploration does not resolve event")

	state = GameLogicScript.move_fleet(state, "fleet_player_1", "sys_polaris")
	var moved_fleet: Dictionary = _fleet_by_id(state, "fleet_player_1")
	var arrived_polaris: Dictionary = _system_by_id(state, "sys_polaris")
	_expect(str(moved_fleet.get("systemId", "")) == "sys_polaris", "fleet moves to target")
	_expect(str(arrived_polaris.get("visibilityLevel", "")) == "FULL", "arrival grants full visibility")
	_expect(bool(arrived_polaris.get("eventResolved", false)), "arrival resolves system event")

	state = GameLogicScript.start_research(state, "tech_deep_colonization")
	_expect(str(state.get("currentResearchId", "")) == "tech_deep_colonization", "research can start")
	for _i: int in range(2):
		state = GameLogicScript.process_turn(state)
	_expect(GameLogicScript.has_research(state, "tech_deep_colonization"), "deep colonization research completes")
	_expect(str(state.get("status", "")) == "PLAYING", "state remains playable after turn processing")
	_expect(state.get("aiActionLog", []).size() > 0, "configured AI emits action records")

	state = _prepare_colonization_target(state, "sys_polaris")
	var colony_preview: Dictionary = GameLogicScript.colonization_preview(state, "fleet_player_1", "sys_polaris", "STANDARD")
	_expect(bool(colony_preview.get("allowed", false)), "colonization preview allows target: %s resources=%s fleet=%s system=%s" % [
		str(colony_preview.get("reason", "")),
		str(GameLogicScript.player_faction(state).get("resources", {})),
		str(_fleet_by_id(state, "fleet_player_1")),
		str(_system_by_id(state, "sys_polaris")),
	])
	state = GameLogicScript.colonize_system(state, "fleet_player_1", "sys_polaris", "STANDARD")
	var colony_system: Dictionary = _system_by_id(state, "sys_polaris")
	_expect(str(colony_system.get("ownerId", "")) == "f_player", "colony target owned by player")
	_expect(str(colony_system.get("colonyStage", "")) != "NONE", "colony process started")

	var snapshot_after: Dictionary = iteration_service.build_turn_snapshot(state, "f_player", "smoke")
	var decision_record: Dictionary = iteration_service.build_decision_record(
		snapshot_before,
		{"action": "SMOKE_TEST", "target": "sys_polaris", "rationale": "Validate the playable loop."},
		{"source": "runtime_smoke", "tokens": {"input": 0, "output": 0}},
		"smoke_playbook",
		["explore_system", "move_fleet", "start_research", "process_turn", "colonize_system"]
	)
	var evaluation: Dictionary = iteration_service.evaluate_transition(snapshot_before, snapshot_after)
	var trial: Dictionary = iteration_service.build_trial_record("smoke", [snapshot_before, snapshot_after], [decision_record], [evaluation], {"seed": "initial", "map": "default", "civs": ["f_player", "f_merchant", "f_orchid"]})
	_expect(bool(iteration_service.validate_record(decision_record).get("ok", false)), "decision record validates")
	_expect(bool(iteration_service.validate_record(evaluation).get("ok", false)), "evaluation record validates")
	_expect(bool(iteration_service.validate_record(trial).get("ok", false)), "trial record validates")

	var victory_report: Dictionary = GameLogicScript.player_victory_progress_report(state)
	_expect(victory_report.has("military") and victory_report.has("diplomatic") and victory_report.has("science"), "victory report covers all paths")

	if _errors.is_empty():
		print("STARCAT_RUNTIME_SMOKE_OK turns=%s systems=%s messages=%s vp=%s" % [
			str(state.get("turn", 0)),
			str(state.get("starSystems", []).size()),
			str(state.get("messages", []).size()),
			str(snapshot_after.get("vp_t", {}).get("best", 0.0)),
		])
		quit(0)
	else:
		for error: String in _errors:
			push_error(error)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _fleet_by_id(state: Dictionary, fleet_id: String) -> Dictionary:
	for fleet: Dictionary in state.get("fleets", []):
		if str(fleet.get("id", "")) == fleet_id:
			return fleet
	return {}


func _system_by_id(state: Dictionary, system_id: String) -> Dictionary:
	for system: Dictionary in state.get("starSystems", []):
		if str(system.get("id", "")) == system_id:
			return system
	return {}


func _clear_hostile_fleets_from_system(state: Dictionary, system_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var player_id: String = str(GameLogicScript.player_faction(next_state).get("id", ""))
	var retained_fleets: Array = []
	for fleet: Dictionary in next_state.get("fleets", []):
		if str(fleet.get("systemId", "")) == system_id and str(fleet.get("ownerId", "")) != player_id:
			continue
		retained_fleets.append(fleet)
	next_state["fleets"] = retained_fleets
	return next_state


func _prepare_colonization_target(state: Dictionary, system_id: String) -> Dictionary:
	var next_state: Dictionary = _clear_hostile_fleets_from_system(state, system_id)
	var systems: Array = next_state.get("starSystems", [])
	for index: int in range(systems.size()):
		var system: Dictionary = systems[index]
		if str(system.get("id", "")) != system_id:
			continue
		system["ownerId"] = null
		system["population"] = 0
		system["colonyStage"] = "NONE"
		system["colonizationProgress"] = 0.0
		system["colonizationTurnsRemaining"] = 0
		system["colonizationMode"] = ""
		system["buildings"] = []
		systems[index] = system
		break
	next_state["starSystems"] = systems
	return next_state
