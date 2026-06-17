import Quickshell
import QtQuick
import "."

Item {
    id: root

    property bool wallpaperOpen: false

    width: 30
    height: 30

    Text {
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize16

        color: root.wallpaperOpen
        ? Theme.iconWidgetOpen
        : Theme.iconWidget

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
