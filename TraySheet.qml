import QtQuick

Item {
    id: sheet
    readonly property int sheetWidth: 200
    readonly property int lipHeight: 0
    readonly property int bodyHeight: trayPanel.implicitHeight
    readonly property int bottomRadius: 16
    readonly property int flare: 15
    property real deploy: 1

    width: sheetWidth
    height: bodyHeight

    Canvas {
        id: background
        anchors.right: parent.right
        width: parent.width + 30
        x: -30
        height: parent.height + flare * 2
        y: -flare
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            const ox = 30
            const w = sheet.sheetWidth
            const h = sheet.bodyHeight
            const r = sheet.bottomRadius
            const f = sheet.flare
            ctx.beginPath()
            ctx.moveTo(ox, 0)
            ctx.bezierCurveTo(ox, f * 0.3, ox + f, f, ox + f * 1.5, f)
            ctx.lineTo(ox + w - r, f)
            ctx.arc(ox + w - r, f + r, r, Math.PI * 1.5, 0, false)
            ctx.lineTo(ox + w, f + h - r)
            ctx.arc(ox + w - r, f + h - r, r, 0, Math.PI * 0.5, false)
            ctx.lineTo(ox + f * 1.5, f + h)
            ctx.bezierCurveTo(ox + f, f + h, ox, f + h + f * 0.7, ox, f * 2 + h)
            ctx.closePath()
            ctx.fillStyle = "#1d2021"
            ctx.fill()
        }
    }

    TrayPanel {
        id: trayPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
    }
}
