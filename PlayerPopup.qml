import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import "."

PopupWindow {
    id: popup
    readonly property int sheetWidth: sheet.sheetWidth
    readonly property int sheetHeight: sheet.lipHeight + sheet.bodyHeight
    readonly property int extra: 40
    implicitWidth: sheetWidth
    implicitHeight: sheetHeight + extra * 2
    color: "transparent"

    property bool open: false
    property bool windowVisible: false
    property MprisPlayer currentPlayer: null
    property int currentPlayerIndex: -1
    visible: windowVisible

    signal popupEntered()
    signal popupExited()
    signal playerSelected(int index)

    onOpenChanged: {
        if (open)
            popup.windowVisible = true
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
                if (hovered) popupEntered()
                else popupExited()
            }
        }

        PlayerSheet {
            id: sheet
            player: currentPlayer
            playerIndex: currentPlayerIndex
            onPlayerSelected: popup.playerSelected(index)
            y: popup.open ? 0 : -popup.sheetHeight
            Behavior on y {
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
}
