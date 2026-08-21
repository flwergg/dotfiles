import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: musicPanel
    property bool panelOpen: false
    visible: panelOpen
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; right: true }
    margins { top: 50; left: 0; right: 0 }
    implicitWidth: 400
    implicitHeight: 188
    color: "transparent"
    focusable: true
    WlrLayershell.keyboardFocus: root.musicVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property string configPath: root.configPath
    property string gifPath: configPath + "/assets/gifs"
    readonly property string playerStatus: root.mediaStatus
    readonly property string trackTitle: root.mediaTitle
    readonly property string trackArtist: root.mediaArtist
    readonly property real position: root.mediaPosition
    readonly property real length: root.mediaLength
    property bool hasTrack: playerStatus === "Playing" || playerStatus === "Paused"
    property string gifSource: "file://" + gifPath + "/nyancat.gif"
    property var cavaValues: []
    property int cavaBars: 24

    function formatTime(seconds) {
        var mins = Math.floor(seconds / 60)
        var secs = Math.floor(seconds % 60)
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    Item {
        anchors.fill: parent
        clip: true
        focus: root.musicVisible

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.musicVisible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Space) {
                root.mediaPlayPause()
                event.accepted = true
            } else if (event.key === Qt.Key_N) {
                root.mediaNext()
                event.accepted = true
            } else if (event.key === Qt.Key_P) {
                root.mediaPrevious()
                event.accepted = true
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.musicVisible ? 0 : -height
            spacing: 8
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            Rectangle {
                width: 400
                height: 180
                color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.5)
                radius: 15
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        Text {
                            text: musicPanel.trackTitle || "Nothing is playing"
                            color: root.walColor5
                            font.pixelSize: 15
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: musicPanel.trackArtist || ""
                            color: root.walForeground
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            opacity: 0.7
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            visible: musicPanel.trackArtist !== ""
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 40
                            visible: musicPanel.cavaValues.length > 0

                            Row {
                                anchors.centerIn: parent
                                spacing: 3

                                Repeater {
                                    model: musicPanel.cavaBars
                                    Rectangle {
                                        width: 4
                                        radius: 2
                                        height: Math.max(3, (musicPanel.cavaValues[index] || 0) * 30)
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: root.walColor5
                                        antialiasing: true
                                        Behavior on height { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            visible: musicPanel.hasTrack

                            Text {
                                text: musicPanel.formatTime(musicPanel.position)
                                color: root.walColor8
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: Qt.rgba(0, 0, 0, 0.3)

                                Rectangle {
                                    width: musicPanel.length > 0 ? parent.width * (musicPanel.position / musicPanel.length) : 0
                                    height: parent.height
                                    radius: 2
                                    color: root.walColor5
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        if (musicPanel.length > 0 && !seekProc.running) {
                                            var seekPos = (mouse.x / parent.width) * musicPanel.length
                                            seekProc.command = ["playerctl", "position", seekPos.toString()]
                                            seekProc.running = true
                                        }
                                    }
                                }
                            }

                            Text {
                                text: musicPanel.formatTime(musicPanel.length)
                                color: root.walColor8
                                font.pixelSize: 10
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }

                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12
                            opacity: musicPanel.hasTrack ? 1.0 : 0.5

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: prevMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒮"
                                    color: root.walForeground
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                MouseArea {
                                    id: prevMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.mediaPrevious()
                                }
                            }

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: root.walColor5

                                Text {
                                    anchors.centerIn: parent
                                    text: musicPanel.playerStatus === "Playing" ? "󰏤" : "󰐊"
                                    color: root.walBackground
                                    font.pixelSize: 18
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.mediaPlayPause()
                                }
                            }

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 8
                                color: nextMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒭"
                                    color: root.walForeground
                                    font.pixelSize: 16
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                MouseArea {
                                    id: nextMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.mediaNext()
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 160
                        Layout.alignment: Qt.AlignBottom

                        Item {
                            id: gifContainer
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 200
                            height: 160

                            Loader {
                                id: danceGifLoader
                                anchors.fill: parent
                                active: root.musicVisible
                                sourceComponent: AnimatedImage {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    source: musicPanel.gifSource
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    playing: musicPanel.playerStatus === "Playing"
                                    paused: musicPanel.playerStatus !== "Playing"
                                    cache: false
                                    asynchronous: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: root
        function onMusicVisibleChanged() {
            if (root.musicVisible) {
                closeTimer.stop()
                musicPanel.panelOpen = true
                focusTimer.start()
            } else {
                closeTimer.restart()
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 320
        repeat: false
        onTriggered: musicPanel.panelOpen = false
    }

    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: {
            musicPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
            releaseTimer.start()
        }
    }

    Timer {
        id: releaseTimer
        interval: 100
        repeat: false
        onTriggered: {
            musicPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
        }
    }

    Process {
    id: panelCavaProc
    running: root.musicVisible && musicPanel.playerStatus === "Playing"
    command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/config_raw"]
    stdout: SplitParser {
        onRead: data => {
            var parts = data.trim().split(";")
            var vals = []
            for (var i = 0; i < musicPanel.cavaBars && i < parts.length; i++)
                vals.push(parseInt(parts[i]) / 255)
            while (vals.length < musicPanel.cavaBars) vals.push(0)
            musicPanel.cavaValues = vals
        }
    }
}

Timer {
    interval: 80
    running: root.musicVisible && musicPanel.playerStatus !== "Playing"
    repeat: true
    onTriggered: {
        var newVals = []
        for (var i = 0; i < musicPanel.cavaBars; i++)
            newVals.push((musicPanel.cavaValues[i] || 0) * 0.85)
        musicPanel.cavaValues = newVals
    }
}

    Process {
        id: seekProc
        command: ["playerctl", "position", "0"]
    }
}