import QtQuick
import "."

Item {
    id: root
    property bool updateOpen: false
    width: 30
    height: 30

    Text {
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: 20
        color: root.updateOpen ? Theme.accentYellow : Theme.accent
        text: "󰓦"
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.updateOpen = !root.updateOpen
    }
}
