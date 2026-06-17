import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    property bool notificationOpen: false
    property bool panelOpen: false
    signal toggled()

    property int notificationCount: 0
    property bool dnd: false

    width: 30
    height: 30

    Process {
        id: swbProcess
        command: ["swaync-client", "-swb"]
        running: true
        property int _restartCount: 0

        stdout: SplitParser {
            onRead: function(data) {
                var line = data.trim()
                if (!line) return
                try {
                    var jsonData = JSON.parse(line)
                    root.notificationCount = parseInt(jsonData.text) || 0
                    root.dnd = String(jsonData.alt).indexOf("dnd") >= 0
                } catch(e) {}
            }
        }

        onExited: {
            if (swbProcess._restartCount < 5) {
                swbProcess._restartCount++
                swbProcess.running = true
            }
        }

        onStarted: swbProcess._restartCount = 0
    }

    Text {
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize16
        color: root.panelOpen ? Theme.accentYellow : (root.dnd ? Theme.textMuted : (root.notificationCount > 0 ? Theme.accent : Theme.border))
        text: root.notificationCount > 0 ? "\uF0F3" : "\uF0A2"
    }

    Rectangle {
        visible: root.notificationCount > 0 && !root.dnd
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -2
        anchors.rightMargin: -2
        width: 16
        height: 16
        radius: 8
        color: Theme.accentRed

        Text {
            anchors.centerIn: parent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize8
            font.weight: Theme.fontWeightBold
            color: Theme.textPrimary
            text: Math.min(root.notificationCount, 99).toString()
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
