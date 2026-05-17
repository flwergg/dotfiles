import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: calendarPanel
    visible: root.calendarVisible
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    focusable: true
    WlrLayershell.keyboardFocus: root.calendarVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None


    property int displayMonth: new Date().getMonth()
    property int displayYear: new Date().getFullYear()
    property int todayDay: new Date().getDate()
    property int todayMonth: new Date().getMonth()
    property int todayYear: new Date().getFullYear()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    property var calendarDays: {
        var days = []
        var firstDay = new Date(displayYear, displayMonth, 1).getDay()
        var totalDays = new Date(displayYear, displayMonth + 1, 0).getDate()
        for (var i = 0; i < firstDay; i++) days.push(0)
        for (var d = 1; d <= totalDays; d++) days.push(d)
        while (days.length % 7 !== 0) days.push(0)
        return days
    }

    function prevMonth() {
        if (displayMonth === 0) { displayMonth = 11; displayYear-- }
        else displayMonth--
    }

    function nextMonth() {
        if (displayMonth === 11) { displayMonth = 0; displayYear++ }
        else displayMonth++
    }

    function isToday(day) {
        return day === todayDay &&
               displayMonth === todayMonth &&
               displayYear === todayYear
    }

    onVisibleChanged: {
        if (!visible) {
            displayMonth = new Date().getMonth()
            displayYear = new Date().getFullYear()
        }
    }


    MouseArea {
        anchors.fill: parent
        onClicked: root.calendarVisible = false
    }


    Rectangle {
        id: panel
        x: 8
        y: 36
        width: 272
        height: panelColumn.implicitHeight + 24
        color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.45)
        radius: 16

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: panelColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 0

                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: prevMa.containsMouse ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        color: root.walColor5
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: prevMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendarPanel.prevMonth()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: calendarPanel.monthNames[calendarPanel.displayMonth] + " " + calendarPanel.displayYear
                    color: root.walForeground
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: nextMa.containsMouse ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        color: root.walColor5
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: nextMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendarPanel.nextMonth()
                    }
                }
            }

            Row {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: calendarPanel.dayNames
                    Text {
                        width: 36
                        text: modelData
                        color: index === 0 || index === 6
                            ? root.walColor1
                            : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.5)
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Grid {
                Layout.fillWidth: true
                columns: 7
                spacing: 0

                Repeater {
                    model: calendarPanel.calendarDays

                    Item {
                        width: 36
                        height: 32

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 8
                            color: calendarPanel.isToday(modelData) && modelData !== 0
                                ? root.walColor13
                                : dayMa.containsMouse && modelData !== 0
                                    ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.2)
                                    : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData !== 0 ? modelData : ""
                            color: {
                                if (modelData === 0) return "transparent"
                                if (calendarPanel.isToday(modelData)) return root.walBackground
                                var col = (index % 7)
                                if (col === 0 || col === 6)
                                    return Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.7)
                                return root.walForeground
                            }
                            font.pixelSize: 12
                            font.bold: calendarPanel.isToday(modelData)
                            font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: dayMa
                            anchors.fill: parent
                            hoverEnabled: modelData !== 0
                            cursorShape: modelData !== 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }
                }
            }
        }
    }


    Item {
        anchors.fill: parent
        focus: root.calendarVisible
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.calendarVisible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                calendarPanel.prevMonth()
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                calendarPanel.nextMonth()
                event.accepted = true
            }
        }
    }
}
