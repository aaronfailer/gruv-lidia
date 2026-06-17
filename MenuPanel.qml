import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: panel
    readonly property int panelWidth: 360
    readonly property int panelHeight: 340
    width: panelWidth
    implicitHeight: panelHeight

    signal requestClose()
    signal placeRequested(string path)

    property bool searchActive: false
    property var recentApps: []
    property var searchResults: []

    function trackLaunch(entry) {
        trackProcess.trackName = entry.name
        trackProcess.trackIcon = entry.icon || "application-x-executable"
        trackProcess.trackExec = entry.execString
        trackProcess.running = true
    }

    function forceSearchFocus() {
        searchInput.forceActiveFocus()
    }

    function parseHistory() {
        const text = historyFile.text()
        if (!text || text.trim() === "") {
            const apps = DesktopEntries.applications.values
            panel.recentApps = apps.slice(0, Math.min(8, apps.length))
            return
        }
        const lines = text.trim().split("\n").reverse()
        const seen = {}
        const result = []
        for (let i = 0; i < lines.length && result.length < 8; i++) {
            const parts = lines[i].split("|")
            if (parts.length === 3 && !seen[parts[0]] && parts[0].trim() !== "") {
                seen[parts[0]] = true
                const entry = DesktopEntries.heuristicLookup(parts[0])
                if (entry) {
                    result.push(entry)
                } else {
                    // Fallback: entry sintético del log (Wine, AppImages, etc.)
                    result.push({
                        "name": parts[0],
                        "icon": parts[1] || "application-x-executable",
                        "execString": parts[2]
                    })
                }
            }
        }
        const apps = DesktopEntries.applications.values
        panel.recentApps = result.length > 0 ? result : apps.slice(0, Math.min(8, apps.length))
    }

    function updateFilter() {
        const q = searchInput.text.toLowerCase().trim()
        if (q === "") {
            panel.searchResults = []
            panel.searchActive = false
            return
        }
        const results = []
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; i++) {
            if (results.length >= 8) break
            if (apps[i].name.toLowerCase().includes(q)) {
                results.push(apps[i])
            }
        }
        panel.searchResults = results
        panel.searchActive = true
    }

    FileView {
        id: historyFile
        path: Quickshell.env("HOME") + "/.config/quickshell/app_history.log"
        onTextChanged: panel.parseHistory()
        Component.onCompleted: reload()
    }

    Process {
        id: trackProcess
        property string trackName: ""
        property string trackIcon: ""
        property string trackExec: ""
        command: ["bash", "-c",
            "echo '" + trackName + "|" + trackIcon + "|" + trackExec + "' >> " + Quickshell.env("HOME") + "/.config/quickshell/app_history.log"
            + " && tail -200 " + Quickshell.env("HOME") + "/.config/quickshell/app_history.log > /tmp/qs_history_tmp"
            + " && mv /tmp/qs_history_tmp " + Quickshell.env("HOME") + "/.config/quickshell/app_history.log"
        ]
    }

    Timer {
        id: reloadTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: historyFile.reload()
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { panel.parseHistory() }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Column {
            width: parent.width - 114
            height: parent.height
            spacing: 10

            Rectangle {
                width: parent.width
                height: 28
                radius: Theme.radius8
                color: searchInput.activeFocus ? Theme.surfaceHover : Theme.surface
                border.color: searchInput.activeFocus ? Theme.accent : Theme.border
                border.width: 1

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize11
                    color: Theme.textPrimary
                    cursorVisible: activeFocus
                    onTextChanged: panel.updateFilter()
                    Keys.onEscapePressed: {
                        searchInput.text = ""
                        searchInput.focus = false
                        panel.searchResults = []
                        panel.searchActive = false
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize11
                    color: Theme.textDim
                    text: "Buscar aplicaciones..."
                    visible: searchInput.text === "" && !searchInput.activeFocus
                }
            }

            Column {
                width: parent.width
                spacing: 2
                visible: !panel.searchActive

                Repeater {
                    model: panel.recentApps
                    delegate: MenuAppItem {
                        required property var modelData
                        width: parent.width
                        desktopEntry: modelData
                        onLaunched: {
                            panel.trackLaunch(modelData)
                            panel.requestClose()
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2
                visible: panel.searchActive

                Text {
                    width: parent.width
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize10
                    color: Theme.textDim
                    text: "Resultados"
                    visible: panel.searchResults.length > 0
                    topPadding: 4
                    bottomPadding: 2
                }

                Repeater {
                    model: panel.searchResults
                    delegate: MenuAppItem {
                        required property var modelData
                        width: parent.width
                        desktopEntry: modelData
                        onLaunched: {
                            panel.trackLaunch(modelData)
                            panel.requestClose()
                        }
                    }
                }

                Text {
                    width: parent.width
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize10
                    color: Theme.textDim
                    text: "Sin resultados"
                    visible: panel.searchResults.length === 0
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: Theme.surface
            opacity: Theme.opacityDim
        }

        Column {
            width: 100
            height: parent.height
            spacing: 4

            Repeater {
                model: [
                    { label: "Personal",   glyph: "󰋞",  path: Quickshell.env("HOME") },
                    { label: "Documentos", glyph: "󰈙",  path: Quickshell.env("HOME") + "/Documentos" },
                    { label: "Imágenes",   glyph: "󰋩",  path: Quickshell.env("HOME") + "/Imágenes" },
                    { label: "Música",     glyph: "󰎄",  path: Quickshell.env("HOME") + "/Música" },
                    { label: "Descargas",  glyph: "󰉍",  path: Quickshell.env("HOME") + "/Descargas" },
                    { label: "Equipo",     glyph: "󰋊",  path: "/" }
                ]
                delegate: MenuPlaceButton {
                    required property var modelData
                    width: parent.width
                    label: modelData.label
                    glyph: modelData.glyph
                    path: modelData.path
                    onClicked: panel.placeRequested(path)
                }
            }
        }
    }

    Timer {
        id: clearTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (!searchInput.activeFocus && searchInput.text === "") {
                panel.searchResults = []
                panel.searchActive = false
            }
        }
    }

    Connections {
        target: searchInput
        function onActiveFocusChanged() {
            if (!searchInput.activeFocus && searchInput.text === "") {
                clearTimer.start()
            }
        }
    }
}
