extends RefCounted
class_name SDK

## Thin, portable facade over two vendored portal SDKs: Playgama Bridge
## (res://addons/playgama_bridge, MIT-licensed, https://github.com/Playgama/bridge-godot-4)
## for portals it supports (Y8, CrazyGames, and others - see its own
## platform id list), and GamePix's own plugin (res://addons/gpx-godot-plugin)
## for GamePix specifically, which Playgama Bridge doesn't cover at all.
## Game code calls SDK.* instead of touching Bridge.*/GPX.* directly.
##
## The two are shipped as genuinely separate exports (see export_presets.cfg's
## "Web" vs "GamePix" presets - each portal's SDK needs its own
## custom_html_shell, so one build can't serve both at once), but this file
## stays a single codepath for both: GPX.gpx is only non-null when the
## GamePix JS SDK is actually present (see gpx.gd's own _ready()), so
## checking that at call time picks the right backend automatically no
## matter which preset produced the running build - ad/analytics calls for
## the OTHER SDK, which was never loaded in that build's HTML at all, would
## otherwise silently no-op (or for GPX.rewardAd() specifically, instantly
## "succeed" - see show_rewarded()'s own comment on why that one specifically
## can't be called unconditionally).
##
## Bridge auto-detects the platform (OS.has_feature("web")) and falls back
## to safe mock modules everywhere else (editor, desktop, or a web export
## whose HTML never actually loaded window.bridge at all - e.g. the
## GamePix preset) - see addons/playgama_bridge/modules/*/​*_editor_mock.gd
## and bridge.gd's own _ready(). That mock is what every GUT test in this
## project runs against, since tests always run outside a web export.
##
## Adding a new portal later: if it has its own Playgama Bridge-style module
## (see bridge.gd), no changes needed here at all. If it needs its own
## separate plugin (like GPX), give that plugin the same "only non-null
## when its own JS SDK is actually present" shape as gpx.gd, and add one
## more `if <PLUGIN>.<obj> != null:` branch alongside GPX's below in each
## relevant method - never replace the Bridge branch, since a portal using
## Bridge still needs it.


## How long an ad's own promise/callback gets to fire before this facade
## gives up on it and recovers on its own. A plugin can pause the SceneTree
## itself right before firing an ad request and only unpause inside that
## request's own resolution (see gpx.gd's interstitialAd()/rewardAd()) - if
## that promise never settles (a JS-side SDK issue on the portal's end, not
## something fixable from this facade without patching the vendored
## plugin), the whole game would otherwise stay frozen forever. Generous on
## purpose - real interstitial/rewarded videos commonly run up to 30s, and
## this must never cut one off mid-play - it's purely a recovery net for a
## genuinely broken/hung call. A static var (not a const) so tests can
## shrink it instead of waiting on the wall clock.
static var ad_timeout_sec: float = 45.0


## Wraps each of on_fire so only the first of them - or, failing that,
## timeout_fallback once ad_timeout_sec elapses - actually runs; every
## other one (including a real SDK callback that finally arrives late,
## after this facade already gave up on it) becomes a silent no-op. Also
## unconditionally un-pauses the tree on timeout, on top of just calling
## timeout_fallback - see ad_timeout_sec's own comment on why that's
## needed here specifically (harmless when nothing was actually paused).
static func _first_to_fire(on_fire: Array[Callable], timeout_fallback: Callable) -> Array[Callable]:
	var fired := [false]
	var wrapped: Array[Callable] = []
	for c in on_fire:
		wrapped.append(func() -> void:
			if fired[0]:
				return
			fired[0] = true
			c.call()
		)
	var tree := Engine.get_main_loop() as SceneTree
	tree.create_timer(ad_timeout_sec).timeout.connect(func() -> void:
		if fired[0]:
			return
		fired[0] = true
		push_warning("SDK: ad_timeout_sec (%s s) elapsed with no ad callback - forcing recovery" % ad_timeout_sec)
		tree.paused = false
		timeout_fallback.call()
	)
	return wrapped


## The portal's own player language, an arbitrary tag ("en", "pt-BR", ...)
## - "en" outside a real web export/portal (the editor mock's
## platform_editor_mock.gd always reports "en"). Callers matching this
## against their own supported language list should normalize it first.
## Checked on GPX first since Bridge.platform.language falls back to its
## own mock (always "en") on a GamePix build - Playgama's own window.bridge
## script is never loaded there (see bridge.gd's _ready()), so it never has
## a real answer to give.
static func platform_language() -> String:
	if GPX.gpx != null:
		return GPX.lang()
	return Bridge.platform.language


## True once connect_platform_signals() has wired its connections, so
## calling it again (e.g. every time Title is revisited) doesn't stack a
## second listener on top of the first.
static var _platform_signals_connected: bool = false


## Wires Bridge's own portal-driven audio/pause signals (Bridge.platform.
## audio_state_changed / pause_state_changed - see platform.gd) into this
## project's own mute/pause systems. Per Playgama's own docs
## (https://wiki.playgama.com/playgama/bridge-sdk/api/platform): the portal
## (Y8, CrazyGames, ...) raises these whenever IT wants the game muted/
## paused - a site-wide mute button, another game's ad overlay opening on
## the same page, the browser tab losing focus - and Playgama explicitly
## documents this as required, one universal handler covering every case,
## not just tab-switching. Call from somewhere guaranteed to run after
## every autoload is ready (Bridge loads after Core in project.godot's
## [autoload] list, so Core's own _ready() is too early) - Title's own
## _ready(), right alongside notify_loading_finished(), fits and is
## idempotent-safe to call again on every Title revisit.
static func connect_platform_signals() -> void:
	if _platform_signals_connected:
		return
	_platform_signals_connected = true
	Bridge.platform.audio_state_changed.connect(func(enabled: bool) -> void:
		Core.sound_manager.set_bus_mute("Master", not enabled)
	)
	Bridge.platform.pause_state_changed.connect(func(should_pause: bool) -> void:
		Core.toggle_pause(should_pause, "platform")
	)


## Call once, as early as possible (e.g. Title's _ready()), once the game
## is actually ready to play - portals show their own loading screen until
## this fires. GamePix specifically also needs its own game.gameLoaded()
## call on top of Bridge's GAME_READY message: per GamePix's docs,
## interstitialAd()/rewardAd() both reject with "GAMEPIX_LOADED_NOT_CALLED"
## until gameLoaded() has been called, and the vendored plugin never calls
## it on its own. Called straight on the raw JS object (GPX.gpx), not
## through a gpx.gd wrapper, since gpx.gd doesn't expose one.
static func notify_loading_finished() -> void:
	Bridge.platform.send_message(Bridge.PlatformMessage.GAME_READY)
	if GPX.gpx != null:
		GPX.gpx.game.gameLoaded()


static func notify_level_started() -> void:
	Bridge.platform.send_message(Bridge.PlatformMessage.LEVEL_STARTED)


## level_number (the level/stage just cleared), if the game has one, is
## also reported to GamePix via GPX.updateLevel() and GPX.updateScore() -
## GamePix has no dedicated "level completed" message, and updateScore()
## is the closest stand-in for a game whose own idea of "score" IS its
## level number. <= 0 (the default) skips both - a caller with nothing
## meaningful to report just doesn't.
static func notify_level_completed(level_number: int = 0) -> void:
	Bridge.platform.send_message(Bridge.PlatformMessage.LEVEL_COMPLETED)
	# GPX.happyMoment() ("something satisfying just happened") is GamePix's
	# own closest fit for a level clear. Safe to call unconditionally - a
	# no-op when GPX.gpx is null (see gpx.gd's happyMoment()).
	GPX.happyMoment()
	if level_number > 0:
		GPX.updateLevel(level_number)
		GPX.updateScore(level_number)


static func notify_level_failed() -> void:
	Bridge.platform.send_message(Bridge.PlatformMessage.LEVEL_FAILED)


## True from the moment show_interstitial()/show_rewarded() fires an ad
## request until its own completion callback runs (success, no-reward, or
## the ad_timeout_sec recovery). Centralized here - not left to each call
## site to track for itself - specifically so EVERY future caller gets
## this protection automatically: GamePix's own SDK rejects a second
## interstitialAd()/rewardAd() call made before the first resolves with an
## INTERSTITIAL_AD_CALLED_TWICE/REWARD_AD_CALLED_TWICE error outright (not
## just wasted - actively broken). A caller that also wants to grey out its
## own button while an ad is in flight still needs its own flag for that -
## this only prevents the actual double SDK call, it doesn't expose "is one
## in flight" itself.
static var _interstitial_in_progress: bool = false
static var _rewarded_in_progress: bool = false


## on_complete (optional) fires once the ad flow is fully done - shown and
## closed, skipped, failed, or (see ad_timeout_sec) given up on - never
## while it's still on screen. Callers that need to do something right
## after (e.g. reloading the next level) must wait for this instead of
## firing immediately alongside the ad request, to avoid reloading the
## scene before the ad flow's own pause/unpause has caught up. A call made
## while a previous one hasn't finished yet is silently ignored (on_complete
## is simply never called for it) - see _interstitial_in_progress.
static func show_interstitial(on_complete: Callable = Callable()) -> void:
	if _interstitial_in_progress:
		return
	_interstitial_in_progress = true
	var finish := func():
		_interstitial_in_progress = false
		if on_complete.is_valid():
			on_complete.call()
	var complete: Callable = _first_to_fire([finish], finish)[0]
	if GPX.gpx != null:
		GPX.interstitialAd(complete)
		return
	var self_ref := [Callable()]
	self_ref[0] = func(state: String) -> void:
		# Plain if/elif on purpose: match's patterns need to resolve as
		# compile-time constants, and Bridge.InterstitialState.X is a
		# runtime lookup through the Bridge autoload, not one - match
		# silently never matched it.
		if state == Bridge.InterstitialState.CLOSED or state == Bridge.InterstitialState.FAILED:
			Bridge.advertisement.interstitial_state_changed.disconnect(self_ref[0])
			complete.call()
	Bridge.advertisement.interstitial_state_changed.connect(self_ref[0])
	Bridge.advertisement.show_interstitial()


## on_reward is called only if the player watched the ad to completion.
## on_no_reward (optional) is called if the ad was skipped/closed early or
## failed to load - use it to just continue without the bonus, never to
## block the player. A call made while a previous one hasn't finished yet
## is silently ignored (neither callback fires for it) - see
## _rewarded_in_progress.
static func show_rewarded(on_reward: Callable, on_no_reward: Callable = Callable()) -> void:
	if _rewarded_in_progress:
		return
	_rewarded_in_progress = true
	# gpx.gd's own _reward_callback() unconditionally .call()s whichever of
	# these it picks, so both must always be real, valid Callables - these
	# wrap the caller's own (on_no_reward may be unset) and always release
	# _rewarded_in_progress no matter which one fires.
	var finish_reward := func():
		_rewarded_in_progress = false
		on_reward.call()
	var finish_no_reward := func():
		_rewarded_in_progress = false
		if on_no_reward.is_valid():
			on_no_reward.call()
	if GPX.gpx != null:
		# _first_to_fire's timeout is the recovery path if GamePix's own
		# rewardAd() promise never resolves at all (see ad_timeout_sec) -
		# past it, this treats the ad as failed/no-reward and force-unpauses,
		# rather than leaving the player stuck on a frozen, paused game
		# forever waiting on a callback that's never coming.
		var wrapped := _first_to_fire([finish_reward, finish_no_reward], finish_no_reward)
		GPX.rewardAd(wrapped[0], wrapped[1])
		return
	# GDScript lambdas capture locals BY VALUE, and re-snapshot them on every
	# separate invocation - a mutation made during one signal emission is
	# NOT visible the next time this same lambda fires. A one-element Array
	# is a reference type, so slot 0 is a real shared mutable cell both
	# across invocations and for the self-disconnect below.
	var got_reward := [false]
	var self_ref := [Callable()]
	self_ref[0] = func(state: String) -> void:
		if state == Bridge.RewardedState.REWARDED:
			got_reward[0] = true
			finish_reward.call()
		elif state == Bridge.RewardedState.CLOSED or state == Bridge.RewardedState.FAILED:
			Bridge.advertisement.rewarded_state_changed.disconnect(self_ref[0])
			if not got_reward[0]:
				finish_no_reward.call()
	Bridge.advertisement.rewarded_state_changed.connect(self_ref[0])
	Bridge.advertisement.show_rewarded()
