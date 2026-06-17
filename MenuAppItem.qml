import QtQuick
import Quickshell
import "."

Item {
    id: item
    property var desktopEntry: null
    signal launched()

    width: parent.width
    height: 32

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius6
        color: hover.containsMouse ? Theme.surfaceHover : "transparent"
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 6
        spacing: 8

        Image {
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            source: "image://icon/" + (item.desktopEntry ? item.desktopEntry.icon : "")
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: hover.containsMouse ? Theme.textPrimary : Theme.textTertiary
            text: item.desktopEntry ? item.desktopEntry.name : ""
            elide: Text.ElideRight
            width: item.width - 34
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (item.desktopEntry) {
                if (typeof item.desktopEntry.execute === "function")
                    item.desktopEntry.execute()
                else if (item.desktopEntry.execString)
                    Quickshell.execDetached(item.desktopEntry.execString)
            }
            item.launched()
        }
    }
}
