import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    property bool internetOpen: false
    property bool hasInternet: false
    property bool isEthernet: false
    property bool isWifi: false
    width: 30
    height: 30

    Process {
        id: stateReader
        command: ["bash", "-c", "nmcli -t -f STATE general status > /tmp/qs_inet_state.txt 2>/dev/null; nmcli -t -f TYPE,DEVICE connection show --active 2>/dev/null | grep -E '802-11-wireless|802-3-ethernet' | head -1 > /tmp/qs_inet_type.txt"]
        running: true
        onExited: stateFile.reload()
    }

    FileView {
        id: stateFile
        path: "/tmp/qs_inet_state.txt"
        onTextChanged: {
            root.hasInternet = stateFile.text().trim() === "connected"
        }
    }

    FileView {
        id: typeFile
        path: "/tmp/qs_inet_type.txt"
        onTextChanged: {
            const text = typeFile.text().trim()
            if (!text) { root.isEthernet = false; root.isWifi = false; return }
            root.isEthernet = text.includes("802-3-ethernet")
            root.isWifi = text.includes("802-11-wireless")
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: stateReader.running = true
    }

    Text {
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize16
        color: {
            if (root.internetOpen) return Theme.iconWidgetOpen
            if (!root.hasInternet) return Theme.accentRed
            if (root.isEthernet) return Theme.iconWidget
            return Theme.iconWidget
        }
        text: {
            if (!root.hasInternet) return "\uF00D"
            if (root.isEthernet) return "\uEF44"
            return "\uF1EB"
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.internetOpen = !root.internetOpen
    }
}
