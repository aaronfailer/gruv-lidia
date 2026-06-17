import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: root
    property bool bluetoothOpen: false
    property bool btPowered: false
    width: 30
    height: 30

    Process {
        id: showReader
        command: ["bash", "-c", "bluetoothctl --timeout 2 show > /tmp/qs_bt_show.txt"]
        running: true
        onExited: showFile.reload()
    }

    FileView {
        id: showFile
        path: "/tmp/qs_bt_show.txt"
        onTextChanged: {
            root.btPowered = showFile.text().includes("Powered: yes")
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: showReader.running = true
    }

    Text {
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize16
        color: root.bluetoothOpen ? Theme.iconWidgetOpen : (root.btPowered ? Theme.iconWidget : Theme.textMuted)
        text: "\uF294"
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.bluetoothOpen = !root.bluetoothOpen
    }
}
