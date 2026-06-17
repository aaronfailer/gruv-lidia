import Quickshell
import QtQuick
import "."

PanelWindow {
    visible: false
    width: 0
    height: 0

    LeftBar {
        id: leftBar
        borderTopInset: 9
        borderBottomInset: 0
        onCalendarOpenChanged: if (calendarOpen) { topBar.notificationOpen = false; bottomBorder.weatherOpen = false }
        onTrayOpenChanged: if (trayOpen) { topBar.notificationOpen = false; bottomBorder.weatherOpen = false }
        onVolumeOpenChanged: if (volumeOpen) { topBar.notificationOpen = false; bottomBorder.weatherOpen = false }
        onWallpaperOpenChanged: if (wallpaperOpen) { topBar.notificationOpen = false; bottomBorder.weatherOpen = false }
        onMenuOpenChanged: if (menuOpen) { topBar.notificationOpen = false; bottomBorder.weatherOpen = false }
        onPowerOpenChanged: if (powerOpen) { topBar.notificationOpen = false; bottomBorder.weatherOpen = false }
        onBluetoothOpenChanged: if (bluetoothOpen) { topBar.notificationOpen = false; bottomBorder.weatherOpen = false }
        onInternetOpenChanged: if (internetOpen) { topBar.notificationOpen = false; bottomBorder.weatherOpen = false }
        onUpdateOpenChanged: if (updateOpen) { topBar.notificationOpen = false; bottomBorder.weatherOpen = false }
        onFileOpenChanged: if (fileOpen) { bottomBorder.weatherOpen = false }
    }

    TopBar {
        id: topBar
        onNotificationOpenChanged: {
            if (notificationOpen) {
                leftBar.calendarOpen = false
                leftBar.trayOpen = false
                leftBar.volumeOpen = false
                leftBar.wallpaperOpen = false
                leftBar.menuOpen = false
                leftBar.powerOpen = false
                leftBar.bluetoothOpen = false
                leftBar.internetOpen = false
                leftBar.updateOpen = false
                bottomBorder.weatherOpen = false
            }
        }
    }

    BottomBorder {
        id: bottomBorder
        onWeatherOpenChanged: {
            if (weatherOpen) {
                leftBar.calendarOpen = false
                leftBar.trayOpen = false
                leftBar.volumeOpen = false
                leftBar.wallpaperOpen = false
                leftBar.menuOpen = false
                leftBar.powerOpen = false
                leftBar.bluetoothOpen = false
                leftBar.internetOpen = false
                leftBar.updateOpen = false
                leftBar.fileOpen = false
                topBar.notificationOpen = false
            }
        }
    }

    RightBorder {
        borderTopInset: 19
        borderBottomInset: 15
    }
}
