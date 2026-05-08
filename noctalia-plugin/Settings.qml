// Settings.qml - niri-screensaver plugin settings tab
//
// Renders inside Noctalia's Settings panel. Uses Noctalia's NBox/NText/NToggle
// widgets so it matches the rest of the shell visually. Form fields write
// straight into pluginApi.pluginSettings; Main.qml's Connections block picks
// the change up and re-syncs the shell config + idle hook.
//
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: rootItem
  property var pluginApi: null
  implicitWidth: 600
  implicitHeight: layout.implicitHeight
  width: Math.max(600, parent ? parent.width : 0)

  property var cfg: rootItem.pluginApi?.pluginSettings || ({})
  property var defaults: rootItem.pluginApi?.manifest?.metadata?.defaultSettings || ({})

  function tr(k) { return rootItem.pluginApi?.tr(k) || k }

  ColumnLayout {
    id: layout
    width: parent.width
    spacing: Style.marginM

    NText {
      Layout.fillWidth: true
      text: rootItem.tr("settings.title")
      pointSize: Style.fontSizeXXL
      font.weight: Style.fontWeightBold
      color: Color.mOnSurface
    }
    NText {
      Layout.fillWidth: true
      text: rootItem.tr("settings.description")
      color: Color.mOnSurfaceVariant
      pointSize: Style.fontSizeM
      wrapMode: Text.WordWrap
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
        spacing: Style.marginS

        NText {
          text: rootItem.tr("settings.idle-section")
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        RowLayout {
          spacing: Style.marginM
          NText {
            text: rootItem.tr("settings.enabled")
            color: Color.mOnSurface
            Layout.preferredWidth: 200
          }
          NToggle {
            checked: rootItem.cfg.enabled === true
            onToggled: {
              rootItem.cfg.enabled = checked
              rootItem.pluginApi.saveSettings()
            }
          }
        }

        RowLayout {
          spacing: Style.marginM
          NText {
            text: rootItem.tr("settings.idle-seconds")
            color: Color.mOnSurface
            Layout.preferredWidth: 200
          }
          SpinBox {
            from: 30
            to: 7200
            stepSize: 30
            value: parseInt(rootItem.cfg.idleSeconds) || rootItem.defaults.idleSeconds || 300
            onValueChanged: {
              rootItem.cfg.idleSeconds = value
              rootItem.pluginApi.saveSettings()
            }
          }
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
        spacing: Style.marginS

        NText {
          text: rootItem.tr("settings.effects-section")
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        RowLayout {
          spacing: Style.marginM
          NText {
            text: rootItem.tr("settings.include-effects")
            Layout.preferredWidth: 200
          }
          TextField {
            Layout.fillWidth: true
            text: rootItem.cfg.includeEffects || ""
            placeholderText: "blackhole,matrix,rain"
            onEditingFinished: {
              rootItem.cfg.includeEffects = text
              rootItem.pluginApi.saveSettings()
            }
          }
        }

        RowLayout {
          spacing: Style.marginM
          NText {
            text: rootItem.tr("settings.exclude-effects")
            Layout.preferredWidth: 200
          }
          TextField {
            Layout.fillWidth: true
            text: rootItem.cfg.excludeEffects || ""
            placeholderText: "dev_worm"
            onEditingFinished: {
              rootItem.cfg.excludeEffects = text
              rootItem.pluginApi.saveSettings()
            }
          }
        }

        RowLayout {
          spacing: Style.marginM
          NText {
            text: rootItem.tr("settings.fade-in")
            Layout.preferredWidth: 200
          }
          TextField {
            Layout.fillWidth: true
            text: rootItem.cfg.fadeInEffect || ""
            placeholderText: "expand | slide | middleout"
            onEditingFinished: {
              rootItem.cfg.fadeInEffect = text
              rootItem.pluginApi.saveSettings()
            }
          }
        }

        RowLayout {
          spacing: Style.marginM
          NText {
            text: rootItem.tr("settings.fade-out")
            Layout.preferredWidth: 200
          }
          TextField {
            Layout.fillWidth: true
            text: rootItem.cfg.fadeOutEffect || ""
            placeholderText: "burn | crumble | scattered"
            onEditingFinished: {
              rootItem.cfg.fadeOutEffect = text
              rootItem.pluginApi.saveSettings()
            }
          }
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
        spacing: Style.marginS

        NText {
          text: rootItem.tr("settings.logo-section")
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        RowLayout {
          spacing: Style.marginM
          NText { text: rootItem.tr("settings.random-logo"); Layout.preferredWidth: 200 }
          NToggle {
            checked: rootItem.cfg.randomLogo === true
            onToggled: {
              rootItem.cfg.randomLogo = checked
              rootItem.pluginApi.saveSettings()
            }
          }
        }

        RowLayout {
          spacing: Style.marginM
          NText { text: rootItem.tr("settings.logo-dir"); Layout.preferredWidth: 200 }
          TextField {
            Layout.fillWidth: true
            text: rootItem.cfg.logoDir || ""
            placeholderText: "~/.local/share/niri-screensaver/logos"
            onEditingFinished: {
              rootItem.cfg.logoDir = text
              rootItem.pluginApi.saveSettings()
            }
          }
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
        spacing: Style.marginS

        NText {
          text: rootItem.tr("settings.clock-section")
          pointSize: Style.fontSizeL
          font.weight: Style.fontWeightBold
          color: Color.mOnSurface
        }

        RowLayout {
          spacing: Style.marginM
          NText { text: rootItem.tr("settings.show-clock"); Layout.preferredWidth: 200 }
          NToggle {
            checked: rootItem.cfg.showClock === true
            onToggled: {
              rootItem.cfg.showClock = checked
              rootItem.pluginApi.saveSettings()
            }
          }
        }

        RowLayout {
          spacing: Style.marginM
          NText { text: rootItem.tr("settings.clock-format"); Layout.preferredWidth: 200 }
          TextField {
            Layout.fillWidth: true
            text: rootItem.cfg.clockFormat || "%H:%M"
            onEditingFinished: {
              rootItem.cfg.clockFormat = text
              rootItem.pluginApi.saveSettings()
            }
          }
        }
      }
    }

    // ----- Manual trigger -----
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      Button {
        text: rootItem.tr("settings.trigger-now")
        onClicked: triggerNowProcess.running = true
      }
      Button {
        text: rootItem.tr("settings.stop")
        onClicked: stopNowProcess.running = true
      }
    }

    Process { id: triggerNowProcess; command: ["sh", "-c", rootItem.cfg.launcherCommand || "niri-screensaver-launch launch"] }
    Process { id: stopNowProcess;    command: ["sh", "-c", rootItem.cfg.killCommand || "niri-screensaver-launch kill"] }
  }
}
