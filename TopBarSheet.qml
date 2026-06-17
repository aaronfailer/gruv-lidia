import QtQuick
import "."

Item {
    id: root

    default property alias content: contentArea.data

    readonly property real flareWidth: 20
    readonly property real flareHeight: 35
    readonly property real bottomRadius: 16

    Item {
        id: contentArea
        anchors.fill: parent
    }

    Canvas {
        id: background
        x: -root.flareWidth
        y: -root.flareHeight
        width: root.width + 2 * root.flareWidth
        height: root.height + root.flareHeight
        property int _tick: Theme.isDark ? 1 : 0
        on_TickChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            const fw = root.flareWidth
            const fh = root.flareHeight
            const bw = root.width
            const bh = root.height
            const r = root.bottomRadius

            ctx.beginPath()

            ctx.moveTo(fw, fh)
            ctx.bezierCurveTo(fw, fh * 0.6, fw * 0.3, 0, 0, 0)

            ctx.lineTo(bw + 2 * fw, 0)

            ctx.bezierCurveTo(
                bw + 2 * fw - fw * 0.3, 0,
                fw + bw, fh * 0.6,
                fw + bw, fh
            )

            ctx.lineTo(fw + bw, fh + bh - r)

            ctx.arc(fw + bw - r, fh + bh - r, r, 0, Math.PI * 0.5, false)

            ctx.lineTo(fw + r, fh + bh)

            ctx.arc(fw + r, fh + bh - r, r, Math.PI * 0.5, Math.PI, false)

            ctx.lineTo(fw, fh)

            ctx.closePath()
            ctx.fillStyle = Theme.background
            ctx.fill()
        }
    }
}
