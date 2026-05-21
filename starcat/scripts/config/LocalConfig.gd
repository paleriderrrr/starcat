extends RefCounted

class_name LocalConfig

const LOCAL_CONFIG_PATH: String = "res://starcat.local.cfg"
const SECTION_LLM: String = "llm"

static func _project_setting(key: String, default_value: Variant) -> Variant:
	return ProjectSettings.get_setting(key, default_value)

static func load_settings() -> Dictionary:
	var settings: Dictionary = {
		"remote_enabled": bool(_project_setting("starcat/llm/remote_enabled", false)),
		"provider": str(_project_setting("starcat/llm/provider", "bailian")),
		"auth_header": str(_project_setting("starcat/llm/auth_header", "")),
		"api_key": str(_project_setting("starcat/llm/api_key", "")),
		"mimo_api_key": str(_project_setting("starcat/llm/mimo_api_key", "")),
		"mimo_model": str(_project_setting("starcat/llm/mimo_model", "")),
		"mimo_base_url": str(_project_setting("starcat/llm/mimo_base_url", "")),
		"model": str(_project_setting("starcat/llm/model", "qwen3.5-flash")),
		"base_url": str(_project_setting("starcat/llm/base_url", "https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1")),
	}
	var config: ConfigFile = ConfigFile.new()
	if config.load(LOCAL_CONFIG_PATH) == OK:
		settings["remote_enabled"] = bool(config.get_value(SECTION_LLM, "remote_enabled", settings["remote_enabled"]))
		settings["provider"] = str(config.get_value(SECTION_LLM, "provider", settings["provider"]))
		settings["auth_header"] = str(config.get_value(SECTION_LLM, "auth_header", settings["auth_header"]))
		settings["api_key"] = str(config.get_value(SECTION_LLM, "api_key", settings["api_key"]))
		settings["mimo_api_key"] = str(config.get_value(SECTION_LLM, "mimo_api_key", settings["mimo_api_key"]))
		settings["mimo_model"] = str(config.get_value(SECTION_LLM, "mimo_model", settings["mimo_model"]))
		settings["mimo_base_url"] = str(config.get_value(SECTION_LLM, "mimo_base_url", settings["mimo_base_url"]))
		settings["model"] = str(config.get_value(SECTION_LLM, "model", settings["model"]))
		settings["base_url"] = str(config.get_value(SECTION_LLM, "base_url", settings["base_url"]))
	var provider: String = str(settings["provider"]).to_lower()
	if provider == "mimo":
		var env_mimo_api_key: String = str(OS.get_environment("MIMO_API_KEY")).strip_edges()
		var mimo_api_key: String = str(settings.get("mimo_api_key", "")).strip_edges()
		if env_mimo_api_key != "":
			settings["api_key"] = env_mimo_api_key
		elif mimo_api_key != "":
			settings["api_key"] = mimo_api_key
		elif str(settings["api_key"]).strip_edges() == "":
			settings["api_key"] = ""
		var mimo_model: String = str(settings.get("mimo_model", "")).strip_edges()
		var env_mimo_model: String = str(OS.get_environment("MIMO_MODEL")).strip_edges()
		if settings["model"] == "" or settings["model"] == "qwen3.5-flash":
			settings["model"] = env_mimo_model if env_mimo_model != "" else mimo_model
		if settings["model"] == "":
			settings["model"] = "mimo-v2.5-pro"
		var mimo_base_url: String = str(settings.get("mimo_base_url", "")).strip_edges()
		var env_mimo_base_url: String = str(OS.get_environment("MIMO_BASE_URL")).strip_edges()
		if settings["base_url"] == "" or str(settings["base_url"]).contains("dashscope.aliyuncs.com"):
			settings["base_url"] = env_mimo_base_url if env_mimo_base_url != "" else mimo_base_url
		if settings["base_url"] == "":
			settings["base_url"] = "https://api.xiaomimimo.com/v1"
	if provider != "mimo":
		if settings["api_key"] == "":
			settings["api_key"] = str(OS.get_environment("BAILIAN_API_KEY"))
		if settings["api_key"] == "":
			settings["api_key"] = str(OS.get_environment("DASHSCOPE_API_KEY"))
		if settings["model"] == "":
			settings["model"] = str(OS.get_environment("BAILIAN_MODEL"))
		if settings["base_url"] == "":
			settings["base_url"] = str(OS.get_environment("BAILIAN_BASE_URL"))
	settings["provider_enabled"] = bool(settings["remote_enabled"]) and str(settings["api_key"]) != ""
	return settings
