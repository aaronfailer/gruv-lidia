import Quickshell
import QtQuick
import QtQuick.Window
import Quickshell.Io
import "."

PanelWindow {
    id: bottomBorder
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: bottomBorderThemeAnimating ? -1 : 10
    aboveWindows: bottomBorderThemeAnimating
    color: "transparent"
    margins.right: 0

    property bool weatherOpen: false
    property bool bottomBorderThemeAnimating: false

    height: bottomBorderThemeAnimating ? Screen.height : 30

    Process {
        id: delayedWallpaper
        property string targetPath: ""
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/scripts/set-wallpaper.sh",
            targetPath
        ]
    }

    Process {
        id: themeStateReader
        command: ["bash", "-c",
            "cat " + Quickshell.env("HOME") + "/.config/quickshell/theme_state.json 2>/dev/null || echo '{\"isDark\":true}'"]
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                try {
                    var state = JSON.parse(data.trim())
                    if (state.isDark !== undefined)
                        Theme.isDark = state.isDark
                } catch(e) {}
            }
        }
    }

    Process {
        id: themeStateWriter
        property string payload: ""
        command: ["bash", "-c",
            "echo '" + payload + "' > " + Quickshell.env("HOME") + "/.config/quickshell/theme_state.json"]
        running: false
    }

    Process {
        id: kittyColorChanger
        running: false
    }

    Component.onCompleted: themeStateReader.running = true

    Connections {
        target: Theme
        function onOverridesChanged() { bottomCanvas.requestPaint() }
    }

    Timer {
        id: wallpaperTimer
        interval: 500
        onTriggered: {
            delayedWallpaper.targetPath = Theme.isDark
                ? Quickshell.env("HOME") + "/Wallpapers/Wallpaper-imagen/whitetheme.jpg"
                : Quickshell.env("HOME") + "/Wallpapers/Wallpaper-imagen/darktheme.jpg"
            delayedWallpaper.running = true
        }
    }

    Canvas {
        id: bottomCanvas
        anchors.fill: parent
        property int _tick: Theme.isDark ? 1 : 0
        on_TickChanged: requestPaint()
        property int _tpTrigger: themePill.x + themePill.width
        on_TpTriggerChanged: requestPaint()
        property int _wpTrigger: weatherPill.x + weatherPill.width
        on_WpTriggerChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            var w = width, h = height

            var tpx = themePill.x
            var tpy = themePill.y
            var tpw = themePill.width
            var tnr = Math.min(5, tpw / 2)

            var wpx = weatherPill.x
            var wpy = weatherPill.y
            var wpw = weatherPill.width
            var wnr = Math.min(5, wpw / 2)

            ctx.strokeStyle = Theme.border
            ctx.lineWidth = 4

            ctx.beginPath()
            ctx.moveTo(wpx, 20)
            ctx.lineTo(wpx, wpy + wnr)
            ctx.arcTo(wpx, wpy, wpx + wnr, wpy, wnr)
            ctx.lineTo(wpx + wpw - wnr, wpy)
            ctx.arcTo(wpx + wpw, wpy, wpx + wpw, wpy + wnr, wnr)
            ctx.lineTo(wpx + wpw, 20)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(tpx, 20)
            ctx.lineTo(tpx, tpy + tnr)
            ctx.arcTo(tpx, tpy, tpx + tnr, tpy, tnr)
            ctx.lineTo(tpx + tpw - tnr, tpy)
            ctx.arcTo(tpx + tpw, tpy, tpx + tpw, tpy + tnr, tnr)
            ctx.lineTo(tpx + tpw, 20)
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(0, 20)
            ctx.lineTo(wpx, 20)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(wpx + wpw, 20)
            ctx.lineTo(tpx, 20)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(tpx + tpw, 20)
            ctx.lineTo(w, 20)
            ctx.stroke()

            ctx.fillStyle = Theme.background
            ctx.fillRect(0, 20, w, h - 20)

            ctx.beginPath()
            ctx.moveTo(wpx, 20)
            ctx.lineTo(wpx, wpy + wnr)
            ctx.arcTo(wpx, wpy, wpx + wnr, wpy, wnr)
            ctx.lineTo(wpx + wpw - wnr, wpy)
            ctx.arcTo(wpx + wpw, wpy, wpx + wpw, wpy + wnr, wnr)
            ctx.lineTo(wpx + wpw, 20)
            ctx.closePath()
            ctx.fill()

            ctx.beginPath()
            ctx.moveTo(tpx, 20)
            ctx.lineTo(tpx, tpy + tnr)
            ctx.arcTo(tpx, tpy, tpx + tnr, tpy, tnr)
            ctx.lineTo(tpx + tpw - tnr, tpy)
            ctx.arcTo(tpx + tpw, tpy, tpx + tpw, tpy + tnr, tnr)
            ctx.lineTo(tpx + tpw, 20)
            ctx.closePath()
            ctx.fill()
        }
    }

    Rectangle {
        id: themePill
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        implicitWidth: 20
        implicitHeight: 20
        radius: 0
        topLeftRadius: 5
        color: Theme.background

        Text {
            anchors.centerIn: parent
            font.family: Theme.fontFamily
            font.pixelSize: 11
            text: Theme.isDark ? "\uF043" : "\uF06D"
            color: Theme.isDark ? "#83a598" : Theme.accentRed
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
                    onClicked: {
                wallpaperTimer.restart()
                themeAnim.restart()
            }
        }
    }

    Rectangle {
        id: weatherPill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 3
        width: weatherWidget.implicitWidth + 16
        height: 22
        color: Theme.background
        radius: 0
        topLeftRadius: 5
        topRightRadius: 5

        WeatherWidget {
            id: weatherWidget
            anchors.centerIn: parent
        }

        MouseArea {
            id: weatherHoverArea
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            onEntered: {
                weatherCloseTimer.stop()
                weatherOpen = true
            }
            onExited: weatherCloseTimer.restart()
        }
    }

    Timer {
        id: weatherCloseTimer
        interval: 400
        onTriggered: weatherOpen = false
    }

    WeatherPopup {
        id: weatherPopup
        open: weatherOpen
        onPopupEntered: weatherCloseTimer.stop()
        onPopupExited: weatherCloseTimer.restart()
    }

    Canvas {
        id: wipeOverlay
        anchors.fill: parent
        visible: bottomBorderThemeAnimating

        property real radius: 0
        property color targetColor: "#fbf1c7"
        readonly property real maxDist: Math.sqrt(Screen.width * Screen.width + Screen.height * Screen.height)

        onRadiusChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.beginPath()
            ctx.arc(width, height, radius, 0, Math.PI * 2)
            ctx.closePath()
            ctx.fillStyle = targetColor
            ctx.fill()
        }
    }

    SequentialAnimation {
        id: themeAnim

        ScriptAction {
            script: {
                bottomBorderThemeAnimating = true
                wipeOverlay.targetColor = Theme.isDark ? "#fbf1c7" : "#1d2021"
                wipeOverlay.radius = 0
            }
        }

        NumberAnimation {
            target: wipeOverlay
            property: "radius"
            from: 0; to: wipeOverlay.maxDist
            duration: 600
            easing.type: Easing.OutCubic
        }

        ScriptAction { script: Theme.toggle() }

        ScriptAction {
            script: {
                var theme = Theme.isDark ? "dark" : "light"
                kittyColorChanger.command = [
                    Quickshell.env("HOME") + "/.config/quickshell/scripts/swap-kitty-theme.sh",
                    theme
                ]
                kittyColorChanger.running = true
            }
        }

        ScriptAction {
            script: {
                themeStateWriter.payload = JSON.stringify({isDark: Theme.isDark})
                themeStateWriter.running = true
            }
        }

        ScriptAction {
            script: {
                bottomBorderThemeAnimating = false
            }
        }
    }
}
