import Quickshell
import QtQuick
import "."

Item {
    id: root
    property bool fileOpen: false
    width: 30
    height: 30

    function closeFile() {
        root.fileOpen = false
    }

    Text {
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize16
        color: root.fileOpen ? Theme.iconWidgetOpen : Theme.iconWidget
        text: "\uF07C"
    }

    property var onToggle: null

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.onToggle) root.onToggle()
            else root.fileOpen = !root.fileOpen
        }
    }
}
