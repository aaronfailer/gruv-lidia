import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    property url sheetSource
    property int extra: 30
    property int extraHeightFactor: 2
    property int closeDelay: 300
    property bool slideVertical: false
    property int reposTopOffset: 0
    property bool open: false
    property Item anchorItem: null

    readonly property int _sheetWidth: loader.item?.sheetWidth ?? 0
    readonly property int _sheetHeight: (loader.item?.lipHeight ?? 0) + (loader.item?.bodyHeight ?? 0)
    property bool searchActive: loader.item?.searchActive ?? false
    property Item sheetItem: loader.item

    property bool _windowVisible: false
    visible: _windowVisible

    signal requestClose()

    implicitWidth: _sheetWidth
    implicitHeight: _sheetHeight + extra * extraHeightFactor
    color: "transparent"
    focusable: true

    anchors { left: true; top: true }
    WlrLayershell.layer: WlrLayer.Overlay
    margins.left: 36
    margins.top: _reposTop
    exclusiveZone: -1

    property int _reposTop: 0

    onOpenChanged: {
        if (open) {
            if (anchorItem)
                _reposTop = anchorItem.y + anchorItem.height / 2 - implicitHeight / 2 + reposTopOffset
            root._windowVisible = true
            focusTimer.restart()
        }
    }

    onAnchorItemChanged: { if (open && anchorItem) _reposTop = anchorItem.y + anchorItem.height / 2 - implicitHeight / 2 + reposTopOffset }
    onImplicitHeightChanged: { if (open && anchorItem) _reposTop = anchorItem.y + anchorItem.height / 2 - implicitHeight / 2 + reposTopOffset }

    Timer {
        id: focusTimer
        interval: 150
        onTriggered: {
            root.requestActivate()
            if (root.open && loader.item && loader.item.forceSearchFocus)
                loader.item.forceSearchFocus()
        }
    }

    Item {
        id: sheetContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: root.extra
        height: root._sheetHeight
        width: root._sheetWidth
        clip: false

        HoverHandler {
            enabled: root.closeDelay > 0
            onHoveredChanged: {
                if (!hovered) closeTimer.start()
                else closeTimer.stop()
            }
        }

        Loader {
            id: loader
            source: root.sheetSource
            x: root.slideVertical ? 0 : (root.open ? 0 : -root._sheetWidth)
            y: root.slideVertical ? (root.open ? 0 : -root._sheetHeight) : 0

            Behavior on x {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutCubic
                    onRunningChanged: {
                        if (!running && !root.open)
                            root._windowVisible = false
                    }
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutCubic
                    onRunningChanged: {
                        if (!running && !root.open)
                            root._windowVisible = false
                    }
                }
            }

            onItemChanged: {
                if (loader.item && loader.item.requestClose)
                    loader.item.requestClose.connect(root.requestClose)
            }
        }
    }

    Timer {
        id: closeTimer
        interval: root.searchActive ? 800 : root.closeDelay
        repeat: false
        onTriggered: root.requestClose()
    }
}
