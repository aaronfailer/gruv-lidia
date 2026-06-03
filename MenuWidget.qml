import Quickshell
import QtQuick

Item {
    id: root
    property bool menuOpen: false
    width: 30
    height: 30

    function closeMenu() {
        root.menuOpen = false
    }

    Text {
        anchors.centerIn: parent
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 16
        color: root.menuOpen ? "#fabd2f" : "#b8bb26"
        text: "󰣇"
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.menuOpen = !root.menuOpen
    }
}
