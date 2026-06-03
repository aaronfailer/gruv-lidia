import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    property bool trayOpen: false
    width: 30
    height: 30

    Text {
        anchors.centerIn: parent
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 14
        color: root.trayOpen ? "#fabd2f" : "#b8bb26"
        text: "󰺑"
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.trayOpen = !root.trayOpen
    }
}
