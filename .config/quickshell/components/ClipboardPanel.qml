import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: clipboardPanel
    visible: root.clipboardVisible
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    focusable: true
    WlrLayershell.keyboardFocus: root.clipboardVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None


    property var entries: []
    property var pendingImageIds: []
    property string searchTerm: ""
    property int selectedIndex: 0
    readonly property string tmpDir: "/tmp/qs_clipboard"

    property var filteredEntries: {
        if (searchTerm === "") return entries
        var term = searchTerm.toLowerCase()
        return entries.filter(function(e) {
            return e.preview.toLowerCase().includes(term)
        })
    }

    function isImageEntry(preview) {
        return preview.indexOf("[[ binary data") !== -1
    }

    function loadEntries() {
        clipboardPanel.entries = []
        clipboardPanel.pendingImageIds = []
        clipboardPanel.selectedIndex = 0
        if (!listProc.running) listProc.running = true
    }

    function copyEntry(entry) {
        copyProc.command = ["bash", "-c",
            "printf '%s\\t%s' '" + entry.id + "' '" + entry.preview.replace(/'/g, "'\\''") + "' | cliphist decode | wl-copy"
        ]
        copyProc.running = true
        root.clipboardVisible = false
    }

    function deleteEntry(entry) {
        deleteProc.command = ["bash", "-c",
            "printf '%s\\t%s' '" + entry.id + "' '" + entry.preview.replace(/'/g, "'\\''") + "' | cliphist delete"
        ]
        deleteProc.running = true
        var updated = entries.filter(function(e) { return e.id !== entry.id })
        clipboardPanel.entries = updated
        clipboardPanel.selectedIndex = Math.min(selectedIndex, Math.max(0, updated.length - 1))
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = ""
            clipboardPanel.searchTerm = ""
            clipboardPanel.selectedIndex = 0
            if (clipboardPanel.entries.length === 0)
                mkdirProc.running = true
            focusTimer.start()
        }
    }


    Process {
        id: mkdirProc
        command: ["mkdir", "-p", clipboardPanel.tmpDir]
        onExited: clipboardPanel.loadEntries()
    }

    Process {
        id: listProc
        // last 100 entries
        command: ["bash", "-c", "cliphist list | head -n 100"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var tabIdx = line.indexOf("\t")
                if (tabIdx === -1) return
                var id = line.substring(0, tabIdx)
                var preview = line.substring(tabIdx + 1)
                var isImg = clipboardPanel.isImageEntry(preview)
                var current = clipboardPanel.entries.slice()
                current.push({
                    id: id,
                    preview: preview,
                    isImage: isImg,
                    tmpFile: isImg ? clipboardPanel.tmpDir + "/" + id + ".png" : ""
                })
                clipboardPanel.entries = current
                // batch load images in parallel at end
                if (isImg) {
                    var pending = clipboardPanel.pendingImageIds.slice()
                    pending.push({ id: id, preview: preview })
                    clipboardPanel.pendingImageIds = pending
                }
            }
        }
        onExited: {
            // generate all previews in parallel, not one by one
            if (clipboardPanel.pendingImageIds.length > 0) {
                var script = "mkdir -p '" + clipboardPanel.tmpDir + "'\n"
                for (var i = 0; i < clipboardPanel.pendingImageIds.length; i++) {
                    var e = clipboardPanel.pendingImageIds[i]
                    var f = clipboardPanel.tmpDir + "/" + e.id + ".png"
                    var safePreview = e.preview.replace(/\\/g, "\\\\").replace(/'/g, "'\\''")
                    script += "[ -f '" + f + "' ] || printf '%s\\t%s' '" + e.id + "' '" + safePreview + "' | cliphist decode > '" + f + "' 2>/dev/null &\n"
                }
                script += "wait\n"
                previewProc.command = ["bash", "-c", script]
                previewProc.running = true
            }
        }
    }

    Process { id: previewProc }
    Process { id: copyProc }
    Process { id: deleteProc }

    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: {
            clipboardPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
            releaseFocusTimer.start()
        }
    }

    Timer {
        id: releaseFocusTimer
        interval: 100
        repeat: false
        onTriggered: {
            searchInput.forceActiveFocus()
            clipboardPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
        }
    }


    MouseArea {
        anchors.fill: parent
        onClicked: root.clipboardVisible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 480
        height: Math.min(580, parent.height - 80)
        color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.45)
        radius: 20

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: Qt.rgba(0, 0, 0, 0.15)
                radius: 12
                border.width: searchInput.activeFocus ? 1 : 0
                border.color: root.walColor5

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: ""
                        color: root.walColor8
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: root.walForeground
                        font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        clip: true

                        Text {
                            text: "Search clipboard..."
                            color: root.walColor8
                            visible: !parent.text
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            font: parent.font
                            opacity: 0.6
                        }

                        onTextChanged: {
                            clipboardPanel.searchTerm = text.toLowerCase()
                            clipboardPanel.selectedIndex = 0
                            listView.contentY = 0
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Down) {
                                clipboardPanel.selectedIndex = Math.min(
                                    clipboardPanel.selectedIndex + 1,
                                    clipboardPanel.filteredEntries.length - 1)
                                listView.positionViewAtIndex(clipboardPanel.selectedIndex, ListView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                clipboardPanel.selectedIndex = Math.max(
                                    clipboardPanel.selectedIndex - 1, 0)
                                listView.positionViewAtIndex(clipboardPanel.selectedIndex, ListView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (clipboardPanel.filteredEntries.length > 0)
                                    clipboardPanel.copyEntry(clipboardPanel.filteredEntries[clipboardPanel.selectedIndex])
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                root.clipboardVisible = false
                                event.accepted = true
                            } else if (event.key === Qt.Key_Delete) {
                                if (clipboardPanel.filteredEntries.length > 0)
                                    clipboardPanel.deleteEntry(clipboardPanel.filteredEntries[clipboardPanel.selectedIndex])
                                event.accepted = true
                            }
                        }
                    }

                    Text {
                        visible: clipboardPanel.entries.length > 0
                        text: clipboardPanel.filteredEntries.length + ""
                        color: root.walColor8
                        font.pixelSize: 10
                        font.family: "JetBrainsMono Nerd Font"
                        opacity: 0.5
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.rgba(0, 0, 0, 0.15)
                radius: 14
                clip: true

                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 3
                    boundsBehavior: Flickable.StopAtBounds
                    model: clipboardPanel.filteredEntries
                    cacheBuffer: 400

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onWheel: function(wheel) {
                            listView.contentY = Math.max(0,
                                Math.min(listView.contentY - wheel.angleDelta.y * 0.5,
                                         Math.max(0, listView.contentHeight - listView.height)))
                        }
                        onClicked: mouse.accepted = false
                        onPressed: mouse.accepted = false
                        onReleased: mouse.accepted = false
                    }

                    delegate: Rectangle {
                        id: delegateItem
                        width: listView.width
                        height: modelData.isImage ? 100 : 44
                        radius: 10
                        color: index === clipboardPanel.selectedIndex
                            ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2)
                            : itemMa.containsMouse
                                ? Qt.rgba(1, 1, 1, 0.05)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            visible: index === clipboardPanel.selectedIndex
                            width: 3
                            height: modelData.isImage ? 36 : 20
                            radius: 2
                            color: root.walColor5
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 10
                            anchors.topMargin: 6
                            anchors.bottomMargin: 6
                            spacing: 10

                            Rectangle {
                                visible: modelData.isImage
                                Layout.preferredWidth: 130
                                Layout.fillHeight: true
                                color: Qt.rgba(0, 0, 0, 0.2)
                                radius: 8
                                clip: true

                                Image {
                                    id: thumbImg
                                    anchors.fill: parent
                                    source: modelData.isImage ? "file://" + modelData.tmpFile : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    smooth: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰋩"
                                    color: root.walColor8
                                    font.pixelSize: 20
                                    font.family: "JetBrainsMono Nerd Font"
                                    opacity: 0.3
                                    visible: thumbImg.status !== Image.Ready
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 3

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.isImage ? "Image" : modelData.preview
                                    color: index === clipboardPanel.selectedIndex
                                        ? root.walColor5
                                        : root.walForeground
                                    font.pixelSize: 12
                                    font.bold: index === clipboardPanel.selectedIndex
                                    font.family: "JetBrainsMono Nerd Font"
                                    elide: Text.ElideRight
                                    maximumLineCount: modelData.isImage ? 1 : 3
                                    wrapMode: modelData.isImage ? Text.NoWrap : Text.Wrap
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                Text {
                                    visible: modelData.isImage
                                    Layout.fillWidth: true
                                    text: modelData.preview.replace("[[ binary data ", "").replace(" ]]", "")
                                    color: root.walColor8
                                    font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                    opacity: 0.6
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 6
                                color: deleteMa.containsMouse
                                    ? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.3)
                                    : "transparent"
                                visible: itemMa.containsMouse || index === clipboardPanel.selectedIndex
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: deleteMa.containsMouse ? root.walColor1 : root.walColor8
                                    font.pixelSize: 11
                                    font.family: "JetBrainsMono Nerd Font"
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                MouseArea {
                                    id: deleteMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: clipboardPanel.deleteEntry(modelData)
                                }
                            }
                        }

                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clipboardPanel.copyEntry(modelData)
                            onContainsMouseChanged: {
                                if (containsMouse) clipboardPanel.selectedIndex = index
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        width: 4
                        policy: ScrollBar.AsNeeded
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: clipboardPanel.filteredEntries.length === 0 && clipboardPanel.entries.length === 0
                    text: "Loading..."
                    color: root.walColor8
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    opacity: 0.5
                }

                Text {
                    anchors.centerIn: parent
                    visible: clipboardPanel.filteredEntries.length === 0 && clipboardPanel.entries.length > 0
                    text: "No results"
                    color: root.walColor8
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    opacity: 0.5
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                color: Qt.rgba(0, 0, 0, 0.15)
                radius: 10

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Text { text: "↑↓ nav"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.6 }
                    Item { Layout.fillWidth: true }
                    Text { text: "↵ copy"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.6 }
                    Item { Layout.fillWidth: true }
                    Text { text: "del delete"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.6 }
                    Item { Layout.fillWidth: true }
                    Text { text: "esc close"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.6 }
                }
            }
        }
    }
}