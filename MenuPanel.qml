import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: panel
    readonly property int panelWidth: 360
    readonly property int panelHeight: 340
    width: panelWidth
    implicitHeight: panelHeight

    signal requestClose()

    property bool searchActive: false
    property var recentApps: []
    property var allApps: []
    property var filteredApps: []

    readonly property var defaultApps: [
        { name: "Firefox",    icon: "firefox",               exec: "firefox" },
        { name: "Chromium",   icon: "chromium",              exec: "chromium" },
        { name: "Discord",    icon: "discord",               exec: "discord" },
        { name: "Steam",      icon: "steam",                 exec: "steam" },
        { name: "Alacritty",  icon: "Alacritty",             exec: "alacritty" },
        { name: "OBS",        icon: "com.obsproject.Studio",  exec: "obs" },
        { name: "Cursor",     icon: "cursor",                exec: "cursor" },
        { name: "Dolphin",    icon: "org.kde.dolphin",       exec: "dolphin" }
    ]

    function trackLaunch(name, icon, exec) {
        trackProcess.trackName = name
        trackProcess.trackIcon = icon
        trackProcess.trackExec = exec
        trackProcess.running = true
    }

    function parseHistory() {
        const text = historyFile.text()
        if (!text || text.trim() === "") {
            panel.recentApps = panel.defaultApps
            return
        }
        const lines = text.trim().split("\n").reverse()
        const seen = {}
        const result = []
        for (let i = 0; i < lines.length && result.length < 8; i++) {
            const parts = lines[i].split("|")
            if (parts.length === 3 && !seen[parts[0]] && parts[0].trim() !== "") {
                seen[parts[0]] = true
                result.push({ name: parts[0], icon: parts[1], exec: parts[2] })
            }
        }
        panel.recentApps = result.length > 0 ? result : panel.defaultApps
    }

    function updateFilter() {
        const q = searchInput.text.toLowerCase().trim()
        if (q === "") {
            panel.filteredApps = []
            panel.searchActive = false
            return
        }
        const results = []
        for (let i = 0; i < panel.allApps.length; i++) {
            if (results.length >= 8) break
            if (panel.allApps[i].name.toLowerCase().includes(q)) {
                results.push(panel.allApps[i])
            }
        }
        panel.filteredApps = results
        panel.searchActive = true
    }

    FileView {
        id: historyFile
        path: Quickshell.env("HOME") + "/.config/quickshell/app_history.log"
        onTextChanged: panel.parseHistory()
        Component.onCompleted: reload()
    }

    FileView {
        id: appsFile
        path: "/tmp/qs_all_apps.txt"
        onTextChanged: {
            const text = appsFile.text()
            if (!text || text.trim() === "") return
            const lines = text.trim().split("\n")
            const result = []
            for (let i = 0; i < lines.length; i++) {
                const parts = lines[i].split("|")
                if (parts.length === 3) {
                    result.push({ name: parts[0], icon: parts[1], exec: parts[2] })
                }
            }
            panel.allApps = result
        }
    }

    Process {
        id: listProcess
        command: ["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/list-apps.sh"]
        running: true
        onExited: appsFile.reload()
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

    Timer {
        id: appListReloadTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: listProcess.running = true
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
                radius: 8
                color: searchInput.activeFocus ? "#504945" : "#3c3836"
                border.color: searchInput.activeFocus ? "#b8bb26" : "#504945"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: searchInput.forceActiveFocus()
                }

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                    color: "#ebdbb2"
                    cursorVisible: activeFocus
                    onTextChanged: panel.updateFilter()
                    Keys.onEscapePressed: {
                        searchInput.text = ""
                        searchInput.focus = false
                        panel.filteredApps = []
                        panel.searchActive = false
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                    color: "#665c54"
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
                        appName: modelData.name
                        iconName: modelData.icon
                        execCmd: modelData.exec
                        onLaunched: {
                            panel.trackLaunch(modelData.name, modelData.icon, modelData.exec)
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
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                    color: "#665c54"
                    text: "Resultados"
                    visible: panel.filteredApps.length > 0
                    topPadding: 4
                    bottomPadding: 2
                }

                Repeater {
                    model: panel.filteredApps
                    delegate: MenuAppItem {
                        required property var modelData
                        width: parent.width
                        appName: modelData.name
                        iconName: modelData.icon
                        execCmd: modelData.exec
                        onLaunched: {
                            panel.trackLaunch(modelData.name, modelData.icon, modelData.exec)
                            panel.requestClose()
                        }
                    }
                }

                Text {
                    width: parent.width
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                    color: "#665c54"
                    text: "Sin resultados"
                    visible: panel.filteredApps.length === 0
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: "#3c3836"
            opacity: 0.7
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
                panel.filteredApps = []
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
