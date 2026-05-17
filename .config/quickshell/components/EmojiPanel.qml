import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: emojiPanel
    visible: root.emojiVisible
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    focusable: true
    WlrLayershell.keyboardFocus: root.emojiVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property int currentTab: 0
    property string searchTerm: ""
    property int selectedIndex: 0


    FileView {
        id: emojiFile
        path: Quickshell.env("HOME") + "/.config/quickshell/files/emoji.json"
    }

    FileView {
        id: kaomojiFile
        path: Quickshell.env("HOME") + "/.config/quickshell/files/kaomoji.json"
    }

    readonly property var emojiRaw: {
        var t = emojiFile.text()
        if (!t || !t.trim()) return {}
        try { return JSON.parse(t) } catch(e) { return {} }
    }

    readonly property var kaoRaw: {
        var t = kaomojiFile.text()
        if (!t || !t.trim()) return []
        try { return JSON.parse(t) } catch(e) { return [] }
    }

    readonly property var emojiAll: {
        var out = []
        for (var emoji in emojiRaw)
            out.push({ emoji: emoji, name: emojiRaw[emoji].name || "", category: emojiRaw[emoji].group || "" })
        return out
    }

    readonly property var kaoAll: {
        var out = []
        for (var i = 0; i < kaoRaw.length; i++) {
            var group = kaoRaw[i]
            for (var j = 0; j < group.categories.length; j++) {
                var cat = group.categories[j]
                for (var k = 0; k < cat.emoticons.length; k++)
                    out.push({ text: cat.emoticons[k], group: group.name, category: cat.name })
            }
        }
        return out
    }

    readonly property var emojiFiltered: {
        var q = searchTerm.toLowerCase()
        if (!q) return emojiAll
        return emojiAll.filter(function(e) {
            return e.name.toLowerCase().includes(q) ||
                   e.category.toLowerCase().includes(q) ||
                   e.emoji === q
        })
    }

    readonly property var kaoFiltered: {
        var q = searchTerm.toLowerCase()
        if (!q) return kaoAll
        return kaoAll.filter(function(e) {
            return e.text.toLowerCase().includes(q) ||
                   e.group.toLowerCase().includes(q) ||
                   e.category.toLowerCase().includes(q)
        })
    }


    function copyText(text) {
        var esc = text.replace(/'/g, "'\\''")
        copyProc.command = ["bash", "-c", "printf '%s' '" + esc + "' | wl-copy"]
        copyProc.running = true
        root.emojiVisible = false
    }

    Process { id: copyProc }


    Timer {
        id: focusDelayTimer
        interval: 50
        repeat: false
        onTriggered: {
            emojiPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
            exclusiveReleaseTimer.start()
        }
    }

    Timer {
        id: exclusiveReleaseTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (emojiPanel.currentTab === 0)
                emojiSearchInput.forceActiveFocus()
            else
                kaoSearchInput.forceActiveFocus()
            emojiPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
        }
    }

    Connections {
        target: root
        function onEmojiVisibleChanged() {
            if (root.emojiVisible) {
                emojiPanel.searchTerm = ""
                emojiPanel.selectedIndex = 0
                emojiSearchInput.text = ""
                kaoSearchInput.text = ""
                emojiGridView.contentY = 0
                kaoListView.contentY = 0
                focusDelayTimer.start()
            } else {
                emojiSearchInput.text = ""
                kaoSearchInput.text = ""
                emojiSearchInput.focus = false
                kaoSearchInput.focus = false
            }
        }
    }


    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.emojiVisible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 480
        height: 560
        opacity: root.emojiVisible ? 1 : 0
        scale: root.emojiVisible ? 1 : 0.95
        color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.5)
        radius: 20

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: Qt.rgba(0, 0, 0, 0.15)
                radius: 12

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: emojiPanel.currentTab === 0
                            ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰞅"
                                color: emojiPanel.currentTab === 0 ? root.walColor5 : root.walColor8
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "Emoji"
                                color: emojiPanel.currentTab === 0 ? root.walColor5 : root.walColor8
                                font.pixelSize: 13
                                font.bold: emojiPanel.currentTab === 0
                                font.family: "JetBrainsMono Nerd Font"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                emojiPanel.currentTab = 0
                                emojiSearchInput.forceActiveFocus()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: emojiPanel.currentTab === 1
                            ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.2)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "󰙃"
                                color: emojiPanel.currentTab === 1 ? root.walColor13 : root.walColor8
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "Kaomoji"
                                color: emojiPanel.currentTab === 1 ? root.walColor13 : root.walColor8
                                font.pixelSize: 13
                                font.bold: emojiPanel.currentTab === 1
                                font.family: "JetBrainsMono Nerd Font"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                emojiPanel.currentTab = 1
                                kaoSearchInput.forceActiveFocus()
                            }
                        }
                    }
                }
            }


            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true


                ColumnLayout {
                    anchors.fill: parent
                    spacing: 15
                    visible: emojiPanel.currentTab === 0
                    opacity: emojiPanel.currentTab === 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        color: Qt.rgba(0, 0, 0, 0.15)
                        radius: 12
                        border.width: emojiSearchInput.activeFocus ? 1 : 0
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
                                id: emojiSearchInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: root.walForeground
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                clip: true

                                Text {
                                    text: "Search emoji..."
                                    color: root.walColor8
                                    visible: !parent.text
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    font: parent.font
                                    opacity: 0.6
                                }

                                onTextChanged: {
                                    emojiPanel.searchTerm = text.toLowerCase()
                                    emojiGridView.contentY = 0
                                }

                                Keys.onPressed: function(event) {
                                    var cols = Math.max(1, Math.floor(emojiGridView.width / emojiGridView.cellWidth))
                                    if (event.key === Qt.Key_Right) {
                                        emojiGridView.currentIndex = Math.min(emojiGridView.currentIndex + 1, emojiPanel.emojiFiltered.length - 1)
                                        emojiGridView.positionViewAtIndex(emojiGridView.currentIndex, GridView.Contain)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Left) {
                                        emojiGridView.currentIndex = Math.max(emojiGridView.currentIndex - 1, 0)
                                        emojiGridView.positionViewAtIndex(emojiGridView.currentIndex, GridView.Contain)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Down) {
                                        emojiGridView.currentIndex = Math.min(emojiGridView.currentIndex + cols, emojiPanel.emojiFiltered.length - 1)
                                        emojiGridView.positionViewAtIndex(emojiGridView.currentIndex, GridView.Contain)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Up) {
                                        emojiGridView.currentIndex = Math.max(emojiGridView.currentIndex - cols, 0)
                                        emojiGridView.positionViewAtIndex(emojiGridView.currentIndex, GridView.Contain)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        var idx = Math.max(0, emojiGridView.currentIndex)
                                        if (emojiPanel.emojiFiltered.length > 0)
                                            emojiPanel.copyText(emojiPanel.emojiFiltered[idx].emoji)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.emojiVisible = false
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Tab) {
                                        emojiPanel.currentTab = 1
                                        kaoSearchInput.forceActiveFocus()
                                        event.accepted = true
                                    }
                                }
                            }

                            Text {
                                visible: emojiSearchInput.text.length > 0
                                text: "󰅖"
                                color: root.walColor8
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                opacity: clearEmojiMa.containsMouse ? 1.0 : 0.7
                                MouseArea {
                                    id: clearEmojiMa
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { emojiSearchInput.text = ""; emojiSearchInput.forceActiveFocus() }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Qt.rgba(0, 0, 0, 0.15)
                        radius: 15
                        clip: true

                        GridView {
                            id: emojiGridView
                            anchors.fill: parent
                            anchors.margins: 8
                            cellWidth: 52
                            cellHeight: 52
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true
                            cacheBuffer: 200
                            model: emojiPanel.emojiFiltered

                            MouseArea {
                                anchors.fill: parent
                                propagateComposedEvents: true
                                onWheel: function(wheel) {
                                    emojiGridView.contentY = Math.max(0,
                                        Math.min(emojiGridView.contentY - wheel.angleDelta.y * 0.5,
                                                 Math.max(0, emojiGridView.contentHeight - emojiGridView.height)))
                                }
                                onClicked: mouse.accepted = false
                                onPressed: mouse.accepted = false
                                onReleased: mouse.accepted = false
                            }

                            delegate: Item {
                                width: emojiGridView.cellWidth
                                height: emojiGridView.cellHeight

                                property bool isHovered: emojiItemMa.containsMouse
                                property bool isCurrent: GridView.isCurrentItem

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    radius: 10
                                    color: isCurrent
                                        ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.25)
                                        : isHovered
                                            ? Qt.rgba(1, 1, 1, 0.08)
                                            : "transparent"
                                    border.width: isCurrent ? 1 : 0
                                    border.color: root.walColor5
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.emoji
                                        font.pixelSize: 26
                                        scale: isHovered ? 1.2 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                                    }
                                }

                                Rectangle {
                                    visible: isHovered && modelData.name !== ""
                                    anchors.bottom: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 4
                                    width: tooltipText.implicitWidth + 12
                                    height: tooltipText.implicitHeight + 6
                                    radius: 6
                                    color: Qt.rgba(0, 0, 0, 0.8)
                                    z: 10

                                    Text {
                                        id: tooltipText
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        color: root.walForeground
                                        font.pixelSize: 10
                                        font.family: "JetBrainsMono Nerd Font"
                                    }
                                }

                                MouseArea {
                                    id: emojiItemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: emojiPanel.copyText(modelData.emoji)
                                    onContainsMouseChanged: {
                                        if (containsMouse) emojiGridView.currentIndex = index
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
                            visible: emojiPanel.emojiFiltered.length === 0
                            text: "No emoji found"
                            color: root.walColor8
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            opacity: 0.5
                        }
                    }
                }


                ColumnLayout {
                    anchors.fill: parent
                    spacing: 15
                    visible: emojiPanel.currentTab === 1
                    opacity: emojiPanel.currentTab === 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        color: Qt.rgba(0, 0, 0, 0.15)
                        radius: 12
                        border.width: kaoSearchInput.activeFocus ? 1 : 0
                        border.color: root.walColor13

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
                                id: kaoSearchInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: root.walForeground
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                verticalAlignment: TextInput.AlignVCenter
                                selectByMouse: true
                                clip: true

                                Text {
                                    text: "Search kaomoji..."
                                    color: root.walColor8
                                    visible: !parent.text
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    font: parent.font
                                    opacity: 0.6
                                }

                                onTextChanged: {
                                    emojiPanel.searchTerm = text.toLowerCase()
                                    emojiPanel.selectedIndex = 0
                                    kaoListView.contentY = 0
                                }

                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Down) {
                                        emojiPanel.selectedIndex = Math.min(emojiPanel.selectedIndex + 1, emojiPanel.kaoFiltered.length - 1)
                                        kaoListView.positionViewAtIndex(emojiPanel.selectedIndex, ListView.Contain)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Up) {
                                        emojiPanel.selectedIndex = Math.max(emojiPanel.selectedIndex - 1, 0)
                                        kaoListView.positionViewAtIndex(emojiPanel.selectedIndex, ListView.Contain)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (emojiPanel.kaoFiltered.length > 0)
                                            emojiPanel.copyText(emojiPanel.kaoFiltered[emojiPanel.selectedIndex].text)
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Escape) {
                                        root.emojiVisible = false
                                        event.accepted = true
                                    } else if (event.key === Qt.Key_Tab) {
                                        emojiPanel.currentTab = 0
                                        emojiSearchInput.forceActiveFocus()
                                        event.accepted = true
                                    }
                                }
                            }

                            Text {
                                visible: kaoSearchInput.text.length > 0
                                text: "󰅖"
                                color: root.walColor8
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                opacity: clearKaoMa.containsMouse ? 1.0 : 0.7
                                MouseArea {
                                    id: clearKaoMa
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { kaoSearchInput.text = ""; kaoSearchInput.forceActiveFocus() }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Qt.rgba(0, 0, 0, 0.15)
                        radius: 15
                        clip: true

                        ListView {
                            id: kaoListView
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4
                            boundsBehavior: Flickable.StopAtBounds
                            model: emojiPanel.kaoFiltered
                            currentIndex: emojiPanel.selectedIndex

                            MouseArea {
                                anchors.fill: parent
                                propagateComposedEvents: true
                                onWheel: function(wheel) {
                                    kaoListView.contentY = Math.max(0,
                                        Math.min(kaoListView.contentY - wheel.angleDelta.y * 0.5,
                                                 Math.max(0, kaoListView.contentHeight - kaoListView.height)))
                                }
                                onClicked: mouse.accepted = false
                                onPressed: mouse.accepted = false
                                onReleased: mouse.accepted = false
                            }

                            delegate: Rectangle {
                                width: kaoListView.width
                                height: 48
                                radius: 12
                                color: {
                                    if (index === emojiPanel.selectedIndex)
                                        return Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.2)
                                    if (kaoItemMa.containsMouse)
                                        return Qt.rgba(1, 1, 1, 0.05)
                                    return "transparent"
                                }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Rectangle {
                                    visible: index === emojiPanel.selectedIndex
                                    width: 3
                                    height: 22
                                    radius: 2
                                    color: root.walColor13
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    anchors.topMargin: 6
                                    anchors.bottomMargin: 6
                                    spacing: 12

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.text
                                        color: index === emojiPanel.selectedIndex ? root.walColor13 : root.walForeground
                                        font.pixelSize: 14
                                        font.family: "JetBrainsMono Nerd Font"
                                        elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Rectangle {
                                        visible: modelData.category !== ""
                                        height: 18
                                        width: catText.implicitWidth + 12
                                        radius: 6
                                        color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.15)

                                        Text {
                                            id: catText
                                            anchors.centerIn: parent
                                            text: modelData.category
                                            color: root.walColor13
                                            font.pixelSize: 10
                                            font.family: "JetBrainsMono Nerd Font"
                                            opacity: 0.8
                                        }
                                    }

                                    Text {
                                        visible: index === emojiPanel.selectedIndex
                                        text: "↵"
                                        color: root.walColor13
                                        font.pixelSize: 14
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: kaoItemMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: emojiPanel.copyText(modelData.text)
                                    onContainsMouseChanged: {
                                        if (containsMouse) emojiPanel.selectedIndex = index
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
                            visible: emojiPanel.kaoFiltered.length === 0
                            text: "No kaomoji found"
                            color: root.walColor8
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            opacity: 0.5
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        color: Qt.rgba(0, 0, 0, 0.15)
                        radius: 10
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            Text { text: "↑↓ nav"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            Text { text: "↵ copy"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            Text { text: "tab emoji"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                            Item { Layout.fillWidth: true }
                            Text { text: "esc close"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
                        }
                    }
                }
            }
        }
    }
}
