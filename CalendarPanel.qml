import QtQuick
import "."

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
        radius: Theme.radius16
        color: Theme.background
        border.color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85)
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: Theme.backgroundAlt
            opacity: Theme.opacitySubtle
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
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize13
                font.weight: Theme.fontWeightMedium
                color: Theme.textPrimary
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
            color: Theme.surface
            opacity: panel.showChrome ? Theme.opacityDim : 0.45
        }

        CalendarMonthGrid {
            anchors.horizontalCenter: parent.horizontalCenter
            year: panel.viewYear
            month: panel.viewMonth
        }
    }
}
