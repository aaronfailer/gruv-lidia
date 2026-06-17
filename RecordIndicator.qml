import Quickshell
import Quickshell.Io
import QtQuick
import "."

Item {
    id: root
    width: 30
    height: 30

    property bool recording: false

    Timer {
        id: checkTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: checker.running = true
    }

    Process {
        id: checker
        command: ["sh", "-c", "test -f /tmp/screen-recording.lock && echo recording || echo not"]
        stdout: StdioCollector {
            id: checkOut
        }
        onExited: {
            root.recording = checkOut.data.toString().trim() === "recording"
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.backgroundAlt
        radius: Theme.radius8
        visible: recording
    }

    Rectangle {
        id: dot
        anchors.centerIn: parent
        width: 10
        height: 10
        radius: 5
        color: Theme.accentRed
        visible: recording

        Timer {
            id: blink
            interval: 800
            running: recording
            repeat: true
            property real low: 0.3
            onTriggered: parent.opacity = parent.opacity === 1.0 ? low : 1.0
        }
        onVisibleChanged: opacity = 1.0
    }

    MouseArea {
        anchors.fill: parent
        visible: recording
        cursorShape: Qt.PointingHandCursor
        onClicked: stopper.running = true
    }

    Process {
        id: stopper
        command: ["sh", "-c", "kill $(cat /tmp/screen-recording.lock) 2>/dev/null; rm -f /tmp/screen-recording.lock; notify-send '⏹ Grabación detenida'"]
    }
}
