import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Quickshell.Services.Mpris
import "."

PanelWindow {
    id: topBar
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    exclusiveZone: 10
    color: "transparent"

    Process {
        id: notifMonitor
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/notif-monitor.py"]
        running: true
        property int _restartCount: 0
        onExited: Qt.callLater(function() {
            if (notifMonitor._restartCount < 5) {
                notifMonitor._restartCount++
                notifMonitor.running = true
            }
        })
        onStarted: notifMonitor._restartCount = 0
    }

    property bool notificationOpen: false
    onNotificationOpenChanged: {
        notifPopup.open = notificationOpen
        notificationWidget.panelOpen = notificationOpen
    }

    property int currentPlayerIndex: -1
    property MprisPlayer currentPlayer: null
    property bool playerOpen: false

    Connections {
        target: Theme
        function onOverridesChanged() { topCanvas.requestPaint() }
    }

    Canvas {
        id: topCanvas
        anchors.fill: parent
        property int _tick: Theme.isDark ? 1 : 0
        on_TickChanged: requestPaint()
        property int _ppTrigger: playerPill.x + playerPill.width
        property int _npTrigger: notifPill.x + notifPill.width
        on_PpTriggerChanged: requestPaint()
        on_NpTriggerChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            var w = width, h = height
            var ppl = playerPill.x - playerPill.leftExt
            var ppr = playerPill.x + playerPill.width + playerPill.rightExt
            var npl = notifPill.x - notifPill.leftExt
            var npr = notifPill.x + notifPill.width + notifPill.rightExt
            var r = Math.min(playerPill.cornerRadius, h - 20)
            var nr = Math.min(notifPill.cornerRadius, h - 20)

            ctx.fillStyle = Theme.background
            ctx.fillRect(0, 0, w, 10)

            ctx.beginPath()
            ctx.moveTo(ppl, 10)
            ctx.lineTo(ppl, h - r)
            ctx.arcTo(ppl, h, ppl + r, h, r)
            ctx.lineTo(ppr - r, h)
            ctx.arcTo(ppr, h, ppr, h - r, r)
            ctx.lineTo(ppr, 10)
            ctx.closePath()
            ctx.fill()

            ctx.beginPath()
            ctx.moveTo(npl, 10)
            ctx.lineTo(npl, h - nr)
            ctx.arcTo(npl, h, npl + nr, h, nr)
            ctx.lineTo(npr - nr, h)
            ctx.arcTo(npr, h, npr, h - nr, nr)
            ctx.lineTo(npr, 10)
            ctx.closePath()
            ctx.fill()

            ctx.strokeStyle = Theme.border
            ctx.lineWidth = 2

            ctx.beginPath()
            ctx.moveTo(0, 10)
            ctx.lineTo(ppl, 10)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(ppr, 10)
            ctx.lineTo(npl, 10)
            ctx.stroke()

            if (npr < w) {
                ctx.beginPath()
                ctx.moveTo(npr, 10)
                ctx.lineTo(w, 10)
                ctx.stroke()
            }

            ctx.beginPath()
            ctx.moveTo(ppl, 10)
            ctx.lineTo(ppl, h - r)
            ctx.arcTo(ppl, h, ppl + r, h, r)
            ctx.lineTo(ppr - r, h)
            ctx.arcTo(ppr, h, ppr, h - r, r)
            ctx.lineTo(ppr, 10)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(npl, 10)
            ctx.lineTo(npl, h - nr)
            ctx.arcTo(npl, h, npl + nr, h, nr)
            ctx.lineTo(npr - nr, h)
            ctx.arcTo(npr, h, npr, h - nr, nr)
            ctx.lineTo(npr, 10)
            ctx.stroke()
        }
    }

    Rectangle {
        id: playerPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 0
        anchors.top: parent.top
        anchors.topMargin: 0
        property int extraWidth: 20
        property int leftExt: 10
        property int rightExt: 10
        property int cornerRadius: 10
        width: playerWidget.implicitWidth + 32 + extraWidth
        height: 29
        radius: 0
        color: Theme.background

        PlayerWidget {
            id: playerWidget
            player: currentPlayer
            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: notifPill
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.top: parent.top
        anchors.topMargin: 0
        property int extraWidth: -15
        property int leftExt: 10
        property int rightExt: 10
        property int cornerRadius: 10
        height: 28
        width: 40 + extraWidth
        radius: cornerRadius
        color: Theme.background

        NotificationWidget {
            id: notificationWidget
            anchors.centerIn: parent
            onToggled: {
                topBar.notificationOpen = !topBar.notificationOpen
            }
        }
    }

    NotifPopup {
        id: notifPopup
        open: topBar.notificationOpen
        onRequestClose: topBar.notificationOpen = false
    }

    MouseArea {
        id: barHoverArea
        anchors.fill: playerPill
        hoverEnabled: true
        onEntered: {
            if (Mpris.players.values.length > 0) {
                closeTimer.stop()
                playerOpen = true
                topBar.notificationOpen = false
            }
        }
        onExited: closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: 400
        onTriggered: playerOpen = false
    }

    Connections {
        target: Mpris && Mpris.players ? Mpris.players : null
        function onValuesChanged() {
            updateCurrentPlayer()
        }
    }

    Component.onCompleted: updateCurrentPlayer()

    function updateCurrentPlayer() {
        if (!Mpris || !Mpris.players) return
        var list = Mpris.players.values
        if (currentPlayerIndex >= list.length)
            currentPlayerIndex = -1
        if (currentPlayerIndex < 0 && list.length > 0)
            currentPlayerIndex = 0
        currentPlayer = currentPlayerIndex >= 0 && currentPlayerIndex < list.length ? list[currentPlayerIndex] : null
    }

    function selectPlayer(index) {
        var list = Mpris.players.values
        currentPlayerIndex = index
        currentPlayer = index >= 0 && index < list.length ? list[index] : null
    }

    Item {
        id: playerAnchor
        anchors.horizontalCenter: playerPill.horizontalCenter
        anchors.top: playerPill.bottom
        width: 1
        height: 1
    }

    PlayerPopup {
        id: playerPopup
        open: playerOpen
        currentPlayer: topBar.currentPlayer
        currentPlayerIndex: topBar.currentPlayerIndex
        onPopupEntered: {
            closeTimer.stop()
            topBar.notificationOpen = false
        }
        onPopupExited: closeTimer.restart()
        onPlayerSelected: {
            topBar.selectPlayer(index)
            closeTimer.stop()
        }
        anchor.item: playerAnchor
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Top
    }
}
