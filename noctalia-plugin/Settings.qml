// Settings.qml - niri-screensaver plugin settings tab
//
// Edit-copy pattern: form fields write to local `edit*` properties; the shell
// calls saveSettings() when the user clicks Apply, at which point we copy the
// edit values back into pluginApi.pluginSettings and call saveSettings() on
// the plugin API. This matches the noctalia-plugins AGENTS.md convention.
//
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
  id: root
  property var pluginApi: null
  spacing: Style.marginL

  // ----- Settings access (cfg → defaults → hardcoded) -----
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // ----- Edit-copy properties -----
  property bool   editEnabled:        cfg.enabled        ?? defaults.enabled        ?? true
  property int    editIdleSeconds:    parseInt(cfg.idleSeconds   ?? defaults.idleSeconds   ?? 300)
  property string editIncludeEffects: cfg.includeEffects ?? defaults.includeEffects ?? ""
  property string editExcludeEffects: cfg.excludeEffects ?? defaults.excludeEffects ?? "dev_worm"
  property string editFadeInEffect:   cfg.fadeInEffect   ?? defaults.fadeInEffect   ?? ""
  property string editFadeOutEffect:  cfg.fadeOutEffect  ?? defaults.fadeOutEffect  ?? ""
  property bool   editRandomLogo:     cfg.randomLogo     ?? defaults.randomLogo     ?? false
  property string editLogoDir:        cfg.logoDir        ?? defaults.logoDir        ?? ""
  property bool   editShowClock:      cfg.showClock      ?? defaults.showClock      ?? false
  property string editClockFormat:    cfg.clockFormat    ?? defaults.clockFormat    ?? "%H:%M"

  // ----- CLI-missing banner (Main.qml runs detection on startup) -----
  readonly property var mainInstance: pluginApi?.mainInstance || null
  readonly property bool cliMissing: mainInstance && mainInstance.cliAvailable === false

  // ----- Save handler (called by the shell on Apply) -----
  function saveSettings() {
    if (!pluginApi) {
      Logger.e("NiriScreensaver", "saveSettings: pluginApi is null")
      return
    }
    pluginApi.pluginSettings.enabled        = root.editEnabled
    pluginApi.pluginSettings.idleSeconds    = root.editIdleSeconds
    pluginApi.pluginSettings.includeEffects = root.editIncludeEffects
    pluginApi.pluginSettings.excludeEffects = root.editExcludeEffects
    pluginApi.pluginSettings.fadeInEffect   = root.editFadeInEffect
    pluginApi.pluginSettings.fadeOutEffect  = root.editFadeOutEffect
    pluginApi.pluginSettings.randomLogo     = root.editRandomLogo
    pluginApi.pluginSettings.logoDir        = root.editLogoDir
    pluginApi.pluginSettings.showClock      = root.editShowClock
    pluginApi.pluginSettings.clockFormat    = root.editClockFormat
    pluginApi.saveSettings()
    Logger.i("NiriScreensaver", "settings saved")
  }

  // ----- Title -----
  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.title")
    pointSize: Style.fontSizeXXL
    font.weight: Style.fontWeightBold
    color: Color.mOnSurface
  }
  NText {
    Layout.fillWidth: true
    text: pluginApi?.tr("settings.description")
    color: Color.mOnSurfaceVariant
    pointSize: Style.fontSizeM
    wrapMode: Text.WordWrap
  }

  // ----- CLI-missing banner -----
  NBox {
    Layout.fillWidth: true
    visible: root.cliMissing
    color: Color.mError
    Layout.preferredHeight: bannerCol.implicitHeight + Style.marginM * 2

    ColumnLayout {
      id: bannerCol
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginXS
      NText {
        text: pluginApi?.tr("settings.cli-missing.title")
        color: Color.mOnError
        font.weight: Style.fontWeightBold
        pointSize: Style.fontSizeL
      }
      NText {
        text: pluginApi?.tr("settings.cli-missing.desc")
        color: Color.mOnError
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }
  }

  // ----- Idle behavior -----
  NBox {
    Layout.fillWidth: true
    Layout.preferredHeight: idleCol.implicitHeight + Style.marginM * 2
    color: Color.mSurfaceVariant

    ColumnLayout {
      id: idleCol
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("settings.idle-section")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.enabled")
        description: pluginApi?.tr("settings.enabled-desc")
        checked: root.editEnabled
        defaultValue: root.defaults.enabled
        onToggled: checked => root.editEnabled = checked
      }

      NSpinBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.idle-seconds")
        description: pluginApi?.tr("settings.idle-seconds-desc")
        from: 30
        to: 7200
        stepSize: 30
        value: root.editIdleSeconds
        defaultValue: root.defaults.idleSeconds
        onValueChanged: root.editIdleSeconds = value
      }
    }
  }

  // ----- Effects -----
  NBox {
    Layout.fillWidth: true
    Layout.preferredHeight: fxCol.implicitHeight + Style.marginM * 2
    color: Color.mSurfaceVariant

    ColumnLayout {
      id: fxCol
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("settings.effects-section")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.include-effects")
        description: pluginApi?.tr("settings.include-effects-desc")
        placeholderText: pluginApi?.tr("settings.placeholder.include-effects")
        text: root.editIncludeEffects
        defaultValue: root.defaults.includeEffects
        onEditingFinished: root.editIncludeEffects = text
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.exclude-effects")
        description: pluginApi?.tr("settings.exclude-effects-desc")
        placeholderText: pluginApi?.tr("settings.placeholder.exclude-effects")
        text: root.editExcludeEffects
        defaultValue: root.defaults.excludeEffects
        onEditingFinished: root.editExcludeEffects = text
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.fade-in")
        description: pluginApi?.tr("settings.fade-in-desc")
        placeholderText: pluginApi?.tr("settings.placeholder.fade-in")
        text: root.editFadeInEffect
        defaultValue: root.defaults.fadeInEffect
        onEditingFinished: root.editFadeInEffect = text
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.fade-out")
        description: pluginApi?.tr("settings.fade-out-desc")
        placeholderText: pluginApi?.tr("settings.placeholder.fade-out")
        text: root.editFadeOutEffect
        defaultValue: root.defaults.fadeOutEffect
        onEditingFinished: root.editFadeOutEffect = text
      }
    }
  }

  // ----- Logo -----
  NBox {
    Layout.fillWidth: true
    Layout.preferredHeight: logoCol.implicitHeight + Style.marginM * 2
    color: Color.mSurfaceVariant

    ColumnLayout {
      id: logoCol
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("settings.logo-section")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.random-logo")
        description: pluginApi?.tr("settings.random-logo-desc")
        checked: root.editRandomLogo
        defaultValue: root.defaults.randomLogo
        onToggled: checked => root.editRandomLogo = checked
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.logo-dir")
        description: pluginApi?.tr("settings.logo-dir-desc")
        placeholderText: pluginApi?.tr("settings.placeholder.logo-dir")
        text: root.editLogoDir
        defaultValue: root.defaults.logoDir
        onEditingFinished: root.editLogoDir = text
      }
    }
  }

  // ----- Clock -----
  NBox {
    Layout.fillWidth: true
    Layout.preferredHeight: clockCol.implicitHeight + Style.marginM * 2
    color: Color.mSurfaceVariant

    ColumnLayout {
      id: clockCol
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("settings.clock-section")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.show-clock")
        description: pluginApi?.tr("settings.show-clock-desc")
        checked: root.editShowClock
        defaultValue: root.defaults.showClock
        onToggled: checked => root.editShowClock = checked
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.clock-format")
        description: pluginApi?.tr("settings.clock-format-desc")
        text: root.editClockFormat
        defaultValue: root.defaults.clockFormat
        onEditingFinished: root.editClockFormat = text
      }
    }
  }

  // ----- Manual trigger -----
  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NButton {
      text: pluginApi?.tr("settings.trigger-now")
      icon: "player-play"
      onClicked: {
        var argv = root.mainInstance ? root.mainInstance._launcherArgv()
                                     : ["niri-screensaver-launch", "launch"]
        triggerNowProcess.command = argv
        triggerNowProcess.running = true
      }
    }
    NButton {
      text: pluginApi?.tr("settings.stop")
      icon: "stop"
      outlined: true
      onClicked: {
        var argv = root.mainInstance ? root.mainInstance._killArgv()
                                     : ["niri-screensaver-launch", "kill"]
        stopNowProcess.command = argv
        stopNowProcess.running = true
      }
    }
  }

  Process {
    id: triggerNowProcess
    onExited: function (code) {
      if (code !== 0) Logger.w("NiriScreensaver", "trigger (Settings) exited with code", code)
    }
  }
  Process {
    id: stopNowProcess
    onExited: function (code) {
      if (code !== 0) Logger.w("NiriScreensaver", "stop (Settings) exited with code", code)
    }
  }
}
