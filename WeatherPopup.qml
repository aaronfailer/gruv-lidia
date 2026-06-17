import Quickshell
import QtQuick
import "."

PanelWindow {
    id: popup

    readonly property int sheetWidth: sheet.sheetWidth
    readonly property int sheetHeight: sheet.bodyHeight

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    implicitHeight: sheetHeight
    margins.bottom: 0
    focusable: true
    exclusiveZone: 0
    color: "transparent"

    property bool open: false
    property bool windowVisible: false
    visible: windowVisible

    signal popupEntered()
    signal popupExited()

    onOpenChanged: {
        if (open) {
            popup.windowVisible = true
        }
    }

    Item {
        id: sheetHost
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: sheetWidth
        height: sheetHeight
        clip: false

        HoverHandler {
            onHoveredChanged: {
                if (hovered) popupEntered()
                else popupExited()
            }
        }

        WeatherSheet {
            id: sheet
            y: popup.open ? 0 : sheetHeight
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
