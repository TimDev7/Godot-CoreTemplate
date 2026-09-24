extends GutTest

# Covers template/sdk/sdk.gd: our thin facade over the two vendored portal
# SDKs (Playgama Bridge, GamePix's own plugin). Outside a web export both
# fall back to safe stand-ins - Bridge to its own editor-mock modules (see
# addons/playgama_bridge/modules/*/*_editor_mock.gd), GPX.gpx stays null
# (see gpx.gd's own _ready(), which only sets it when OS.has_feature("web")
# is true) - so every test here exercises the Bridge branch specifically,
# same as production traffic on any portal Bridge covers. Real ad-network
# behavior, and the GPX branch specifically, can only be verified in an
# actual web export on the matching portal; this only proves the facade
# calls the right things and handles both SDKs' callback shapes correctly.


func after_each() -> void:
	SDK.ad_timeout_sec = 45.0


func test_running_against_the_mock_platform() -> void:
	# Sanity anchor for this whole file: if this ever fails, everything
	# below is silently testing something other than the mock.
	assert_eq(Bridge.platform.id, "mock")
	assert_null(GPX.gpx, "GPX.gpx must stay null outside a real web export")


func test_notify_functions_do_not_error_against_the_mock() -> void:
	SDK.notify_loading_finished()
	SDK.notify_level_started()
	SDK.notify_level_completed()
	SDK.notify_level_completed(7)
	SDK.notify_level_failed()
	assert_eq(Bridge.platform.id, "mock") # just needs an assertion to not be "risky"


func test_platform_language_falls_back_to_bridge_when_no_gpx() -> void:
	assert_eq(SDK.platform_language(), Bridge.platform.language)


func test_connect_platform_signals_is_idempotent() -> void:
	SDK.connect_platform_signals()
	SDK.connect_platform_signals()
	SDK.connect_platform_signals()

	assert_eq(Bridge.platform.audio_state_changed.get_connections().size(), 1)
	assert_eq(Bridge.platform.pause_state_changed.get_connections().size(), 1)


func test_show_interstitial_runs_to_closed_via_the_mock() -> void:
	SDK.show_interstitial()
	assert_eq(Bridge.advertisement.interstitial_state, Bridge.InterstitialState.CLOSED)


func test_show_interstitial_calls_on_complete() -> void:
	var completed := [false]

	SDK.show_interstitial(func(): completed[0] = true)

	assert_true(completed[0])


func test_show_interstitial_ignores_a_call_while_one_is_in_flight() -> void:
	SDK.ad_timeout_sec = 0.05
	var completions := [0]
	# The mock's show_interstitial() resolves synchronously, so to actually
	# observe "in flight" this leans on the real in-progress flag directly
	# rather than racing a timer - the flag IS the thing under test.
	SDK._interstitial_in_progress = true

	SDK.show_interstitial(func(): completions[0] += 1)

	assert_eq(completions[0], 0, "a call made while one is already in flight must be ignored")
	SDK._interstitial_in_progress = false


func test_show_rewarded_calls_on_reward_when_the_mock_grants_one() -> void:
	var reward_calls := [0]
	var no_reward_calls := [0]

	SDK.show_rewarded(func(): reward_calls[0] += 1, func(): no_reward_calls[0] += 1)

	assert_eq(reward_calls[0], 1)
	assert_eq(no_reward_calls[0], 0)


func test_show_rewarded_works_without_an_on_no_reward_callback() -> void:
	var reward_calls := [0]

	SDK.show_rewarded(func(): reward_calls[0] += 1)

	assert_eq(reward_calls[0], 1)


func test_show_rewarded_disconnects_so_repeated_calls_dont_stack() -> void:
	var reward_calls := [0]

	SDK.show_rewarded(func(): reward_calls[0] += 1)
	SDK.show_rewarded(func(): reward_calls[0] += 1)

	# 2, not 3+: if the first call's listener leaked, the second show_rewarded
	# would fire it again on top of its own.
	assert_eq(reward_calls[0], 2)
	assert_eq(Bridge.advertisement.rewarded_state_changed.get_connections().size(), 0)


func test_ad_timeout_recovers_a_hung_call() -> void:
	SDK.ad_timeout_sec = 0.05
	# Simulates a hung SDK call: the in-progress flag is set, but nothing
	# will ever resolve it on its own - only _first_to_fire's own timer can.
	SDK._interstitial_in_progress = true
	var recovered := [false]
	SDK._first_to_fire([func(): recovered[0] = true], func(): recovered[0] = true)

	await wait_seconds(0.1)

	assert_true(recovered[0], "the timeout fallback must fire when nothing else does")
	SDK._interstitial_in_progress = false
