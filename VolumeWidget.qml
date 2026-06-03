import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool volumeOpen: false
    property real volume: 1.0
    property bool muted: false
    width: 30
    height: 30

    Process {
        id: volReader
        command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ > /tmp/qs_vol.txt"]
        running: true
        onExited: volFile.reload()
    }

    FileView {
        id: volFile
        path: "/tmp/qs_vol.txt"
        onTextChanged: {
            const text = volFile.text()
            if (!text || text.trim() === "") return
                root.muted = text.includes("MUTED")
                const match = text.match(/[\d.]+/)
                if (match) root.volume = parseFloat(match[0])
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: volReader.running = true
    }

    Text {
        anchors.centerIn: parent
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 14
        color: root.volumeOpen ? "#fabd2f" : (root.muted ? "#928374" : "#b8bb26")
        text: root.muted ? "󰝟" : (root.volume > 0.5 ? "󰕾" : "󰖀")
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.volumeOpen = !root.volumeOpen
    }
}
