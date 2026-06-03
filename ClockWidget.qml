import Quickshell
import QtQuick
Item {
    id: root
    property bool calendarOpen: false
    property bool showingDate: false
    width: 30
    height: showingDate ? dateCol.height : timeCol.height
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.showingDate = !root.showingDate
    }
    Column {
        id: timeCol
        visible: !root.showingDate
        spacing: 4
        width: root.width
        Repeater {
            model: ["HH", "mm"]
            delegate: Item {
                required property var modelData
                required property int index
                width: root.width
                height: numText.height + (index < 1 ? 6 : 0)
                Text {
                    id: numText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                    color: root.calendarOpen ? "#fabd2f" : "#b8bb26"
                    text: Qt.formatDateTime(clock.date, modelData)
                }
                Rectangle {
                    visible: index < 1
                    anchors.top: numText.bottom
                    anchors.topMargin: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: numText.width * 0.8
                    height: 2
                    radius: 1
                    color: root.calendarOpen ? "#fabd2f" : "#b8bb26"
                    opacity: 0.9
                }
            }
        }
    }
    Column {
        id: dateCol
        visible: root.showingDate
        spacing: 4
        width: root.width
        Repeater {
            model: ["dd", "MM", "yy"]
            delegate: Item {
                required property var modelData
                required property int index
                width: root.width
                height: numText.height + (index < 2 ? 6 : 0)
                Text {
                    id: numText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                    color: root.calendarOpen ? "#fabd2f" : "#b8bb26"
                    text: Qt.formatDateTime(clock.date, modelData)
                }
                Rectangle {
                    visible: index < 2
                    anchors.top: numText.bottom
                    anchors.topMargin: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: numText.width * 0.8
                    height: 2
                    radius: 1
                    color: root.calendarOpen ? "#fabd2f" : "#b8bb26"
                    opacity: 0.9
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.calendarOpen = !root.calendarOpen
    }
}
