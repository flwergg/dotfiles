import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: osdPanel
    visible: root.osdVisible
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-osd"

    anchors { right: true; top: true; bottom: true }
    implicitWidth: 70

    property real brightnessValue: 0
    property real maxBrightness: 1
    property bool brightnessReady: false

    FileView {
        id: brightnessFile
        path: ""
        watchChanges: true
        onFileChanged: brightnessReadProc.running = true
    }

    Process {
        id: backlightDiscovery
        command: ["sh", "-c", "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.startsWith("/")) {
                    brightnessFile.path = line
                } else {
                    var max = parseInt(line)
                    if (!isNaN(max) && max > 0) osdPanel.maxBrightness = max
                    brightnessReadProc.running = true
                }
            }
        }
    }

    Process {
        id: brightnessReadProc
        command: ["brightnessctl", "get"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.trim())
                if (!isNaN(val) && osdPanel.maxBrightness > 0) {
                    osdPanel.brightnessValue = val / osdPanel.maxBrightness
                    if (osdPanel.brightnessReady) {
                        root.osdType = "brightness"
                        root.osdVisible = true
                        osdHideTimer.restart()
                    }
                    osdPanel.brightnessReady = true
                }
            }
        }
    }


    property real volumeValue: 0
    property bool volumeMuted: false

    Process {
        id: volumeReadProc
        command: ["bash", "-c", "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); muted=$(echo \"$vol\" | grep -q MUTED && echo 1 || echo 0); pct=$(echo \"$vol\" | awk '{printf \"%.2f\", $2}'); echo \"$pct|$muted\""]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|")
                osdPanel.volumeValue = parseFloat(parts[0]) || 0
                osdPanel.volumeMuted = parts[1] === "1"
                root.osdType = "volume"
                root.osdVisible = true
                osdHideTimer.restart()
            }
        }
    }


    Timer {
        id: osdHideTimer
        interval: 1800
        onTriggered: root.osdVisible = false
    }


    IpcHandler {
        target: "osd"
        function volume() {
            if (!volumeReadProc.running) volumeReadProc.running = true
        }
        function brightness() {
            if (!brightnessReadProc.running) brightnessReadProc.running = true
        }
    }

    Column {
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 200
            radius: 18
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.85)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            opacity: root.osdVisible && root.osdType === "volume" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: osdPanel.volumeMuted ? "0%" : Math.round(osdPanel.volumeValue * 100) + "%"
                    color: root.walForeground
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter
                    width: 8
                    radius: 4
                    color: Qt.rgba(0, 0, 0, 0.3)
                    clip: true

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Math.max(0, parent.height * Math.min(1, osdPanel.volumeMuted ? 0 : osdPanel.volumeValue))
                        radius: 4
                        color: root.walColor5
                        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (osdPanel.volumeMuted || osdPanel.volumeValue <= 0) return "󰖁"
                        if (osdPanel.volumeValue < 0.33) return "󰕿"
                        if (osdPanel.volumeValue < 0.66) return "󰖀"
                        return "󰕾"
                    }
                    color: osdPanel.volumeMuted ? root.walColor8 : root.walColor5
                    font.pixelSize: 15
                    font.family: "JetBrainsMono Nerd Font"
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    var pct = Math.max(0, Math.min(1, 1.0 - (mouse.y / parent.height)))
                    volSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct.toFixed(2)]
                    volSetProc.running = true
                }
                onWheel: function(wheel) {
                    var delta = wheel.angleDelta.y > 0 ? "1%+" : "1%-"
                    volSetProc.command = ["bash", "-c", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " + delta]
                    volSetProc.running = true
                }
            }

            Process {
                id: volSetProc
                onExited: { if (!volumeReadProc.running) volumeReadProc.running = true }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 200
            radius: 18
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.85)
            border.color: Qt.rgba(1, 1, 1, 0.1)
            border.width: 1
            opacity: root.osdVisible && root.osdType === "brightness" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(osdPanel.brightnessValue * 100) + "%"
                    color: root.walForeground
                    font.pixelSize: 10
                    font.family: "JetBrainsMono Nerd Font"
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter
                    width: 8
                    radius: 4
                    color: Qt.rgba(0, 0, 0, 0.3)
                    clip: true

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Math.max(0, parent.height * Math.min(1, osdPanel.brightnessValue))
                        radius: 4
                        color: root.walColor4
                        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (osdPanel.brightnessValue < 0.33) return "󰃞"
                        if (osdPanel.brightnessValue < 0.66) return "󰃟"
                        return "󰃠"
                    }
                    color: root.walColor4
                    font.pixelSize: 15
                    font.family: "JetBrainsMono Nerd Font"
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                    var pct = Math.max(1, Math.round((1.0 - (mouse.y / parent.height)) * 100))
                    brightSetProc.command = ["brightnessctl", "set", pct + "%"]
                    brightSetProc.running = true
                }
                onWheel: function(wheel) {
                    var delta = wheel.angleDelta.y > 0 ? "1%+" : "1%-"
                    brightSetProc.command = ["brightnessctl", "-e4", "-n2", "set", delta]
                    brightSetProc.running = true
                }
            }

            Process {
                id: brightSetProc
                onExited: { if (!brightnessReadProc.running) brightnessReadProc.running = true }
            }
        }
    }
}
