import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "."

Item {
    id: root
    property bool trayOpen: false
    width: 30
    height: 30

    Text {
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize14
        color: root.trayOpen ? Theme.iconWidgetOpen : Theme.iconWidget
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
