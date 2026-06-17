import Quickshell
import QtQuick
import "."

PanelWindow {
    id: panel
    focusable: true
    anchors {
        top: true
        left: true
        bottom: true
    }
    readonly property int barWidth: 36
    readonly property int iconSpacing: 10
    property alias taskOpen: taskWidget.overflowOpen
    property alias calendarOpen: clock.calendarOpen
    property alias trayOpen: trayWidget.trayOpen
    property alias volumeOpen: volumeWidget.volumeOpen
    property alias wallpaperOpen: wallpaperWidget.wallpaperOpen
    property alias menuOpen: menuWidget.menuOpen
    property alias powerOpen: powerWidget.powerOpen
    property alias bluetoothOpen: bluetoothWidget.bluetoothOpen
    property alias internetOpen: internetWidget.internetOpen
    property alias fileOpen: fileWidget.fileOpen
    property alias colorEditorOpen: colorEditorWidget.colorEditorOpen
    property alias updateOpen: updateWidget.updateOpen
    onFileOpenChanged: { if (fileOpen) closeOtherPopups([]) }
    implicitWidth: barWidth
    property int borderTopInset: 0
    property int borderBottomInset: 0
    property var _skipRegions: []
    property var _closingSkip: null
    property int _repaintTick: 0

    function closeOtherPopups(dontClose) {
        var map = [
            { obj: clock, prop: "calendarOpen" },
            { obj: trayWidget, prop: "trayOpen" },
            { obj: taskWidget, prop: "overflowOpen" },
            { obj: volumeWidget, prop: "volumeOpen" },
            { obj: wallpaperWidget, prop: "wallpaperOpen" },
            { obj: menuWidget, prop: "menuOpen" },
            { obj: powerWidget, prop: "powerOpen" },
            { obj: bluetoothWidget, prop: "bluetoothOpen" },
            { obj: internetWidget, prop: "internetOpen" },
            { obj: colorEditorWidget, prop: "colorEditorOpen" },
            { obj: updateWidget, prop: "updateOpen" }
        ]
        for (var i = 0; i < map.length; i++) {
            if (dontClose.indexOf(i) < 0)
                map[i].obj[map[i].prop] = false
        }
    }

    function _captureClosing(popup, anchor) {
        var pt = anchor.mapToItem(barCol, 0, 0)
        var ah = anchor.height
        var ph = popup.implicitHeight
        var offset = popup.reposTopOffset || 0
        _closingSkip = { start: Math.max(0, pt.y + ah / 2 - ph / 2 + 15 + offset), end: pt.y + ah / 2 + ph / 2 - 15 + offset }
        _computeSkip()
    }

    function _computeSkip() {
        var items = [
            { open: clock.calendarOpen, anchor: calendarAnchor, popup: calendarPopup },
            { open: trayWidget.trayOpen, anchor: trayAnchor, popup: trayPopup },
            { open: taskWidget.overflowOpen, anchor: taskAnchor, popup: taskPopup },
            { open: volumeWidget.volumeOpen, anchor: volumeAnchor, popup: volumePopup },
            { open: wallpaperWidget.wallpaperOpen, anchor: wallpaperAnchor, popup: wallpaperPopup },
            { open: menuWidget.menuOpen, anchor: menuAnchor, popup: menuPopup },
            { open: powerWidget.powerOpen, anchor: powerAnchor, popup: powerPopup },
            { open: bluetoothWidget.bluetoothOpen, anchor: bluetoothAnchor, popup: bluetoothPopup },
            { open: internetWidget.internetOpen, anchor: internetAnchor, popup: internetPopup },
            { open: colorEditorWidget.colorEditorOpen, anchor: colorEditorAnchor, popup: colorEditorPopup },
            { open: updateWidget.updateOpen, anchor: updateAnchor, popup: updatePopup }
        ]
        var regions = []
        for (var i = 0; i < items.length; i++) {
            var item = items[i]
            if (item.open && item.anchor && item.popup) {
                var pt = item.anchor.mapToItem(barCol, 0, 0)
                var ah = item.anchor.height
                var ph = item.popup.implicitHeight
                var offset = item.popup.reposTopOffset || 0
                regions.push({ start: Math.max(0, pt.y + ah / 2 - ph / 2 + 15 + offset), end: pt.y + ah / 2 + ph / 2 - 15 + offset })
            }
        }
        if (_closingSkip) regions.push(_closingSkip)
        _skipRegions = regions
        _repaintTick++
    }

    onCalendarOpenChanged: { if (clock.calendarOpen) _computeSkip(); else _captureClosing(calendarPopup, calendarAnchor) }
    onTrayOpenChanged: { if (trayWidget.trayOpen) _computeSkip(); else _captureClosing(trayPopup, trayAnchor) }
    onTaskOpenChanged: { if (taskWidget.overflowOpen) _computeSkip(); else _captureClosing(taskPopup, taskAnchor) }
    onVolumeOpenChanged: { if (volumeWidget.volumeOpen) _computeSkip(); else _captureClosing(volumePopup, volumeAnchor) }
    onWallpaperOpenChanged: { if (wallpaperWidget.wallpaperOpen) _computeSkip(); else _captureClosing(wallpaperPopup, wallpaperAnchor) }
    onMenuOpenChanged: { if (menuWidget.menuOpen) _computeSkip(); else _captureClosing(menuPopup, menuAnchor) }
    onPowerOpenChanged: { if (powerWidget.powerOpen) _computeSkip(); else _captureClosing(powerPopup, powerAnchor) }
    onBluetoothOpenChanged: { if (bluetoothWidget.bluetoothOpen) _computeSkip(); else _captureClosing(bluetoothPopup, bluetoothAnchor) }
    onInternetOpenChanged: { if (internetWidget.internetOpen) _computeSkip(); else _captureClosing(internetPopup, internetAnchor) }
    onColorEditorOpenChanged: { if (colorEditorWidget.colorEditorOpen) _computeSkip(); else _captureClosing(colorEditorPopup, colorEditorAnchor) }
    onUpdateOpenChanged: { if (updateWidget.updateOpen) _computeSkip(); else _captureClosing(updatePopup, updateAnchor) }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Canvas {
        anchors.fill: parent
        property int _tick: Theme.isDark ? 1 : 0
        on_TickChanged: requestPaint()
        property int _rt: _repaintTick
        on_RtChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            var w = width - 1
            var h = height

            ctx.strokeStyle = Theme.border
            ctx.lineWidth = 2
            ctx.beginPath()

            if (_skipRegions.length === 0) {
                ctx.moveTo(w, borderTopInset)
                ctx.lineTo(w, h - borderBottomInset)
            } else {
                var sorted = _skipRegions.slice().sort(function(a, b) { return a.start - b.start })
                var cursor = borderTopInset
                for (var s = 0; s < sorted.length; s++) {
                    var reg = sorted[s]
                    if (reg.start > cursor) {
                        ctx.moveTo(w, cursor)
                        ctx.lineTo(w, reg.start)
                    }
                    cursor = Math.max(cursor, reg.end)
                }
                if (cursor < h - borderBottomInset) {
                    ctx.moveTo(w, cursor)
                    ctx.lineTo(w, h - borderBottomInset)
                }
            }
            ctx.stroke()

            ctx.fillStyle = Theme.background
            for (var r = 0; r < _skipRegions.length; r++) {
                var sr = _skipRegions[r]
                ctx.fillRect(w - 1, sr.start - 1, 2, sr.end - sr.start + 2)
            }
        }
    }

    PopupGeometryConnections {
        popup: calendarPopup
        enabled: clock.calendarOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: trayPopup
        enabled: trayWidget.trayOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: taskPopup
        enabled: taskWidget.overflowOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: volumePopup
        enabled: volumeWidget.volumeOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: wallpaperPopup
        enabled: wallpaperWidget.wallpaperOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: menuPopup
        enabled: menuWidget.menuOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: powerPopup
        enabled: powerWidget.powerOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: bluetoothPopup
        enabled: bluetoothWidget.bluetoothOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: internetPopup
        enabled: internetWidget.internetOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: colorEditorPopup
        enabled: colorEditorWidget.colorEditorOpen
        onHeightChanged: _computeSkip()
    }
    PopupGeometryConnections {
        popup: updatePopup
        enabled: updateWidget.updateOpen
        onHeightChanged: _computeSkip()
    }

    Connections {
        target: calendarPopup
        function on_WindowVisibleChanged() { if (!calendarPopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: trayPopup
        function on_WindowVisibleChanged() { if (!trayPopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: taskPopup
        function on_WindowVisibleChanged() { if (!taskPopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: volumePopup
        function on_WindowVisibleChanged() { if (!volumePopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: wallpaperPopup
        function on_WindowVisibleChanged() { if (!wallpaperPopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: menuPopup
        function on_WindowVisibleChanged() { if (!menuPopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: powerPopup
        function on_WindowVisibleChanged() { if (!powerPopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: bluetoothPopup
        function on_WindowVisibleChanged() { if (!bluetoothPopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: internetPopup
        function on_WindowVisibleChanged() { if (!internetPopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: colorEditorPopup
        function on_WindowVisibleChanged() { if (!colorEditorPopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }
    Connections {
        target: updatePopup
        function on_WindowVisibleChanged() { if (!updatePopup._windowVisible && _closingSkip) { _closingSkip = null; _computeSkip() } }
    }

    Item {
        id: barCol
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: panel.barWidth

        TaskWidget {
            id: taskWidget
            anchors.top: barCol.top
            anchors.topMargin: 8
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        RecordIndicator {
            id: recordIndicator
            anchors.top: taskWidget.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        ClockWidget {
            id: clock
            anchors.centerIn: parent
        }

        Rectangle {
            anchors.top: clock.top
            anchors.topMargin: -5
            anchors.bottom: clock.bottom
            anchors.bottomMargin: -4
            anchors.horizontalCenter: barCol.horizontalCenter
            width: 30
            color: Theme.backgroundAlt
            radius: Theme.radius8
            z: -1
        }

        TrayWidget {
            id: trayWidget
            anchors.bottom: volumeWidget.top
            anchors.bottomMargin: iconSpacing
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        VolumeWidget {
            id: volumeWidget
            anchors.bottom: wallpaperWidget.top
            anchors.bottomMargin: iconSpacing
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        WallpaperWidget {
            id: wallpaperWidget

            anchors.bottom: bluetoothWidget.top
            anchors.bottomMargin: iconSpacing
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        BluetoothWidget {
            id: bluetoothWidget
            anchors.bottom: internetWidget.top
            anchors.bottomMargin: iconSpacing
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        InternetWidget {
            id: internetWidget
            anchors.bottom: colorEditorWidget.top
            anchors.bottomMargin: iconSpacing
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        ColorEditorWidget {
            id: colorEditorWidget
            anchors.bottom: fileWidget.top
            anchors.bottomMargin: iconSpacing
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        FileWidget {
            id: fileWidget
            anchors.bottom: menuWidget.top
            anchors.bottomMargin: iconSpacing
            anchors.horizontalCenter: barCol.horizontalCenter
            onToggle: function() {
                fileWidget.fileOpen = !fileWidget.fileOpen
            }
        }

        MenuWidget {
            id: menuWidget
            anchors.bottom: updateWidget.top
            anchors.bottomMargin: iconSpacing
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        UpdateWidget {
            id: updateWidget
            anchors.bottom: powerWidget.top
            anchors.bottomMargin: iconSpacing
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        Rectangle {
            id: iconGroupBg
            anchors.top: trayWidget.top
            anchors.topMargin: -5
            anchors.bottom: menuWidget.bottom
            anchors.bottomMargin: -4
            anchors.horizontalCenter: barCol.horizontalCenter
            width: 30
            color: Theme.backgroundAlt
            radius: Theme.radius8
            z: -1
        }

        PowerWidget {
            id: powerWidget
            anchors.bottom: barCol.bottom
            anchors.bottomMargin: 30
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        Item {
            id: taskAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: taskWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: calendarAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: clock.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: trayAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: trayWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: volumeAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: volumeWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: wallpaperAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: wallpaperWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: menuAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: menuWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: powerAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: powerWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: bluetoothAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: bluetoothWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: internetAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: internetWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: colorEditorAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: colorEditorWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: fileAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: fileWidget.verticalCenter
            width: 1
            height: 1
        }

        Item {
            id: updateAnchor
            anchors.right: barCol.right
            anchors.verticalCenter: updateWidget.verticalCenter
            width: 1
            height: 1
        }
    }

    PopupShell {
        id: calendarPopup
        sheetSource: "CalendarSheet.qml"
        open: clock.calendarOpen
        anchorItem: calendarAnchor
        onRequestClose: clock.calendarOpen = false
        onOpenChanged: { if (open) closeOtherPopups([0, 2]) }
    }

    PopupShell {
        id: trayPopup
        sheetSource: "TraySheet.qml"
        open: trayWidget.trayOpen
        anchorItem: trayAnchor
        onRequestClose: trayWidget.trayOpen = false
        onOpenChanged: { if (open) closeOtherPopups([1, 2]) }
    }

    PopupShell {
        id: taskPopup
        sheetSource: "TaskSheet.qml"
        open: taskWidget.overflowOpen
        anchorItem: taskAnchor
        onRequestClose: taskWidget.overflowOpen = false
        onOpenChanged: { if (open) closeOtherPopups([2]) }
    }

        PopupShell {
            id: volumePopup
            sheetSource: "VolumeSheet.qml"
            reposTopOffset: -60
            open: volumeWidget.volumeOpen
            anchorItem: volumeAnchor
        onRequestClose: volumeWidget.volumeOpen = false
        onOpenChanged: { if (open) closeOtherPopups([2, 3]) }
    }

    PopupShell {
        id: wallpaperPopup
        sheetSource: "WallpaperSheet.qml"
        open: wallpaperWidget.wallpaperOpen
        anchorItem: wallpaperAnchor
        onRequestClose: wallpaperWidget.wallpaperOpen = false
        onOpenChanged: {
            if (open) {
                closeOtherPopups([2, 4, 5])
                if (wallpaperPopup.sheetItem)
                    wallpaperPopup.sheetItem.panel.refreshWallpapers()
            }
        }
    }

    PopupShell {
        id: menuPopup
        sheetSource: "MenuSheet.qml"
        reposTopOffset: -90
        open: menuWidget.menuOpen
        anchorItem: menuAnchor
        onRequestClose: menuWidget.closeMenu()
        onSheetItemChanged: {
            if (sheetItem)
                sheetItem.placeRequested.connect(openNewWindow)
        }
        onOpenChanged: { if (open) closeOtherPopups([2, 5]) }
    }

    PopupShell {
        id: powerPopup
        sheetSource: "PowerSheet.qml"
        extra: 8
        extraHeightFactor: 0
        open: powerWidget.powerOpen
        anchorItem: powerAnchor
        onRequestClose: powerWidget.powerOpen = false
        onOpenChanged: { if (open) closeOtherPopups([2, 6]) }
    }

    PopupShell {
        id: bluetoothPopup
        sheetSource: "BluetoothSheet.qml"
        open: bluetoothWidget.bluetoothOpen
        anchorItem: bluetoothAnchor
        onRequestClose: bluetoothWidget.bluetoothOpen = false
        onOpenChanged: { if (open) closeOtherPopups([7]) }
    }

    PopupShell {
        id: internetPopup
        sheetSource: "InternetSheet.qml"
        open: internetWidget.internetOpen
        anchorItem: internetAnchor
        onRequestClose: internetWidget.internetOpen = false
        onOpenChanged: { if (open) closeOtherPopups([8]) }
    }

        PopupShell {
            id: colorEditorPopup
            sheetSource: "ColorEditorSheet.qml"
            reposTopOffset: -30
            open: colorEditorWidget.colorEditorOpen
            anchorItem: colorEditorAnchor
            onRequestClose: colorEditorWidget.colorEditorOpen = false
            onOpenChanged: { if (open) closeOtherPopups([9]) }
        }

    PopupShell {
        id: updatePopup
        sheetSource: "UpdateSheet.qml"
        open: updateWidget.updateOpen
        anchorItem: updateAnchor
        onRequestClose: updateWidget.updateOpen = false
        onOpenChanged: { if (open) closeOtherPopups([2, 10]) }
    }

    FileFloatingWindow {
        id: fileFloatingWindow
        visible: fileWidget.fileOpen
        onRequestClose: fileWidget.fileOpen = false
        Component.onCompleted: {
            fileFloatingWindow.filePanelObj.newWindowRequested.connect(openNewWindow)
        }
    }

    function openNewWindow(path) {
        var component = Qt.createComponent("FileFloatingWindow.qml")
        var win = component.createObject(null, {
            implicitWidth: fileFloatingWindow.implicitWidth,
            implicitHeight: fileFloatingWindow.implicitHeight
        })
        win.filePanelObj.navigateTo(path)
        win.filePanelObj.newWindowRequested.connect(openNewWindow)
        win.visible = true
        win.requestClose.connect(function(){ win.destroy() })
    }
}
