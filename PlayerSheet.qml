import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "."
import Quickshell.Io

Item {
    id: sheet
    property MprisPlayer player: null
    property int playerIndex: -1

    signal playerSelected(int index)

    onPlayerChanged: artCanvas.resolveArt()

    readonly property int sheetWidth: 350
    readonly property int bodyHeight: Math.min(520, 330 + Math.max(30, appStreams.length * 32 + 60))
    readonly property int lipHeight: 0
    readonly property int bottomRadius: 16
    readonly property int flare: 20
    readonly property int flareTop: 35

    width: sheetWidth
    height: bodyHeight

    function fmt(s) {
        if (!s || s < 0) return "0:00"
        var m = Math.floor(s / 60)
        var sec = Math.floor(s % 60)
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    Timer {
        interval: 500
        running: player ? true : false
        repeat: true
        onTriggered: {
            if (player && player.trackArtUrl !== lastArtUrl) {
                lastArtUrl = player.trackArtUrl
                artCanvas.resolveArt()
            }
        }
        property string lastArtUrl: ""
    }

    property real progressRatio: player && player.length > 0 ? localPosition / player.length : 0
    property real localPosition: player ? player.position : 0
    property bool seeking: false
    property real seekRatio: 0
    property int playerCount: Mpris && Mpris.players ? Mpris.players.values.length : 0
    property var appStreams: []
    property int _streamTick: 0
    property bool _dragging: false

    Connections {
        target: player
        function onPositionChanged() {
            if (player)
                localPosition = player.position
        }
    }

    Timer {
        interval: 1000
        running: player && player.playbackState === MprisPlaybackState.Playing
        repeat: true
        onTriggered: {
            if (player)
                localPosition = player.position
        }
    }

    Process {
        id: streamLister
        running: true
        command: ["bash", "-c", "pactl list sink-inputs > /tmp/qs_streams.txt"]
        onExited: streamFile.reload()
    }

    FileView {
        id: streamFile
        path: "/tmp/qs_streams.txt"
        onTextChanged: {
            if (sheet._dragging) return
            const text = streamFile.text()
            if (!text || text.trim() === "") return
            const blocks = text.trim().split(/\n\s*\n/)
            const result = []
            for (let i = 0; i < blocks.length; i++) {
                const block = blocks[i].trim()
                if (!block) continue
                const idMatch = block.match(/Sink Input #(\d+)/)
                if (!idMatch) continue
                const nameMatch = block.match(/application\.name\s*=\s*"([^"]+)"/)
                if (!nameMatch) continue
                const muteMatch = block.match(/Mute:\s*(yes|no)/)
                const volMatch = block.match(/\/\s*(\d+)%/)
                result.push({
                    id: parseInt(idMatch[1]),
                    name: nameMatch[1],
                    volume: volMatch ? parseInt(volMatch[1]) / 100 : 1.0,
                    muted: muteMatch && muteMatch[1] === "yes"
                })
            }
            sheet.appStreams = result
            sheet._streamTick++
        }
    }

    Process {
        id: streamVolSetter
        property int streamId: 0
        property string streamVol: "50"
        command: ["pactl", "set-sink-input-volume", String(streamId), streamVol + "%"]
        onExited: { if (!sheet._dragging) streamLister.running = true }
    }

    Process {
        id: streamMuteToggler
        property int streamId: 0
        command: ["pactl", "set-sink-input-mute", String(streamId), "toggle"]
        onExited: { if (!sheet._dragging) streamLister.running = true }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: streamLister.running = true
    }

    Canvas {
        id: background
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height + flareTop
        y: -flareTop
        property int _tick: Theme.isDark ? 1 : 0
        on_TickChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            const w = sheet.sheetWidth
            const h = sheet.bodyHeight
            const r = sheet.bottomRadius
            const f = sheet.flare
            const eh = sheet.flareTop
            ctx.beginPath()
            ctx.moveTo(w / 2, -eh)
            ctx.bezierCurveTo(
                w / 2 + f * 0.5, -eh + 2,
                w / 2 + f, -eh * 0.4,
                w / 2 + f * 1.5, 0
            )
            ctx.lineTo(w, 0)
            ctx.lineTo(w, h - r)
            ctx.arc(w - r, h - r, r, 0, Math.PI * 0.5, false)
            ctx.lineTo(r, h)
            ctx.arc(r, h - r, r, Math.PI * 0.5, Math.PI, false)
            ctx.lineTo(0, 0)
            ctx.lineTo(w / 2 - f * 1.5, 0)
            ctx.bezierCurveTo(
                w / 2 - f, -eh * 0.4,
                w / 2 - f * 0.5, -eh + 2,
                w / 2, -eh
            )
            ctx.closePath()
            ctx.fillStyle = Theme.background
            ctx.fill()
        }
    }

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 8

        // Player selector
        Flow {
            visible: playerCount > 1
            width: parent.width
            spacing: 4

            Repeater {
                model: Mpris.players

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: 60; height: 20; radius: Theme.radius3
                    color: index === playerIndex ? Theme.surface : "transparent"
                    border.color: Theme.border; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize9
                        color: index === playerIndex ? Theme.textPrimary : Theme.textMuted
                        text: (modelData.identity || "Player").substring(0, 8)
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sheet.playerSelected(index)
                    }
                }
            }
        }

        // Album art
        Item {
            width: parent.width
            height: 140

            Item {
                id: artCanvas
                anchors.centerIn: parent
                width: 140
                height: 140

                property string artUrl: resolvedArtUrl
                property string resolvedArtUrl: ""

                Process {
                    id: artBridge
                    stdout: SplitParser {
                        onRead: function(data) {
                            var trimmed = data.trim()
                            if (trimmed)
                                artCanvas.resolvedArtUrl = trimmed
                        }
                    }
                }

                function resolveArt() {
                    if (!player || !player.trackArtUrl) {
                        resolvedArtUrl = ""
                        return
                    }
                    var url = player.trackArtUrl
                    if (!url.startsWith("file://")) {
                        resolvedArtUrl = url
                        return
                    }
                    artBridge.running = false
                    artBridge.command = [
                        "bash",
                        Quickshell.env("HOME") + "/.config/quickshell/scripts/art-bridge.sh",
                        player.dbusName,
                        url
                    ]
                    artBridge.running = true
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.surface
                    visible: artImage.status !== Image.Ready
                    z: -1

                    Text {
                        anchors.centerIn: parent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize48
                        color: Theme.textInactive
                        text: "\uF001"
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    clip: true
                    color: "transparent"

                    Image {
                        id: artImage
                        anchors.fill: parent
                        source: artCanvas.artUrl
                        asynchronous: true
                        sourceSize.width: 512
                        sourceSize.height: 512
                        fillMode: Image.PreserveAspectCrop
                    }
                }
            }
        }

        // Title (marquee)
        Item {
            width: parent.width
            height: 20
            clip: true

            Text {
                id: titleText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize13
                font.weight: Theme.fontWeightDemiBold
                color: player && player.trackTitle ? Theme.textPrimary : Theme.textInactive
                text: player && player.trackTitle ? player.trackTitle : (player ? "Sin título" : "Sin reproducción")

                NumberAnimation on x {
                    id: marqueeAnim
                    from: parent.width
                    to: -titleText.implicitWidth
                    duration: Math.max(8000, titleText.implicitWidth * 18)
                    loops: Animation.Infinite
                    running: titleText.implicitWidth > parent.width
                }

                Binding on x {
                    when: !marqueeAnim.running
                    value: 0
                }
            }
        }

        // Artist
        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize11
            color: player && player.trackArtist ? Theme.textSecondary : Theme.textInactive
            text: player && player.trackArtist ? player.trackArtist : (player ? "Artista desconocido" : "")
            elide: Text.ElideRight
            width: parent.width
        }

        // Progress bar (seekable)
        Item {
            width: parent.width
            height: 24

            Rectangle {
                id: progressTrack
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.surface

                Rectangle {
                    id: progressFill
                    width: parent.width * Math.min(sheet.seeking ? sheet.seekRatio : sheet.progressRatio, 1.0)
                    height: parent.height
                    radius: parent.radius
                    color: player && player.isPlaying ? Theme.accent : Theme.textMuted
                }

                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: Theme.accent
                    x: Math.min(sheet.seeking ? sheet.seekRatio : sheet.progressRatio, 1.0) * parent.width - width / 2
                    y: (parent.height - height) / 2
                    visible: player && player.canSeek && (progressMouse.containsMouse || sheet.seeking)

                    Rectangle {
                        width: 6; height: 6; radius: Theme.radius3
                        anchors.centerIn: parent
                        color: Theme.textPrimary
                    }
                }
            }

            MouseArea {
                id: progressMouse
                anchors.fill: progressTrack
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: player && player.canSeek

                onPressed: {
                    sheet.seeking = true
                    var ratio = Math.max(0, Math.min(1, mouseX / progressTrack.width))
                    sheet.seekRatio = ratio
                    if (player && player.length > 0)
                        player.position = ratio * player.length
                }
                onPositionChanged: {
                    if (pressed) {
                        var ratio = Math.max(0, Math.min(1, mouseX / progressTrack.width))
                        sheet.seekRatio = ratio
                        if (player && player.length > 0)
                            player.position = ratio * player.length
                    }
                }
                onReleased: {
                    sheet.seeking = false
                }
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: progressTrack.top
                anchors.bottomMargin: 2
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize9
                color: Theme.textMuted
                text: fmt(sheet.localPosition)
            }

            Text {
                anchors.right: parent.right
                anchors.bottom: progressTrack.top
                anchors.bottomMargin: 2
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize9
                color: Theme.textMuted
                text: fmt(player ? player.length : 0)
            }
        }

        // Controls
        Row {
            width: parent.width
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter
            layoutDirection: Qt.LeftToRight

            Item { width: (parent.width - 28 - 32 - 28 - 24) / 2; height: 1 }

            Rectangle {
                width: 28; height: 28; radius: Theme.radius4
                color: prevHover.containsMouse ? Theme.surfaceHover : "transparent"
                border.color: Theme.border; border.width: 1
                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize14
                    color: player && player.canGoPrevious ? Theme.textPrimary : Theme.textInactive
                    text: "\uF04A"
                }
                MouseArea {
                    id: prevHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (player) player.previous() }
                }
            }

            Rectangle {
                width: 32; height: 28; radius: Theme.radius4
                color: ppHover.containsMouse ? Theme.surfaceHover : "transparent"
                border.color: Theme.accent; border.width: 1
                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize16
                    color: Theme.accent
                    text: player && player.isPlaying ? "\uF04C" : "\uF04B"
                }
                MouseArea {
                    id: ppHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (player) player.togglePlaying() }
                }
            }

            Rectangle {
                width: 28; height: 28; radius: Theme.radius4
                color: nextHover.containsMouse ? Theme.surfaceHover : "transparent"
                border.color: Theme.border; border.width: 1
                Text {
                    anchors.centerIn: parent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize14
                    color: player && player.canGoNext ? Theme.textPrimary : Theme.textInactive
                    text: "\uF04E"
                }
                MouseArea {
                    id: nextHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (player) player.next() }
                }
            }

            Item { width: (parent.width - 28 - 32 - 28 - 24) / 2; height: 1 }
        }

        // Per-app volume
        Rectangle {
            width: parent.width; height: 1; color: Theme.border
        }

        Text {
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize10
            font.bold: true
            color: Theme.textPrimary
            text: "Volumen por programa"
            visible: sheet.appStreams.length > 0
        }

        Repeater {
            id: streamRepeater
            width: parent.width
            model: sheet.appStreams

            delegate: Item {
                required property var modelData
                id: delItem
                height: 24
                width: streamRepeater.width
                property real _dragVol: modelData.volume
                property int _lastSentPct: -1

                Row {
                    spacing: 6
                    width: parent.width

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize12
                        color: modelData.muted ? Theme.textMuted : Theme.accent
                        text: modelData.muted ? "\uF026" : "\uF028"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                streamMuteToggler.streamId = modelData.id
                                streamMuteToggler.running = true
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 80
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize9
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        text: modelData.name
                    }

                    Rectangle {
                        id: st
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 16 - 80 - 32 - 12
                        height: 4
                        radius: 2
                        color: Theme.surface

                        Rectangle {
                            width: parent.width * Math.min(delItem._dragVol, 1.0)
                            height: parent.height
                            radius: parent.radius
                            color: Theme.accent
                        }

                        Rectangle {
                            width: 12; height: 12; radius: 6
                            color: Theme.accent
                            x: parent.width * Math.min(delItem._dragVol, 1.0) - width / 2
                            y: (parent.height - height) / 2
                            visible: sliderMouse.containsMouse || sliderMouse.pressed

                            Rectangle {
                                width: 6; height: 6; radius: 3
                                anchors.centerIn: parent
                                color: Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: sliderMouse
                            anchors.fill: parent
                            anchors.topMargin: -6
                            anchors.bottomMargin: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onPressed: {
                                sheet._dragging = true
                                delItem._lastSentPct = -1
                                const ratio = Math.max(0, Math.min(1, mouseX / width))
                                delItem._dragVol = ratio
                                const pct = Math.round(ratio * 100)
                                delItem._lastSentPct = pct
                                streamVolSetter.streamId = modelData.id
                                streamVolSetter.streamVol = String(pct)
                                streamVolSetter.running = true
                            }

                            onPositionChanged: {
                                if (sheet._dragging) {
                                    delItem._dragVol = Math.max(0, Math.min(1, mouseX / width))
                                    const pct = Math.round(delItem._dragVol * 100)
                                    if (pct !== delItem._lastSentPct) {
                                        delItem._lastSentPct = pct
                                        streamVolSetter.streamId = modelData.id
                                        streamVolSetter.streamVol = String(pct)
                                        streamVolSetter.running = true
                                    }
                                }
                            }

                            onReleased: {
                                sheet._dragging = false
                                modelData.volume = delItem._dragVol
                                streamVolSetter.streamId = modelData.id
                                streamVolSetter.streamVol = String(Math.round(delItem._dragVol * 100))
                                streamVolSetter.running = true
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize9
                        color: Theme.textPrimary
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(delItem._dragVol * 100) + "%"
                    }
                }
            }
        }
    }
}
