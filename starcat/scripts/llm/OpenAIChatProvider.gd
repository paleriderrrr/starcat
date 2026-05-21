extends Node

class_name OpenAIChatProvider

const CHAT_COMPLETIONS_PATH: String = "/chat/completions"
const MIN_COMPLETION_TOKENS: int = 1024
const RETRYABLE_HTTP_CODES: Array[int] = [408, 409, 425, 429, 500, 502, 503, 504]

var _settings: Dictionary = {}

func configure(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)

func enabled() -> bool:
	return bool(_settings.get("provider_enabled", false))

func request_text(prompt: String, max_output_tokens: int, on_complete: Callable) -> void:
	if not enabled():
		on_complete.call(false, "LLM provider not enabled", {})
		return
	var request_node: HTTPRequest = HTTPRequest.new()
	add_child(request_node)
	request_node.request_completed.connect(_on_request_completed.bind(request_node, on_complete))
	var body: String = JSON.stringify({
		"model": str(_settings.get("model", "mimo-v2.5-pro")),
		"messages": [
			{
				"role": "system",
				"content": "你是星际战略游戏 Starcat 的 AI 决策与叙事服务。请严格按照用户要求返回可解析的简洁文本。"
			},
			{
				"role": "user",
				"content": prompt
			}
		],
		"max_completion_tokens": maxi(max_output_tokens, MIN_COMPLETION_TOKENS),
		"temperature": float(_settings.get("temperature", 0.3)),
		"top_p": float(_settings.get("top_p", 0.95)),
		"stream": false,
	})
	var headers: PackedStringArray = PackedStringArray([
		_auth_header(),
		"Content-Type: application/json",
	])
	var base_url: String = str(_settings.get("base_url", "")).rstrip("/")
	var error_code: int = request_node.request("%s%s" % [base_url, CHAT_COMPLETIONS_PATH], headers, HTTPClient.METHOD_POST, body)
	if error_code != OK:
		request_node.queue_free()
		on_complete.call(false, "无法发起 LLM 请求。", {})

func _auth_header() -> String:
	var api_key: String = str(_settings.get("api_key", ""))
	if str(_settings.get("auth_header", "")).to_lower() == "api-key":
		return "api-key: %s" % api_key
	return "Authorization: Bearer %s" % api_key

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest, on_complete: Callable) -> void:
	request_node.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		on_complete.call(false, "LLM 请求失败。", {})
		return
	var text: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if response_code < 200 or response_code >= 300:
		var error_payload: Dictionary = parsed if parsed is Dictionary else {}
		on_complete.call(false, _extract_error_message(error_payload, response_code), error_payload)
		return
	var payload: Dictionary = parsed if parsed is Dictionary else {}
	var output_text: String = _extract_output_text(payload)
	if output_text == "":
		on_complete.call(false, "LLM 返回内容为空。", payload)
		return
	on_complete.call(true, output_text, payload)

func _extract_output_text(payload: Dictionary) -> String:
	for choice: Dictionary in payload.get("choices", []):
		var message: Dictionary = choice.get("message", {})
		var content: String = str(message.get("content", "")).strip_edges()
		if content != "":
			return content
	return ""

func _extract_error_message(payload: Dictionary, response_code: int) -> String:
	var nested_error: Dictionary = payload.get("error", {})
	var message: String = str(nested_error.get("message", payload.get("message", ""))).strip_edges()
	if message != "":
		return message
	if RETRYABLE_HTTP_CODES.has(response_code):
		return "LLM 服务暂时不可用。"
	return "LLM 返回错误状态 %s。" % str(response_code)
