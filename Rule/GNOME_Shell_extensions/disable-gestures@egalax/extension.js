/**
 * Disable Gestures
 *
 * Gnome extension that disables the built in gestures. Useful for kiosks and touch screen apps where they may interfere.
 *
 * Matt Bell 2016
 * Thanks to Stackoverflow question #36896556 kepler_kingsnake
 */

// When the extension is enabled, disable the gestures
function enable() {
	global.stage.get_actions().forEach(a => a.enabled = false);
}

// When the extension is disabled, enable the gestures
function disable() {
	global.stage.get_actions().forEach(a => a.enabled = true);
}
