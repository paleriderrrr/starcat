extends SceneTree

const OpenAIChatProviderScript = preload("res://scripts/llm/OpenAIChatProvider.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var api_key: String = str(OS.get_environment("MIMO_API_KEY")).strip_edges()
	if api_key == "":
		print("STARCAT_MIMO_PROVIDER_SKIPPED missing MIMO_API_KEY")
		quit(0)
		return
	var provider: Node = OpenAIChatProviderScript.new()
	root.add_child(provider)
	provider.configure({
		"provider_enabled": true,
		"api_key": api_key,
		"model": str(OS.get_environment("MIMO_MODEL")) if str(OS.get_environment("MIMO_MODEL")).strip_edges() != "" else "mimo-v2.5-pro",
		"base_url": str(OS.get_environment("MIMO_BASE_URL")) if str(OS.get_environment("MIMO_BASE_URL")).strip_edges() != "" else "https://api.xiaomimimo.com/v1",
		"temperature": 0.3,
		"top_p": 0.95,
	})
	var started_msec: int = Time.get_ticks_msec()
	provider.request_text("请只返回严格 JSON，不要 Markdown，不要解释: {\"ok\":true,\"provider\":\"mimo\"}", 64, func(ok: bool, text: String, payload: Dictionary) -> void:
		var elapsed_msec: int = Time.get_ticks_msec() - started_msec
		if not ok:
			printerr("STARCAT_MIMO_PROVIDER_FAILED elapsed_ms=%s %s" % [str(elapsed_msec), text])
			quit(1)
			return
		var parsed: Variant = JSON.parse_string(_extract_first_json_object(text))
		if not parsed is Dictionary or parsed.get("ok", false) != true or str(parsed.get("provider", "")) != "mimo":
			printerr("STARCAT_MIMO_PROVIDER_FAILED elapsed_ms=%s invalid smoke response" % str(elapsed_msec))
			quit(1)
			return
		var model_name: String = str(payload.get("model", "unknown"))
		print("STARCAT_MIMO_PROVIDER_OK model=%s elapsed_ms=%s chars=%s" % [model_name, str(elapsed_msec), str(text.length())])
		quit(0)
	)

func _extract_first_json_object(text: String) -> String:
	var start: int = text.find("{")
	var end: int = text.rfind("}")
	if start == -1 or end == -1 or end <= start:
		return text
	return text.substr(start, end - start + 1)
