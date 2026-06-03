import Quickshell
import QtQuick

PanelWindow {
    id: panel
    focusable: true
    anchors {
        top: true
        left: true
        bottom: true
    }
    readonly property int barWidth: 36
    implicitWidth: barWidth

    Rectangle {
        anchors.fill: parent
        color: "#1d2021"
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

        ClockWidget {
            id: clock
            anchors.centerIn: parent
        }

        TrayWidget {
            id: trayWidget
            anchors.bottom: volumeWidget.top
            anchors.bottomMargin: 16
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        VolumeWidget {
            id: volumeWidget
            anchors.bottom: menuWidget.top
            anchors.bottomMargin: 16
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        WallpaperWidget {
            id: wallpaperWidget

            anchors.bottom: menuWidget.top
            anchors.bottomMargin: 110
            anchors.horizontalCenter: barCol.horizontalCenter
        }

        MenuWidget {
            id: menuWidget
            anchors.bottom: powerWidget.top
            anchors.bottomMargin: 30
            anchors.horizontalCenter: barCol.horizontalCenter
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
    }

    CalendarPopup {
        id: calendarPopup
        open: clock.calendarOpen
        anchor.item: calendarAnchor
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right
        anchor.margins.right: 0
        onRequestClose: clock.calendarOpen = false
        onOpenChanged: {
            if (open) {
                trayWidget.trayOpen = false
                volumeWidget.volumeOpen = false
                wallpaperWidget.wallpaperOpen = false
                menuWidget.menuOpen = false
                powerWidget.powerOpen = false
            }
        }
    }

    TrayPopup {
        id: trayPopup
        open: trayWidget.trayOpen
        anchor.item: trayAnchor
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right
        anchor.margins.right: 0
        onRequestClose: trayWidget.trayOpen = false
        onOpenChanged: {
            if (open) {
                clock.calendarOpen = false
                volumeWidget.volumeOpen = false
                wallpaperWidget.wallpaperOpen = false
                menuWidget.menuOpen = false
                powerWidget.powerOpen = false
            }
        }
    }

    TaskPopup {
        id: taskPopup
        open: taskWidget.overflowOpen
        anchor.item: taskAnchor
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right
        anchor.margins.right: 0
        onRequestClose: taskWidget.overflowOpen = false
        onOpenChanged: {
            if (open) {
                clock.calendarOpen = false
                trayWidget.trayOpen = false
                volumeWidget.volumeOpen = false
                wallpaperWidget.wallpaperOpen = false
                menuWidget.menuOpen = false
                powerWidget.powerOpen = false
            }
        }
    }

    VolumePopup {
        id: volumePopup
        open: volumeWidget.volumeOpen
        anchor.item: volumeAnchor
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right
        anchor.margins.right: 0
        onRequestClose: volumeWidget.volumeOpen = false
        onOpenChanged: {
            if (open) {
                clock.calendarOpen = false
                trayWidget.trayOpen = false
                wallpaperWidget.wallpaperOpen = false
                menuWidget.menuOpen = false
                powerWidget.powerOpen = false
            }
        }
    }

    WallpaperPopup {
        id: wallpaperPopup

        open: wallpaperWidget.wallpaperOpen

        anchor.item: wallpaperAnchor
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right

        anchor.margins.right: 0

        onRequestClose: wallpaperWidget.wallpaperOpen = false

        onOpenChanged: {
            if (open) {
                 clock.calendarOpen = false
                 trayWidget.trayOpen = false
                 volumeWidget.volumeOpen = false
                 menuWidget.menuOpen = false
                 powerWidget.powerOpen = false
            }
        }
    }

    MenuPopup {
        id: menuPopup
        open: menuWidget.menuOpen
        anchor.item: menuAnchor
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right
        anchor.margins.right: 0
        onRequestClose: menuWidget.closeMenu()
        onOpenChanged: {
            if (open) {
                clock.calendarOpen = false
                trayWidget.trayOpen = false
                volumeWidget.volumeOpen = false
                wallpaperWidget.wallpaperOpen = false
                powerWidget.powerOpen = false
            }
        }
    }

    PowerPopup {
        id: powerPopup
        open: powerWidget.powerOpen
        anchor.item: powerAnchor
        anchor.edges: Edges.Right
        anchor.gravity: Edges.Right
        anchor.margins.right: 0
        onRequestClose: powerWidget.powerOpen = false
        onOpenChanged: {
            if (open) {
                clock.calendarOpen = false
                trayWidget.trayOpen = false
                volumeWidget.volumeOpen = false
                wallpaperWidget.wallpaperOpen = false
                menuWidget.menuOpen = false
            }
        }
    }
}
