import QtQuick

Item {
    id: panel

    readonly property int panelWidth: 260
    readonly property int panelHeight: 270
    width: panelWidth
    implicitHeight: panelHeight

    property bool showChrome: true
    property real deployProgress: 1

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()

    readonly property var monthNames: [
        "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ]

    function previousMonth() {
        if (viewMonth === 0) {
            viewMonth = 11
            viewYear -= 1
        } else {
            viewMonth -= 1
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0
            viewYear += 1
        } else {
            viewMonth += 1
        }
    }

    function goToToday() {
        const n = new Date()
        viewYear = n.getFullYear()
        viewMonth = n.getMonth()
    }

    Rectangle {
        id: card

        anchors.fill: parent
        visible: panel.showChrome
        radius: 16
        color: "#1d2021"
        border.color: Qt.rgba(60 / 255, 56 / 255, 54 / 255, 0.85)
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "#282828"
            opacity: 0.35
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Row {
            width: parent.width
            spacing: 6

            Text {
                width: parent.width - navRow.width
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                height: 28
                text: panel.monthNames[panel.viewMonth] + " " + panel.viewYear
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: "#ebdbb2"
            }

            Row {
                id: navRow
                spacing: 4
                height: 28

                CalendarNavButton {
                    glyph: "‹"
                    onClicked: panel.previousMonth()
                }

                CalendarNavButton {
                    glyph: "›"
                    onClicked: panel.nextMonth()
                }

                CalendarNavButton {
                    glyph: "•"
                    onClicked: panel.goToToday()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#3c3836"
            opacity: panel.showChrome ? 0.7 : 0.45
        }

        CalendarMonthGrid {
            anchors.horizontalCenter: parent.horizontalCenter
            year: panel.viewYear
            month: panel.viewMonth
        }
    }
}
