// Main.qml - niri-screensaver Noctalia plugin runtime
//
// Responsibilities:
//   1. Persist plugin settings to ~/.config/niri-screensaver/config (shell KEY="value" format)
//      so the script-side driver picks them up.
//   2. Auto-register / deregister a screensaver entry in Noctalia's
//      Settings.data.idle.customCommands array based on plugin enable state.
//   3. Expose IPC: plugin:niri-screensaver { launch | kill | toggle }
//
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root
  property var pluginApi: null

  // Identifier used to find / remove our entry in Noctalia's idle.customCommands
  readonly property string entryName: "Niri Screensaver"

  // ----- File paths -----
  readonly property string configDir: Quickshell.env("HOME") + "/.config/niri-screensaver"
  readonly property string configFile: configDir + "/config"

  // ----- Lifecycle -----
  Component.onCompleted: {
    if (pluginApi) {
      _syncAll()
    }
  }
  onPluginApiChanged: {
    if (pluginApi) {
      _syncAll()
    }
  }

  // Re-sync whenever any plugin setting changes
  Connections {
    target: pluginApi ? pluginApi.pluginSettings : null
    enabled: pluginApi !== null
    function onAnyChanged() { root._syncAll() }
    function onEnabledChanged() { root._syncAll() }
    function onIdleSecondsChanged() { root._syncAll() }
  }

  function _syncAll() {
    _writeShellConfig()
    _syncIdleEntry()
    _syncHooks()
  }

  // ----- Shell config writer -----
  function _shEscape(s) {
    if (s === undefined || s === null) return ""
    return String(s).replace(/"/g, '\\"')
  }

  function _renderShellConfig() {
    var s = pluginApi.pluginSettings
    var bool = function (b) { return b ? "true" : "false" }
    return [
      "# niri-screensaver config (managed by Noctalia plugin)",
      "FRAME_RATE=\"" + (s.frameRate || 60) + "\"",
      "INCLUDE_EFFECTS=\"" + _shEscape(s.includeEffects) + "\"",
      "EXCLUDE_EFFECTS=\"" + _shEscape(s.excludeEffects) + "\"",
      "FADE_IN_EFFECT=\"" + _shEscape(s.fadeInEffect) + "\"",
      "FADE_OUT_EFFECT=\"" + _shEscape(s.fadeOutEffect) + "\"",
      "SHOW_CLOCK=\"" + bool(s.showClock) + "\"",
      "CLOCK_DURATION=\"" + (s.clockDuration || 3) + "\"",
      "CLOCK_FORMAT=\"" + _shEscape(s.clockFormat) + "\"",
      "CLOCK_FONT=\"" + _shEscape(s.clockFont) + "\"",
      "LOGO_FILE=\"" + _shEscape(s.logoPath) + "\"",
      "CURSOR_HIDE=\"" + bool(s.cursorHide) + "\"",
      "DISMISS_ON_KEY=\"" + bool(s.dismissOnKey) + "\"",
      ""
    ].join("\n")
  }

  Process {
    id: writeConfigProcess
    running: false
  }

  function _writeShellConfig() {
    var content = _renderShellConfig()
    // mkdir -p && write atomically via tee
    writeConfigProcess.command = ["sh", "-c",
      "mkdir -p \"" + configDir + "\" && cat > \"" + configFile + "\" << '__NIRI_SS_EOF__'\n" + content + "__NIRI_SS_EOF__\n"
    ]
    writeConfigProcess.running = true
  }

  // ----- Noctalia idle wiring -----
  function _syncIdleEntry() {
    if (!pluginApi) return
    var raw = ""
    try {
      raw = Settings.data.idle.customCommands || "[]"
    } catch (e) { return }

    var arr = []
    try { arr = JSON.parse(raw) } catch (e) { arr = [] }

    // Remove any existing entry of ours
    arr = arr.filter(function (e) { return e && e.name !== root.entryName })

    if (pluginApi.pluginSettings.enabled) {
      arr.push({
        name: root.entryName,
        timeout: parseInt(pluginApi.pluginSettings.idleSeconds) || 300,
        command: pluginApi.pluginSettings.launcherCommand || "niri-screensaver-launch launch",
        resumeCommand: pluginApi.pluginSettings.killCommand || "niri-screensaver-launch kill"
      })
    }
    Settings.data.idle.customCommands = JSON.stringify(arr)
  }

  // ----- Noctalia Hooks wiring (screenLock / screenUnlock) -----
  //
  // Only write to a hook slot if it's currently empty OR already holds our
  // command. That way we never clobber a hook the user authored manually.
  // On disable we mirror the same rule: only clear if the value is still ours.
  // Requires Settings.data.hooks.enabled = true to actually fire — the plugin
  // does not flip that master toggle for the user.
  function _hookKillCmd() {
    return pluginApi?.pluginSettings?.killCommand || "niri-screensaver-launch kill"
  }

  function _syncHooks() {
    if (!pluginApi) return
    if (!Settings.data.hooks) return  // Older Noctalia builds may lack hooks

    var killCmd = _hookKillCmd()
    var lockNow   = Settings.data.hooks.screenLock || ""
    var unlockNow = Settings.data.hooks.screenUnlock || ""

    if (pluginApi.pluginSettings.enabled) {
      if (lockNow === "" || lockNow === killCmd) {
        Settings.data.hooks.screenLock = killCmd
      }
      if (unlockNow === "" || unlockNow === killCmd) {
        Settings.data.hooks.screenUnlock = killCmd
      }
    } else {
      if (lockNow === killCmd)   Settings.data.hooks.screenLock = ""
      if (unlockNow === killCmd) Settings.data.hooks.screenUnlock = ""
    }

    if (typeof Settings.saveImmediate === "function") {
      Settings.saveImmediate()
    }
  }

  // ----- IPC handlers -----
  IpcHandler {
    target: "plugin:niri-screensaver"

    function launch() { triggerProcess.command = ["sh", "-c", root.pluginApi?.pluginSettings?.launcherCommand || "niri-screensaver-launch launch"]; triggerProcess.running = true }
    function kill()   { triggerProcess.command = ["sh", "-c", root.pluginApi?.pluginSettings?.killCommand || "niri-screensaver-launch kill"]; triggerProcess.running = true }
    function toggle() {
      var enabled = root.pluginApi?.pluginSettings?.enabled === true
      root.pluginApi.pluginSettings.enabled = !enabled
      root.pluginApi.saveSettings()
    }
  }

  Process {
    id: triggerProcess
    running: false
  }

  // ----- Cleanup on plugin disable -----
  Component.onDestruction: {
    if (pluginApi) {
      // Best-effort: remove our customCommands entry so we don't leave a dangling hook
      try {
        var arr = JSON.parse(Settings.data.idle.customCommands || "[]")
        arr = arr.filter(function (e) { return e && e.name !== root.entryName })
        Settings.data.idle.customCommands = JSON.stringify(arr)
      } catch (e) { /* ignore */ }

      // Mirror cleanup for hook slots — only clear values we wrote
      try {
        var killCmd = _hookKillCmd()
        if (Settings.data.hooks) {
          if (Settings.data.hooks.screenLock === killCmd)   Settings.data.hooks.screenLock = ""
          if (Settings.data.hooks.screenUnlock === killCmd) Settings.data.hooks.screenUnlock = ""
        }
      } catch (e) { /* ignore */ }
    }
  }
}
