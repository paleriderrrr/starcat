extends RefCounted

class_name LocalConfig

const LOCAL_CONFIG_PATH: String = "res://starcat.local.cfg"
const SECTION_LLM: String = "llm"

static func _project_setting(key: String, default_value: Variant) -> Variant:
	return ProjectSettings.get_setting(key, default_value)

static func load_settings() -> Dictionary:
	var settings: Dictionary = {
		"remote_enabled": bool(_project_setting("starcat/llm/remote_enabled", false)),
		"api_key": str(_project_setting("starcat/llm/api_key", "")),
		"model": str(_project_setting("starcat/llm/model", "qwen3.5-flash")),
		"base_url": str(_project_setting("starcat/llm/base_url", "https://dashscope.aliyuncs.com/api/v2/apps/protocols/compatible-mode/v1")),
	}
	var config: ConfigFile = ConfigFile.new()
	if config.load(LOCAL_CONFIG_PATH) == OK:
		settings["remote_enabled"] = bool(config.get_value(SECTION_LLM, "remote_enabled", settings["remote_enabled"]))
		settings["api_key"] = str(config.get_value(SECTION_LLM, "api_key", settings["api_key"]))
		settings["model"] = str(config.get_value(SECTION_LLM, "model", settings["model"]))
		settings["base_url"] = str(config.get_value(SECTION_LLM, "base_url", settings["base_url"]))
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

