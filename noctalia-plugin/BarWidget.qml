// BarWidget.qml - status-bar entry for niri-screensaver
//
// Click  → launch the screensaver immediately.
// Right-click → context menu: Trigger / Stop / Open Settings / Toggle enabled.
//
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

NIconButton {
  id: root
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  baseSize: Style.getCapsuleHeightForScreen(screen?.name)
  applyUiScale: false
  icon: "moon"
  tooltipText: pluginApi?.tr("barwidget.tooltip")
  tooltipDirection: BarService.getTooltipDirection(screen?.name)
  customRadius: Style.radiusL

  colorBg: Style.capsuleColor
  colorFg: Color.mOnSurface
  colorBgHover: Color.mHover
  colorFgHover: Color.mOnHover

  Process { id: launchProc }
  Process { id: killProc }

  NPopupContextMenu {
    id: contextMenu
    model: [
      { "label": pluginApi?.tr("barwidget.trigger"),  "action": "trigger",  "icon": "player-play" },
      { "label": pluginApi?.tr("barwidget.stop"),     "action": "stop",     "icon": "stop" },
      { "label": pluginApi?.tr("barwidget.toggle"),   "action": "toggle",   "icon": "power" },
      { "label": pluginApi?.tr("barwidget.settings"), "action": "settings", "icon": "settings" }
    ]
    onTriggered: action => {
      contextMenu.close()
      PanelService.closeContextMenu(screen)

      if (action === "trigger") {
        launchProc.command = ["sh", "-c", root.pluginApi?.pluginSettings?.launcherCommand || "niri-screensaver-launch launch"]
        launchProc.running = true
      } else if (action === "stop") {
        killProc.command = ["sh", "-c", root.pluginApi?.pluginSettings?.killCommand || "niri-screensaver-launch kill"]
        killProc.running = true
      } else if (action === "toggle") {
        if (root.pluginApi) {
          var en = root.pluginApi.pluginSettings.enabled === true
          root.pluginApi.pluginSettings.enabled = !en
          root.pluginApi.saveSettings()
        }
      } else if (action === "settings") {
        if (root.pluginApi) {
          BarService.openPluginSettings(screen, root.pluginApi.manifest)
        }
      }
    }
  }

  onClicked: {
    launchProc.command = ["sh", "-c", root.pluginApi?.pluginSettings?.launcherCommand || "niri-screensaver-launch launch"]
    launchProc.running = true
  }

  onRightClicked: {
    PanelService.showContextMenu(contextMenu, root, screen)
  }
}
