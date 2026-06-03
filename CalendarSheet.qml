import QtQuick

Item {
    id: sheet
    readonly property int sheetWidth: 260
    readonly property int lipHeight: 0
    readonly property int bodyHeight: 272
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
            // punto 1 — en la barra, arriba del calendario
            ctx.moveTo(ox, 0)
            // curva suave hacia esquina superior — de arriba hacia la derecha
            ctx.bezierCurveTo(
                ox, f * 0.3,
                ox + f, f,
                ox + f * 1.5, f
            )
            // borde superior
            ctx.lineTo(ox + w - r, f)
            // esquina superior derecha
            ctx.arc(ox + w - r, f + r, r, Math.PI * 1.5, 0, false)
            // borde derecho
            ctx.lineTo(ox + w, f + h - r)
            // esquina inferior derecha
            ctx.arc(ox + w - r, f + h - r, r, 0, Math.PI * 0.5, false)
            // borde inferior
            ctx.lineTo(ox + f * 1.5, f + h)
            // curva suave hacia punto 14 — de la derecha hacia abajo
            ctx.bezierCurveTo(
                ox + f, f + h,
                ox, f + h + f * 0.7,
                ox, f * 2 + h
            )
            ctx.closePath()

            ctx.fillStyle = "#1d2021"
            ctx.fill()
        }
    }

    CalendarPanel {
        id: panel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        showChrome: false
        deployProgress: sheet.deploy
    }
}
