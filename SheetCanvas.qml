import QtQuick
import "."

Canvas {
    id: root
    property real sheetWidth: parent ? parent.width : 0
    property real bodyHeight: parent ? parent.height : 0
    property real bottomRadius: 16
    property real flare: 15

    property int _tick: Theme.isDark ? 1 : 0
    on_TickChanged: requestPaint()

    anchors {
        left: parent.left
        right: parent.right
    }
    height: parent.height + flare * 2
    y: -flare

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)
        const ox = 0
        const w = root.sheetWidth
        const h = root.bodyHeight
        const r = root.bottomRadius
        const f = root.flare
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
        ctx.fillStyle = Theme.background
        ctx.fill()
    }
}
