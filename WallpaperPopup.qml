import Quickshell
import QtQuick

PopupWindow {
    id: popup

    readonly property int sheetWidth: sheet.sheetWidth
    readonly property int sheetHeight: sheet.lipHeight + sheet.bodyHeight
    readonly property int extra: 30

    implicitWidth: sheetWidth
    implicitHeight: sheetHeight + extra * 2

    color: "transparent"

    property bool open: false
    property bool windowVisible: false

    visible: windowVisible

    signal requestClose()

    onOpenChanged: {
        if (open) {
            popup.windowVisible = true
            sheet.panel.refreshWallpapers()
        }
    }

    Item {
        id: sheetHost

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: popup.extra

        height: popup.sheetHeight
        width: popup.sheetWidth

        clip: false

        HoverHandler {
            onHoveredChanged: {
                if (!hovered)
                    closeTimer.start()
                    else
                        closeTimer.stop()
            }
        }

        WallpaperSheet {
            id: sheet

            x: popup.open ? 0 : -popup.sheetWidth

            Behavior on x {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutCubic

                    onRunningChanged: {
                        if (!running && !popup.open)
                            popup.windowVisible = false
                    }
                }
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 300
        repeat: false

        onTriggered: popup.requestClose()
    }
}
