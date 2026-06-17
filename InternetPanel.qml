import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: panel
    readonly property int panelWidth: 260
    width: panelWidth
    height: 200

    property bool hasInternet: false
    property bool isEthernet: false
    property var wifiList: []
    property string connectedSsid: ""
    property string selectedSsid: ""
    property string password: ""
    property bool passwordVisible: false
    property string connectionStatus: ""
    property bool scanning: false

    // Real-time speed
    property real prevRx: 0
    property real prevTx: 0
    property string speedRxStr: "0 B/s"
    property string speedTxStr: "0 B/s"

    // Monthly accumulation
    property real monthRx: 0
    property real monthTx: 0
    property bool fetchingNet: false
    property string currentDevice: ""

    function formatSpeed(bps) {
        if (bps < 1) return "0 B/s"
        if (bps < 1024) return bps.toFixed(0) + " B/s"
        if (bps < 1048576) return (bps / 1024).toFixed(1) + " KB/s"
        if (bps < 1073741824) return (bps / 1048576).toFixed(1) + " MB/s"
        return (bps / 1073741824).toFixed(2) + " GB/s"
    }

    function formatBytes(n) {
        if (n < 1) return "0 B"
        if (n < 1024) return n.toFixed(0) + " B"
        if (n < 1048576) return (n / 1024).toFixed(1) + " KB"
        if (n < 1073741824) return (n / 1048576).toFixed(1) + " MB"
        return (n / 1073741824).toFixed(2) + " GB"
    }

    function parseWifiList(text) {
        if (!text || text.trim() === "") { panel.wifiList = []; return }
        const lines = text.trim().split("\n")
        const result = []
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (!line) continue
            const parts = line.split(":")
            if (parts.length < 3) continue
            const inuse = parts[0]
            const signal = parseInt(parts[parts.length - 2])
            const security = parts[parts.length - 1]
            const ssidParts = parts.slice(1, parts.length - 2)
            const ssid = ssidParts.join(":")
            if (!ssid || ssid.length === 0) continue
            result.push({
                inuse: inuse === "*",
                ssid: ssid,
                signal: isNaN(signal) ? 0 : signal,
                security: security
            })
        }
        panel.wifiList = result
    }

    Process {
        id: scanProcess
        command: ["bash", "-c", "nmcli --terse --fields IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null"]
        stdout: StdioCollector { id: scanOutput; waitForEnd: true }
        onExited: {
            const text = scanOutput.data.toString()
            panel.parseWifiList(text)
        }
    }

    Process {
        id: fullScanProcess
        command: ["bash", "-c", "nmcli --terse --fields IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan yes 2>/dev/null"]
        stdout: StdioCollector { id: fullScanOutput; waitForEnd: true }
        onExited: {
            panel.scanning = false
            const text = fullScanOutput.data.toString()
            panel.parseWifiList(text)
        }
    }

    Process {
        id: connectProcess
        property string connectSsid: ""
        property string connectPassword: ""
        command: ["bash", "-c", "result=$(nmcli dev wifi connect \"" + connectSsid + "\" password \"" + connectPassword + "\" 2>&1); echo \"$result\" > /tmp/qs_wifi_connect.txt; if echo \"$result\" | grep -qiE \"successfully activated|connected\"; then exit 0; else exit 1; fi"]
        onExited: {
            connectResultFile.reload()
            fullScanProcess.running = true
        }
    }

    FileView {
        id: connectResultFile
        path: "/tmp/qs_wifi_connect.txt"
        onTextChanged: {
            const text = connectResultFile.text().trim()
            if (text.includes("successfully activated") || text.includes("already active")) {
                panel.connectionStatus = "connected"
            } else {
                panel.connectionStatus = "incorrect"
            }
        }
    }

    Process {
        id: statusReader
        command: ["bash", "-c", "nmcli -t -f STATE general status > /tmp/qs_inet_state.txt 2>/dev/null; nmcli -t -f TYPE,DEVICE connection show --active 2>/dev/null | grep -E '802-11-wireless|802-3-ethernet' | head -1 > /tmp/qs_inet_type.txt; nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep '802-11-wireless' | head -1 | cut -d: -f1 > /tmp/qs_inet_ssid.txt"]
        running: true
        onExited: {
            stateFile.reload()
            typeFile.reload()
            ssidFile.reload()
        }
    }

    FileView {
        id: stateFile
        path: "/tmp/qs_inet_state.txt"
        onTextChanged: {
            panel.hasInternet = stateFile.text().trim() === "connected"
        }
    }

    FileView {
        id: typeFile
        path: "/tmp/qs_inet_type.txt"
        onTextChanged: {
            const text = typeFile.text().trim()
            if (!text) { panel.isEthernet = false; return }
            panel.isEthernet = text.includes("802-3-ethernet")
            if (!panel.isEthernet) {
                scanProcess.running = true
            }
            const device = text.includes(":") ? text.split(":")[1] || "" : ""
            if (device !== panel.currentDevice) {
                panel.currentDevice = device
                panel.prevRx = 0
                panel.prevTx = 0
                netReader.running = true
            }
        }
    }

    FileView {
        id: ssidFile
        path: "/tmp/qs_inet_ssid.txt"
        onTextChanged: {
            panel.connectedSsid = ssidFile.text().trim()
        }
    }

    Process {
        id: netReader
        command: ["bash", "-c", "dev=$(cat /tmp/qs_inet_type.txt 2>/dev/null | cut -d: -f2); if [ -n \"$dev\" ] && [ -d \"/sys/class/net/$dev/statistics\" ]; then rx=$(cat /sys/class/net/$dev/statistics/rx_bytes); tx=$(cat /sys/class/net/$dev/statistics/tx_bytes); echo \"$rx:$tx\"; else echo \"0:0\"; fi"]
        stdout: StdioCollector { id: netOutput; waitForEnd: true }
        onStarted: panel.fetchingNet = true
        onExited: {
            panel.fetchingNet = false
            const text = netOutput.data.toString().trim()
            const parts = text.split(":")
            if (parts.length >= 2) {
                const curRx = parseFloat(parts[0])
                const curTx = parseFloat(parts[1])
                if (panel.prevRx > 0 && panel.prevTx > 0) {
                    const deltaRx = (curRx - panel.prevRx) * 2  // *2 because 500ms interval = 0.5s -> 1s rate
                    const deltaTx = (curTx - panel.prevTx) * 2
                    if (deltaRx >= 0) {
                        panel.speedRxStr = panel.formatSpeed(deltaRx)
                        panel.monthRx += deltaRx
                    }
                    if (deltaTx >= 0) {
                        panel.speedTxStr = panel.formatSpeed(deltaTx)
                        panel.monthTx += deltaTx
                    }
                }
                panel.prevRx = curRx
                panel.prevTx = curTx
            }
        }
    }

    Process {
        id: monthLoader
        command: [
            "python3", "-c",
            "import sys,os,json; p=os.path.expanduser('~/.cache/quickshell/network_month.json'); print(open(p).read() if os.path.exists(p) else '{}')"
        ]
        stdout: StdioCollector { id: monthLoadOutput; waitForEnd: true }
        running: true
        onExited: {
            const text = monthLoadOutput.data.toString().trim()
            if (!text || text === "{}") return
            try {
                const data = JSON.parse(text)
                const now = new Date()
                if (data.year === now.getFullYear() && data.month === now.getMonth() + 1) {
                    panel.monthRx = parseFloat(data.rx) || 0
                    panel.monthTx = parseFloat(data.tx) || 0
                }
            } catch (e) {}
        }
    }

    Process {
        id: monthSaver
        property string saveJson: ""
        command: [
            "python3", "-c",
            "import sys,os,json; os.makedirs(os.path.expanduser('~/.cache/quickshell'), exist_ok=True); open(os.path.expanduser('~/.cache/quickshell/network_month.json'),'w').write(sys.argv[1])",
            saveJson
        ]
    }

    Timer {
        id: netTimer
        interval: 1000
        running: panel.hasInternet
        repeat: true
        onTriggered: { if (!panel.fetchingNet) netReader.running = true }
    }

    Timer {
        id: refreshTimer
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            statusReader.running = true
        }
    }

    Timer {
        id: monthSaveTimer
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date()
            const json = JSON.stringify({ rx: panel.monthRx, tx: panel.monthTx, year: now.getFullYear(), month: now.getMonth() + 1 })
            monthSaver.saveJson = json
            monthSaver.running = true
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 14
        contentHeight: contentCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: contentCol
            width: parent.width
            spacing: 8

            Text {
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize11
                color: Theme.textMuted
                text: "\uF1EB Internet"
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface
            }

            Item {
                width: parent.width
                height: childrenRect.height
                visible: panel.hasInternet && panel.isEthernet

                Column {
                    width: parent.width
                    spacing: 6

                    Text {
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize10
                        color: Theme.textSecondary
                        text: "\uEF44 Ethernet"
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.surface }

                    Row {
                        width: parent.width
                        spacing: 8

                        Column {
                            width: (parent.width - 8) / 2
                            spacing: 2

                            Text {
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize9
                                color: Theme.textMuted
                                text: "Bajada"
                            }

                            Text {
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize10
                                color: Theme.accent
                                text: panel.speedRxStr
                            }
                        }

                        Column {
                            width: (parent.width - 8) / 2
                            spacing: 2

                            Text {
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize9
                                color: Theme.textMuted
                                text: "Subida"
                            }

                            Text {
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize10
                                color: Theme.accent
                                text: panel.speedTxStr
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.surface }

                    Text {
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize9
                        color: Theme.textTertiary
                        text: "Este mes: " + panel.formatBytes(panel.monthRx) + " \u2193  " + panel.formatBytes(panel.monthTx) + " \u2191"
                    }
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height
                visible: !panel.hasInternet

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize12
                    color: Theme.accentRed
                    text: "No hay internet"
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height
                visible: panel.hasInternet && !panel.isEthernet

                Column {
                    width: parent.width
                    spacing: 6

                    Item {
                        width: parent.width
                        height: childrenRect.height

                        Text {
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize10
                            color: Theme.textSecondary
                            text: "\uF1EB WiFi"
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        Column {
                            width: (parent.width - 8) / 2
                            spacing: 2

                            Text {
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize9
                                color: Theme.textMuted
                                text: "Bajada"
                            }

                            Text {
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize10
                                color: Theme.accent
                                text: panel.speedRxStr
                            }
                        }

                        Column {
                            width: (parent.width - 8) / 2
                            spacing: 2

                            Text {
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize9
                                color: Theme.textMuted
                                text: "Subida"
                            }

                            Text {
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize10
                                color: Theme.accent
                                text: panel.speedTxStr
                            }
                        }
                    }

                    Text {
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize9
                        color: Theme.textTertiary
                        text: "Este mes: " + panel.formatBytes(panel.monthRx) + " \u2193  " + panel.formatBytes(panel.monthTx) + " \u2191"
                    }

                    Rectangle { width: parent.width; height: 1; color: Theme.surface }

                    Rectangle {
                        width: parent.width
                        height: 28
                        radius: Theme.radius4
                        color: refreshBtn.containsMouse ? Theme.surfaceHover : "transparent"
                        border.color: Theme.border
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize11
                            color: panel.scanning ? Theme.textSecondary : Theme.textPrimary
                            text: panel.scanning ? "Escaneando..." : "Escaneá redes"
                        }
                        MouseArea {
                            id: refreshBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (panel.scanning) return
                                panel.scanning = true
                                panel.connectionStatus = ""
                                panel.selectedSsid = ""
                                panel.password = ""
                                fullScanProcess.running = true
                            }
                        }
                    }

                    Text {
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize11
                        color: Theme.textMuted
                        text: "Redes disponibles"
                    }

                    Repeater {
                        model: panel.wifiList

                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: parent.width
                            height: {
                                if (panel.selectedSsid === modelData.ssid)
                                    return 28 + (panel.connectionStatus !== "" ? 20 : 60)
                                return 28
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radius4
                                color: {
                                    if (panel.connectionStatus === "incorrect" && panel.selectedSsid === modelData.ssid)
                                        return Theme.accentRed
                                    if (rowHover.hovered) return Theme.surfaceHover
                                    return "transparent"
                                }
                            }

                            HoverHandler { id: rowHover }

                            Text {
                                id: ssidText
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.right: signalText.left
                                anchors.rightMargin: 4
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize10
                                color: {
                                    if (modelData.inuse) return Theme.accent
                                    if (panel.selectedSsid === modelData.ssid && panel.connectionStatus === "incorrect") return Theme.textPrimary
                                    return Theme.textSecondary
                                }
                                text: {
                                    if (modelData.inuse) return "\u25CF " + modelData.ssid + "  \u2713"
                                    if (panel.selectedSsid === modelData.ssid && panel.connectionStatus === "incorrect") return "\u25CB " + modelData.ssid
                                    return "\u25CB " + modelData.ssid
                                }
                            }

                            Text {
                                id: signalText
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize10
                                color: {
                                    if (modelData.signal > 70) return Theme.accent
                                    if (modelData.signal > 40) return Theme.accentYellow
                                    return Theme.textMuted
                                }
                                text: {
                                    if (modelData.signal > 70) return "\uF1EB"
                                    if (modelData.signal > 40) return "\uF1EB"
                                    return "\uF1EB"
                                }
                                opacity: {
                                    if (modelData.signal > 70) return 1.0
                                    if (modelData.signal > 40) return 0.6
                                    return 0.3
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -2
                                visible: !modelData.inuse && (panel.selectedSsid !== modelData.ssid || panel.connectionStatus !== "connected")
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    panel.selectedSsid = modelData.ssid
                                    panel.password = ""
                                    panel.connectionStatus = ""
                                    panel.passwordVisible = false
                                }
                            }

                            Column {
                                visible: panel.selectedSsid === modelData.ssid && !modelData.inuse
                                anchors.top: parent.top
                                anchors.topMargin: 28
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                spacing: 4

                                Item {
                                    width: parent.width
                                    height: 22

                                    Rectangle {
                                        id: pwInput
                                        anchors.left: parent.left
                                        anchors.right: eyeBtn.left
                                        anchors.rightMargin: 4
                                        height: 22
                                        radius: 3
                                        color: Theme.surface
                                        border.color: panel.connectionStatus === "incorrect" ? Theme.accentRed : Theme.border
                                        border.width: 1

                                        TextInput {
                                            id: pwField
                                            anchors.fill: parent
                                            anchors.margins: 3
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize9
                                            color: Theme.textPrimary
                                            echoMode: panel.passwordVisible ? TextInput.Normal : TextInput.Password
                                            passwordCharacter: "\u2022"
                                            text: panel.password
                                            onTextChanged: panel.password = text
                                            focus: true
                                        }
                                    }

                                    Item {
                                        id: eyeBtn
                                        anchors.right: connectBtn.left
                                        anchors.rightMargin: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18

                                        Text {
                                            anchors.centerIn: parent
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize12
                                            color: eyeBtnArea.containsMouse ? Theme.textPrimary : Theme.textMuted
                                            text: panel.passwordVisible ? "\uF070" : "\uF06E"
                                        }

                                        MouseArea {
                                            id: eyeBtnArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: panel.passwordVisible = !panel.passwordVisible
                                        }
                                    }

                                    Rectangle {
                                        id: connectBtn
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 50
                                        height: 18
                                        radius: 3
                                        color: "transparent"
                                        border.color: Theme.accentBlue
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSize9
                                            color: Theme.accentBlueBright
                                            text: "Conectar"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (!panel.password) return
                                                panel.connectionStatus = ""
                                                connectProcess.connectSsid = modelData.ssid
                                                connectProcess.connectPassword = panel.password
                                                connectProcess.running = true
                                            }
                                        }
                                    }
                                }

                                Text {
                                    height: 16
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize9
                                    color: panel.connectionStatus === "connected" ? Theme.accent : Theme.accentRedBright
                                    text: {
                                        if (panel.connectionStatus === "connected") return "Conectado"
                                        if (panel.connectionStatus === "incorrect") return "Incorrecta"
                                        return ""
                                    }
                                    visible: panel.connectionStatus !== ""
                                }
                            }

                            Text {
                                visible: modelData.inuse
                                anchors.top: parent.top
                                anchors.topMargin: 14
                                anchors.left: parent.left
                                anchors.leftMargin: 6
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize8
                                color: Theme.accent
                                text: "Conectado"
                            }
                        }
                    }

                    Text {
                        visible: panel.wifiList.length === 0 && !panel.scanning
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize10
                        color: Theme.border
                        text: "No hay redes"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
