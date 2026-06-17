import QtQuick
import "."

Item {
    id: btn
    property string label: ""
    property string path: ""
    property string glyph: ""
    signal clicked()

    width: parent.width
    height: 24

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius6
        color: hover.containsMouse ? Theme.surfaceHover : "transparent"
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4
        spacing: 6

        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize12
            color: hover.containsMouse ? Theme.accent : Theme.textMuted
            text: btn.glyph
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: hover.containsMouse ? Theme.textPrimary : Theme.textSecondary
            text: btn.label
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
