import QtQuick
import Quickshell.Services.Mpris
import "."

Item {
    id: root
    property MprisPlayer player: null
    implicitWidth: row.implicitWidth
    implicitHeight: 28

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize12
            color: player && player.isPlaying
                ? (Theme.isDark ? Theme.accent : Theme.iconWidgetOpen)
                : (Theme.isDark ? Theme.border : Theme.iconWidget)
            text: "\uF001"
        }

        Item {
            id: titleClip
            clip: true
            anchors.verticalCenter: parent.verticalCenter
            width: 200
            height: 16

            Text {
                id: titleText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize11
                color: player && player.trackTitle ? Theme.textPrimary : Theme.border
                text: player && player.trackTitle ? player.trackTitle : (player ? "Pausado" : "Sin reproducción")

                NumberAnimation on x {
                    from: titleClip.width
                    to: -titleText.implicitWidth
                    duration: Math.max(6000, titleText.implicitWidth * 20)
                    loops: Animation.Infinite
                    running: titleText.implicitWidth > titleClip.width
                }
            }
        }
    }
}
