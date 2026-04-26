extends RefCounted

class_name NarrativeService

const FORMAT_VERSION: String = "1.0"

func fallback_diplomatic_message(sender: Dictionary, target: Dictionary, relationship_level: String, tone: String) -> Dictionary:
	var title: String = "%s 致 %s 的照会" % [str(sender.get("leaderName", "未知领袖")), str(target.get("name", "对方势力"))]
	var content: String = "基于当前 %s 关系，我方以 %s 立场发出正式回应，并提请贵方评估下一步合作与边境安排。" % [relationship_level, tone]
	return _message_payload(title, content, "fallback", true)

func build_diplomatic_prompt(sender: Dictionary, target: Dictionary, relationship_level: String, tone: String, game_state: Dictionary) -> String:
	return "\n".join([
		"TASK",
		"为太空策略游戏中的外交照会生成一个 JSON 对象。",
		"",
		"OUTPUT_SCHEMA",
		'{"title":"Chinese title","content":"single Chinese paragraph"}',
		"",
		"HARD_RULES",
		"- 只返回一个 JSON 对象。",
		"- title 使用中文，控制在 8-18 字符。",
		"- content 使用中文单段落，控制在 40-100 字符。",
		"- 必须体现 relationship_level 与 tone。",
		"",
		"INPUT_JSON",
		JSON.stringify({
			"sender_name": sender.get("leaderName", ""),
			"recipient_name": target.get("name", ""),
			"relationship_level": relationship_level,
			"tone": tone,
			"personality": sender.get("personality", {}),
			"turn": game_state.get("turn", 1),
		}),
	])

func parse_diplomatic_message(raw_text: String, fallback: Dictionary) -> Dictionary:
	var parsed: Dictionary = _extract_json(raw_text)
	var title: String = _sanitize_text(str(parsed.get("title", "")), 24)
	var content: String = _sanitize_text(str(parsed.get("content", "")), 120)
	if title == "" or content == "":
		return fallback
	return _message_payload(title, content, "bailian", false)

func fallback_conversation(sender: Dictionary, recipient_name: String, relationship_level: String, tone: String, player_message: String, visibility_level: String) -> Dictionary:
	var title: String = "%s 的回函" % str(sender.get("leaderName", "未知领袖"))
	var snippet: String = player_message.substr(0, min(24, player_message.length()))
	var content: String = "我方已收到你关于“%s”的来信。基于当前 %s 关系，我方会以 %s 的立场继续观察并回应后续动向。" % [snippet, relationship_level, tone]
	return _conversation_payload(title, content, tone, visibility_level, "fallback", true)

func build_conversation_prompt(sender: Dictionary, recipient_name: String, relationship_level: String, tone: String, player_message: String, visibility_level: String, intent_type: String, intent_detail: String, game_state: Dictionary) -> String:
	return "\n".join([
		"TASK",
		"为太空策略游戏中的外交回函生成一个 JSON 对象。",
		"",
		"OUTPUT_SCHEMA",
		'{"title":"Chinese title","content":"single Chinese paragraph","tone":"friendly|neutral|firm|hostile"}',
		"",
		"HARD_RULES",
		"- 只返回一个 JSON 对象。",
		"- content 使用中文单段落，控制在 40-140 字符。",
		"- tone 必须是 friendly/neutral/firm/hostile 之一。",
		"- 必须根据 player_message、intent_type、intent_detail 和 relationship_level 作出回应。",
		"",
		"INPUT_JSON",
		JSON.stringify({
			"sender_name": sender.get("leaderName", ""),
			"recipient_name": recipient_name,
			"relationship_level": relationship_level,
			"requested_tone": tone,
			"visibility_level": visibility_level,
			"intent_type": intent_type,
			"intent_detail": intent_detail,
			"player_message": player_message,
			"personality": sender.get("personality", {}),
			"turn": game_state.get("turn", 1),
		}),
	])

func parse_conversation(raw_text: String, fallback: Dictionary) -> Dictionary:
	var parsed: Dictionary = _extract_json(raw_text)
	var title: String = _sanitize_text(str(parsed.get("title", "")), 24)
	var content: String = _sanitize_text(str(parsed.get("content", "")), 160)
	var tone: String = str(parsed.get("tone", fallback.get("tone", "neutral"))).to_lower()
	if title == "" or content == "" or not ["friendly", "neutral", "firm", "hostile"].has(tone):
		return fallback
	return _conversation_payload(title, content, tone, str(fallback.get("visibility_level", "PUBLIC")), "bailian", false)

func fallback_narrative_content(context: String, style: String, recipient: String, content_type: String) -> Dictionary:
	var generated_content: String = "经通报，%s。接收对象：%s。该内容将作为 %s 使用。" % [context, recipient if recipient != "" else "全银河", content_type]
	var tone_analysis: String = "当前采用 %s 风格输出，偏向稳定、可直接嵌入界面。" % style
	return {
		"generated_content": generated_content,
		"tone_analysis": tone_analysis,
		"key_themes": [content_type.to_lower(), style.to_lower()],
	}

func build_narrative_prompt(context: String, style: String, recipient: String, content_type: String, game_state: Dictionary) -> String:
	return "\n".join([
		"TASK",
		"为太空策略游戏生成叙事文本 JSON。",
		"",
		"OUTPUT_SCHEMA",
		'{"generated_content":"Chinese paragraph","tone_analysis":"Chinese sentence","key_themes":["string"]}',
		"",
		"HARD_RULES",
		"- 只返回一个 JSON 对象。",
		"- generated_content 使用中文单段落。",
		"- tone_analysis 使用中文简短分析。",
		"",
		"INPUT_JSON",
		JSON.stringify({
			"context": context,
			"style": style,
			"recipient": recipient,
			"content_type": content_type,
			"turn": game_state.get("turn", 1),
		}),
	])

func parse_narrative_content(raw_text: String, fallback: Dictionary) -> Dictionary:
	var parsed: Dictionary = _extract_json(raw_text)
	var generated_content: String = _sanitize_text(str(parsed.get("generated_content", "")), 240)
	var tone_analysis: String = _sanitize_text(str(parsed.get("tone_analysis", "")), 80)
	if generated_content == "" or tone_analysis == "":
		return fallback
	var key_themes: Array = []
	for item: Variant in parsed.get("key_themes", []):
		key_themes.append(str(item))
	return {
		"generated_content": generated_content,
		"tone_analysis": tone_analysis,
		"key_themes": key_themes,
	}

func _message_payload(title: String, content: String, source: String, is_fallback: bool) -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"source": source,
		"is_fallback": is_fallback,
		"structured_text": _message_structured_text(title, content, source, is_fallback),
		"title": title,
		"content": content,
	}

func _conversation_payload(title: String, content: String, tone: String, visibility_level: String, source: String, is_fallback: bool) -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"source": source,
		"is_fallback": is_fallback,
		"structured_text": _conversation_structured_text(title, content, tone, visibility_level, source, is_fallback),
		"title": title,
		"content": content,
		"tone": tone,
		"visibility_level": visibility_level,
	}

func _message_structured_text(title: String, content: String, source: String, is_fallback: bool) -> String:
	return "\n".join([
		"[AI_DIPLOMATIC_MESSAGE]",
		"format_version: %s" % FORMAT_VERSION,
		"source: %s" % source,
		"is_fallback: %s" % str(is_fallback).to_lower(),
		"title: %s" % title,
		"content: %s" % content,
		"[/AI_DIPLOMATIC_MESSAGE]",
	])

func _conversation_structured_text(title: String, content: String, tone: String, visibility_level: String, source: String, is_fallback: bool) -> String:
	return "\n".join([
		"[AI_DIPLOMATIC_CONVERSATION]",
		"format_version: %s" % FORMAT_VERSION,
		"source: %s" % source,
		"is_fallback: %s" % str(is_fallback).to_lower(),
		"visibility_level: %s" % visibility_level,
		"title: %s" % title,
		"content: %s" % content,
		"tone: %s" % tone,
		"[/AI_DIPLOMATIC_CONVERSATION]",
	])

func _extract_json(raw_text: String) -> Dictionary:
	var matcher: RegEx = RegEx.new()
	matcher.compile("\\{[\\s\\S]*\\}")
	var result: RegExMatch = matcher.search(raw_text)
	if result == null:
		return {}
	var parsed: Variant = JSON.parse_string(result.get_string())
	return parsed if parsed is Dictionary else {}

func _sanitize_text(text: String, max_chars: int) -> String:
	var normalized: String = text.replace("\n", " ").replace("\r", " ").strip_edges()
	if normalized.length() > max_chars:
		return normalized.substr(0, max_chars).strip_edges()
	return normalized

