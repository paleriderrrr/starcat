extends RefCounted
class_name DecisionIterationService

const GameLogicScript = preload("res://scripts/GameLogic.gd")

const SCHEMA_VERSION := "0.1"
const DEFAULT_GAME_ID := "starcat_local"
const DEFAULT_JSONL_PATH := "user://decision_iterations/records.jsonl"
const ARTIFACT_TURN_SNAPSHOT := "TurnSnapshot"
const ARTIFACT_DECISION_RECORD := "DecisionRecord"
const ARTIFACT_TRIAL_RECORD := "TrialRecord"
const ARTIFACT_EVALUATION_RECORD := "EvaluationRecord"
const ARTIFACT_PATCH_RECORD := "PatchRecord"
const ARTIFACT_TEST_CASE := "TestCase"


func build_turn_snapshot(game_state: Dictionary, perspective_faction_id: String = "f_player", game_id: String = DEFAULT_GAME_ID) -> Dictionary:
	var faction: Dictionary = GameLogicScript.get_faction_by_id(game_state, perspective_faction_id)
	if faction.is_empty() and perspective_faction_id == "f_player":
		faction = GameLogicScript.player_faction(game_state)
	var victory_report: Dictionary = GameLogicScript.player_victory_progress_report(game_state)
	var posture_report: Dictionary = GameLogicScript.strategic_posture_report(game_state, perspective_faction_id)
	var visible_state: Dictionary = _visible_state(game_state, perspective_faction_id)
	var features: Dictionary = _features23(game_state, perspective_faction_id, victory_report, posture_report, visible_state)
	return {
		"schema_version": SCHEMA_VERSION,
		"kind": ARTIFACT_TURN_SNAPSHOT,
		"game_id": game_id,
		"turn": int(game_state.get("turn", 1)),
		"civ": str(faction.get("name", perspective_faction_id)),
		"perspective_faction_id": perspective_faction_id,
		"status": str(game_state.get("status", "IN_PROGRESS")),
		"era": str(game_state.get("era", "ANCIENT")),
		"visible_state": visible_state,
		"features23": features,
		"vp_t": _vp_t(victory_report),
	}


func build_decision_record(snapshot: Dictionary, decision: Dictionary, provider_payload: Dictionary = {}, playbook_id: String = "strategist_v0", tools_called: Array = []) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"kind": ARTIFACT_DECISION_RECORD,
		"game_id": str(snapshot.get("game_id", DEFAULT_GAME_ID)),
		"turn": int(snapshot.get("turn", 1)),
		"decision_id": "d_%s_%s" % [str(snapshot.get("turn", 1)), str(decision.get("action", "WAIT"))],
		"source": str(provider_payload.get("source", "local")),
		"action": str(decision.get("action", "WAIT")),
		"target": decision.get("target", decision.get("target_system_id", "")),
		"rationale": str(decision.get("rationale", decision.get("reason", ""))),
		"playbook_id": playbook_id,
		"tools_called": tools_called.duplicate(true),
		"tokens": provider_payload.get("tokens", {}),
		"fallback": bool(decision.get("fallback", false)),
		"snapshot_digest": _snapshot_digest(snapshot),
	}


func evaluate_transition(before_snapshot: Dictionary, after_snapshot: Dictionary) -> Dictionary:
	var before_vp: Dictionary = before_snapshot.get("vp_t", {})
	var after_vp: Dictionary = after_snapshot.get("vp_t", {})
	var before_features: Dictionary = before_snapshot.get("features23", {})
	var after_features: Dictionary = after_snapshot.get("features23", {})
	return {
		"schema_version": SCHEMA_VERSION,
		"kind": ARTIFACT_EVALUATION_RECORD,
		"game_id": str(after_snapshot.get("game_id", before_snapshot.get("game_id", DEFAULT_GAME_ID))),
		"turn": int(after_snapshot.get("turn", before_snapshot.get("turn", 1))),
		"vp_delta": float(after_vp.get("best", 0.0)) - float(before_vp.get("best", 0.0)),
		"resource_delta": _resource_delta(before_features, after_features),
		"military_delta": float(after_features.get("fleet_power", 0.0)) - float(before_features.get("fleet_power", 0.0)),
		"science_progress_delta": float(after_vp.get("science", 0.0)) - float(before_vp.get("science", 0.0)),
		"status_before": str(before_snapshot.get("status", "IN_PROGRESS")),
		"status_after": str(after_snapshot.get("status", "IN_PROGRESS")),
		"risk_flags": _risk_flags(before_snapshot, after_snapshot),
	}


func build_trial_record(game_id: String, snapshots: Array, decisions: Array, evaluations: Array, metadata: Dictionary = {}) -> Dictionary:
	var turns: int = snapshots.size()
	if not snapshots.is_empty():
		turns = int(snapshots.back().get("turn", turns)) - int(snapshots.front().get("turn", 1)) + 1
	return {
		"schema_version": SCHEMA_VERSION,
		"kind": ARTIFACT_TRIAL_RECORD,
		"game_id": game_id,
		"seed": metadata.get("seed", ""),
		"map": metadata.get("map", "starcat_default"),
		"civs": metadata.get("civs", []),
		"turns": max(turns, 0),
		"VP_AUC": _vp_auc(snapshots),
		"cost": metadata.get("cost", {}),
		"time": metadata.get("time", {}),
		"code_sha": str(metadata.get("code_sha", "")),
		"decision_count": decisions.size(),
		"evaluation_count": evaluations.size(),
	}


func build_patch_record(parent_sha: String, diff: String, root_cause: String, tests_added: Array, metadata: Dictionary = {}) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"kind": ARTIFACT_PATCH_RECORD,
		"parent_sha": parent_sha,
		"diff": diff,
		"root_cause": root_cause,
		"tests_added": tests_added.duplicate(true),
		"author": str(metadata.get("author", "coding_agent")),
		"created_at": str(metadata.get("created_at", "")),
		"accepted": bool(metadata.get("accepted", false)),
		"regression_status": str(metadata.get("regression_status", "PENDING")),
	}


func build_test_case(test_id: String, savegame: String, assertions: Array, metadata: Dictionary = {}) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"kind": ARTIFACT_TEST_CASE,
		"id": test_id,
		"savegame": savegame,
		"assertions": assertions.duplicate(true),
		"source_trial": str(metadata.get("source_trial", "")),
		"source_turn": int(metadata.get("source_turn", 0)),
		"failure_label": str(metadata.get("failure_label", "")),
	}


func validate_record(record: Dictionary) -> Dictionary:
	var kind: String = str(record.get("kind", ""))
	var required_fields: Array = _required_fields_for_kind(kind)
	var missing: Array = []
	for field: String in required_fields:
		if not record.has(field):
			missing.append(field)
	return {
		"ok": kind != "" and missing.is_empty(),
		"kind": kind,
		"missing": missing,
		"schema_version": str(record.get("schema_version", "")),
	}


func build_artifact_bundle(records: Array, metadata: Dictionary = {}) -> Dictionary:
	var valid_records: Array = []
	var invalid_records: Array = []
	for record: Dictionary in records:
		var validation: Dictionary = validate_record(record)
		if bool(validation.get("ok", false)):
			valid_records.append(record)
		else:
			invalid_records.append({
				"record": record,
				"validation": validation,
			})
	return {
		"schema_version": SCHEMA_VERSION,
		"kind": "ArtifactBundle",
		"records": valid_records,
		"invalid_records": invalid_records,
		"record_count": records.size(),
		"valid_count": valid_records.size(),
		"invalid_count": invalid_records.size(),
		"metadata": metadata.duplicate(true),
	}


func jsonl_line(record: Dictionary) -> String:
	return JSON.stringify(record)


func append_jsonl(record: Dictionary, path: String = DEFAULT_JSONL_PATH) -> Dictionary:
	var validation: Dictionary = validate_record(record)
	if not bool(validation.get("ok", false)):
		return {
			"ok": false,
			"path": path,
			"error": "invalid_record",
			"validation": validation,
	}
	_ensure_parent_dir(path)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"path": path,
			"error": "open_failed",
		}
	file.seek_end()
	file.store_line(jsonl_line(record))
	file.close()
	return {
		"ok": true,
		"path": path,
		"kind": str(record.get("kind", "")),
	}


func append_jsonl_records(records: Array, path: String = DEFAULT_JSONL_PATH) -> Dictionary:
	var written := 0
	var errors: Array = []
	for record: Dictionary in records:
		var result: Dictionary = append_jsonl(record, path)
		if bool(result.get("ok", false)):
			written += 1
		else:
			errors.append(result)
	return {
		"ok": errors.is_empty(),
		"path": path,
		"written": written,
		"errors": errors,
	}


func schema_catalog() -> Dictionary:
	return {
		ARTIFACT_TURN_SNAPSHOT: ["game_id", "turn", "civ", "visible_state", "features23", "vp_t"],
		ARTIFACT_DECISION_RECORD: ["turn", "tools_called", "playbook_id", "rationale", "tokens"],
		ARTIFACT_EVALUATION_RECORD: ["game_id", "turn", "vp_delta", "resource_delta", "risk_flags"],
		ARTIFACT_PATCH_RECORD: ["parent_sha", "diff", "root_cause", "tests_added"],
		ARTIFACT_TRIAL_RECORD: ["seed", "map", "civs", "turns", "VP_AUC", "cost", "time", "code_sha"],
		ARTIFACT_TEST_CASE: ["id", "savegame", "assertions"],
	}


func _required_fields_for_kind(kind: String) -> Array:
	return schema_catalog().get(kind, [])


func _visible_state(game_state: Dictionary, faction_id: String) -> Dictionary:
	var faction: Dictionary = GameLogicScript.get_faction_by_id(game_state, faction_id)
	var resources: Dictionary = faction.get("resources", {})
	return {
		"systems": _visible_systems(game_state, faction_id),
		"fleets": _visible_fleets(game_state, faction_id),
		"resources": resources,
		"active_treaties": GameLogicScript.active_treaties_for_faction(game_state, faction_id),
		"pending_proposals": game_state.get("pendingProposals", []),
		"recent_intelligence_feed": GameLogicScript.recent_intelligence_feed(game_state, 8),
	}


func _ensure_parent_dir(path: String) -> void:
	var slash_index: int = path.rfind("/")
	if slash_index <= 0:
		return
	var parent_path: String = path.substr(0, slash_index)
	if parent_path == "user:" or parent_path == "res:":
		return
	DirAccess.make_dir_recursive_absolute(parent_path)


func _visible_systems(game_state: Dictionary, faction_id: String) -> Array:
	var rows: Array = []
	for system: Dictionary in game_state.get("starSystems", []):
		var owner_id: String = str(system.get("ownerId", ""))
		var exploration: Dictionary = system.get("explorationByFaction", {})
		var visibility: String = str(system.get("visibilityLevel", "HIDDEN"))
		if owner_id == faction_id or visibility != "HIDDEN" or str(exploration.get(faction_id, "")) != "":
			rows.append({
				"id": str(system.get("id", "")),
				"name": str(system.get("name", "")),
				"owner_id": owner_id,
				"exploration": str(exploration.get(faction_id, visibility)),
				"resources": system.get("resources", {}),
			})
	return rows


func _visible_fleets(game_state: Dictionary, faction_id: String) -> Array:
	var rows: Array = []
	for fleet: Dictionary in game_state.get("fleets", []):
		if str(fleet.get("ownerId", "")) != faction_id:
			continue
		rows.append({
			"id": str(fleet.get("id", "")),
			"name": str(fleet.get("name", "")),
			"system_id": str(fleet.get("systemId", "")),
			"power": float(fleet.get("power", GameLogicScript.fleet_power(fleet))),
			"ship_count": fleet.get("ships", []).size(),
			"task": str(fleet.get("task", "IDLE")),
		})
	return rows


func _features23(game_state: Dictionary, faction_id: String, victory_report: Dictionary, posture_report: Dictionary, visible_state: Dictionary) -> Dictionary:
	var faction: Dictionary = GameLogicScript.get_faction_by_id(game_state, faction_id)
	var resources: Dictionary = faction.get("resources", {})
	var income: Dictionary = faction.get("income", {})
	var owned_systems: int = 0
	var unowned_visible: int = 0
	for system: Dictionary in visible_state.get("systems", []):
		if str(system.get("owner_id", "")) == faction_id:
			owned_systems += 1
		elif str(system.get("owner_id", "")) == "":
			unowned_visible += 1
	return {
		"turn": int(game_state.get("turn", 1)),
		"owned_systems": owned_systems,
		"visible_systems": visible_state.get("systems", []).size(),
		"unowned_visible_systems": unowned_visible,
		"fleets": visible_state.get("fleets", []).size(),
		"fleet_power": _fleet_power_sum(visible_state.get("fleets", [])),
		"food": int(resources.get("food", 0)),
		"minerals": int(resources.get("minerals", 0)),
		"industry": int(resources.get("industry", 0)),
		"energy": int(resources.get("energy", 0)),
		"food_net": int(income.get("food", 0)),
		"minerals_net": int(income.get("minerals", 0)),
		"industry_net": int(income.get("industry", 0)),
		"energy_net": int(income.get("energy", 0)),
		"active_treaties": visible_state.get("active_treaties", []).size(),
		"pending_proposals": visible_state.get("pending_proposals", []).size(),
		"war_count": _war_count(game_state, faction_id),
		"military_progress": _military_progress(victory_report.get("military", {})),
		"diplomacy_votes": int(victory_report.get("diplomatic", {}).get("votes_for", 0)),
		"science_progress": _science_progress(victory_report.get("science", {})),
		"high_pressure_count": int(posture_report.get("high_pressure_count", 0)),
		"high_opportunity_count": int(posture_report.get("high_opportunity_count", 0)),
		"status_code": _status_code(str(game_state.get("status", "IN_PROGRESS"))),
	}


func _vp_t(victory_report: Dictionary) -> Dictionary:
	var military: float = _military_progress(victory_report.get("military", {}))
	var diplomatic: float = _diplomatic_progress(victory_report.get("diplomatic", {}))
	var science: float = _science_progress(victory_report.get("science", {}))
	return {
		"military": military,
		"diplomatic": diplomatic,
		"science": science,
		"best": max(military, max(diplomatic, science)),
		"status": str(victory_report.get("status", "IN_PROGRESS")),
	}


func _military_progress(report: Dictionary) -> float:
	if bool(report.get("achieved", false)):
		return 1.0
	var control_progress := 0.0
	if int(report.get("required_control", 0)) > 0:
		control_progress = float(report.get("controlled_habitable_systems", 0)) / float(report.get("required_control", 1))
	var capital_progress := 0.0
	if int(report.get("rival_capitals", 0)) > 0:
		capital_progress = float(report.get("captured_capitals", 0)) / float(report.get("rival_capitals", 1))
	return clamp(max(control_progress, capital_progress), 0.0, 1.0)


func _diplomatic_progress(report: Dictionary) -> float:
	if bool(report.get("achieved", false)):
		return 1.0
	if int(report.get("required_votes", 0)) <= 0:
		return 0.0
	return clamp(float(report.get("votes_for", 0)) / float(report.get("required_votes", 1)), 0.0, 1.0)


func _science_progress(report: Dictionary) -> float:
	if bool(report.get("achieved", false)):
		return 1.0
	var ascension_progress: float = clamp(float(report.get("progress", 0)) / 100.0, 0.0, 1.0)
	var charge_required: int = int(report.get("charge_required", 0))
	var charge_progress := 0.0
	if charge_required > 0:
		charge_progress = float(report.get("charge_progress", 0)) / float(charge_required)
	return clamp(max(ascension_progress, charge_progress), 0.0, 1.0)


func _fleet_power_sum(fleets: Array) -> float:
	var total := 0.0
	for fleet: Dictionary in fleets:
		total += float(fleet.get("power", 0.0))
	return total


func _resource_delta(before_features: Dictionary, after_features: Dictionary) -> Dictionary:
	return {
		"food": int(after_features.get("food", 0)) - int(before_features.get("food", 0)),
		"minerals": int(after_features.get("minerals", 0)) - int(before_features.get("minerals", 0)),
		"industry": int(after_features.get("industry", 0)) - int(before_features.get("industry", 0)),
		"energy": int(after_features.get("energy", 0)) - int(before_features.get("energy", 0)),
	}


func _war_count(game_state: Dictionary, faction_id: String) -> int:
	var count := 0
	for faction: Dictionary in game_state.get("factions", []):
		var other_id: String = str(faction.get("id", ""))
		if other_id != "" and other_id != faction_id and GameLogicScript.has_treaty(game_state, faction_id, other_id, "WAR_STATE"):
			count += 1
	return count


func _risk_flags(before_snapshot: Dictionary, after_snapshot: Dictionary) -> Array:
	var flags: Array = []
	if str(after_snapshot.get("status", "IN_PROGRESS")) != str(before_snapshot.get("status", "IN_PROGRESS")):
		flags.append("status_changed")
	if float(after_snapshot.get("features23", {}).get("fleet_power", 0.0)) < float(before_snapshot.get("features23", {}).get("fleet_power", 0.0)):
		flags.append("military_power_loss")
	if float(after_snapshot.get("vp_t", {}).get("best", 0.0)) < float(before_snapshot.get("vp_t", {}).get("best", 0.0)):
		flags.append("vp_regression")
	return flags


func _vp_auc(snapshots: Array) -> float:
	if snapshots.is_empty():
		return 0.0
	var total := 0.0
	for snapshot: Dictionary in snapshots:
		total += float(snapshot.get("vp_t", {}).get("best", 0.0))
	return total / float(snapshots.size())


func _status_code(status: String) -> int:
	match status:
		"PLAYER_VICTORY":
			return 2
		"PLAYER_DEFEAT":
			return -2
		"STALEMATE":
			return -1
		_:
			return 0


func _snapshot_digest(snapshot: Dictionary) -> String:
	var stable: Dictionary = {
		"game_id": snapshot.get("game_id", DEFAULT_GAME_ID),
		"turn": snapshot.get("turn", 1),
		"features23": snapshot.get("features23", {}),
		"vp_t": snapshot.get("vp_t", {}),
	}
	return str(JSON.stringify(stable).hash())
