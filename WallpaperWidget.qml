import Quickshell
import QtQuick

Item {
    id: root

    property bool wallpaperOpen: false

    width: 30
    height: 30

    Text {
        anchors.centerIn: parent
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 16

        color: root.wallpaperOpen
        ? "#fabd2f"
        : "#b8bb26"

        text: "󰸉"
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.wallpaperOpen = !root.wallpaperOpen
    }
}
