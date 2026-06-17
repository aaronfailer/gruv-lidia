import Quickshell
import QtQuick
import "."

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
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize16
        color: root.menuOpen ? Theme.iconWidgetOpen : Theme.iconWidget
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
