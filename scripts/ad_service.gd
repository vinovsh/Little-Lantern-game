extends Node
## No fake ads or simulated rewards in a player build. Native bridge is optional.
signal availability_changed
signal reward_earned(placement: String, token: String)
signal closed
var bridge: Object
var pending := ""
var pending_placement := ""
var consumed: Dictionary = {}
var fullscreen_pending := false
var recently_closed_token := ""
var recently_closed_placement := ""
var completed_since_ad := 0
var last_fullscreen := -1000.0
var session_started := 0.0

func _ready() -> void:
	session_started = Time.get_ticks_msec() / 1000.0
	if Engine.has_singleton("LanternAds"):
		bridge = Engine.get_singleton("LanternAds")
		bridge.connect("reward_earned", _on_reward)
		bridge.connect("ad_closed", _on_closed)
		bridge.connect("availability_changed", func(): availability_changed.emit())
		bridge.call("initialize")

func rewarded_ready() -> bool:
	return bridge != null and not fullscreen_pending and pending.is_empty() and bool(bridge.call("is_rewarded_ready"))

func show_rewarded(placement: String, token: String) -> bool:
	if not rewarded_ready() or consumed.has(token):
		return false
	pending = token
	pending_placement = placement
	fullscreen_pending = true
	recently_closed_token = ""
	recently_closed_placement = ""
	last_fullscreen = Time.get_ticks_msec() / 1000.0
	bridge.call("show_rewarded", placement, token)
	return true

func _on_reward(placement: String, token: String) -> void:
	var current := token == pending and placement == pending_placement
	var late := token == recently_closed_token and placement == recently_closed_placement
	if (not current and not late) or consumed.has(token):
		return
	consumed[token] = true
	reward_earned.emit(placement, token)

func _on_closed() -> void:
	if not fullscreen_pending:
		return
	fullscreen_pending = false
	recently_closed_token = pending
	recently_closed_placement = pending_placement
	pending = ""
	pending_placement = ""
	closed.emit()

func invalidate() -> void:
	consumed.clear()
	fullscreen_pending = false
	recently_closed_token = ""
	recently_closed_placement = ""
	pending = ""
	pending_placement = ""

func try_interstitial() -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if bridge == null or fullscreen_pending or completed_since_ad < 3 or now - session_started < 180 or now - last_fullscreen < 120:
		return false
	if not bool(bridge.call("is_interstitial_ready")):
		return false
	last_fullscreen = now
	completed_since_ad = 0
	fullscreen_pending = true
	bridge.call("show_interstitial")
	return true

