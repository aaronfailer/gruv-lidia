import Quickshell
import QtQuick
import Quickshell.Services.Mpris
import "."

PanelWindow {
    id: panel
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 28

    property bool playerOpen: false
    property int currentPlayerIndex: -1
    property MprisPlayer currentPlayer: null

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 4
        color: Theme.surface
    }

    Timer {
        id: closeTimer
        interval: 400
        onTriggered: playerOpen = false
    }

    Timer {
        id: initTimer
        interval: 300
        repeat: true
        running: true
        property int attempts: 0
        onTriggered: {
            attempts++
            if (attempts > 30) { running = false; return }
            var list = Mpris && Mpris.players ? Mpris.players.values : null
            if (list && list.length > 0) {
                running = false
                updateCurrentPlayer()
            }
        }
    }

    Connections {
        target: Mpris && Mpris.players ? Mpris.players : null
        function onValuesChanged() {
            updateCurrentPlayer()
        }
    }

    function updateCurrentPlayer() {
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
        id: barContent
        anchors.fill: parent

        PlayerWidget {
            id: playerWidget
            player: currentPlayer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
        }

        Item {
            id: playerAnchor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            width: 1
            height: 1
        }

        MouseArea {
            id: barHoverArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                if (Mpris.players.values.length > 0) {
                    closeTimer.stop()
                    playerOpen = true
                }
            }
            onExited: {
                closeTimer.restart()
            }
        }
    }

    PlayerPopup {
        id: playerPopup
        open: playerOpen
        currentPlayer: panel.currentPlayer
        currentPlayerIndex: panel.currentPlayerIndex
        onPopupEntered: closeTimer.stop()
        onPopupExited: closeTimer.restart()
        onPlayerSelected: {
            panel.selectPlayer(index)
            closeTimer.stop()
        }
        anchor.item: playerAnchor
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Top
        anchor.margins.top: -25
    }
}
