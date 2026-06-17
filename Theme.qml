pragma Singleton
import QtQuick

QtObject {
    property bool isDark: true

    property var darkOverrides: ({})
    property var lightOverrides: ({})
    property var overrides: ({})

    property color background: isDark ? (overrides.background || "#1d2021") : (overrides.background || "#fbf1c7")
    property color backgroundAlt: isDark ? (overrides.backgroundAlt || "#282828") : (overrides.backgroundAlt || "#ebdbb2")
    property color surface: isDark ? (overrides.surface || "#3c3836") : (overrides.surface || "#d5c4a1")
    property color surfaceHover: isDark ? (overrides.surfaceHover || "#504945") : (overrides.surfaceHover || "#bdae93")

    property color border: isDark ? (overrides.border || "#504945") : (overrides.border || "#32302f")
    property color borderFocus: isDark ? (overrides.borderFocus || "#b8bb26") : (overrides.borderFocus || "#32302f")

    property color textPrimary: isDark ? (overrides.textPrimary || "#ebdbb2") : (overrides.textPrimary || "#32302f")
    property color textSecondary: isDark ? (overrides.textSecondary || "#a89984") : (overrides.textSecondary || "#32302f")
    property color textMuted: isDark ? (overrides.textMuted || "#928374") : (overrides.textMuted || "#32302f")
    property color textDim: isDark ? (overrides.textDim || "#665c54") : (overrides.textDim || "#32302f")
    property color textInactive: isDark ? (overrides.textInactive || "#504945") : (overrides.textInactive || "#32302f")
    property color textTertiary: isDark ? (overrides.textTertiary || "#d5c4a1") : (overrides.textTertiary || "#32302f")
    property color textDisabled: isDark ? (overrides.textDisabled || "#665c54") : (overrides.textDisabled || "#928374")

    property color accent: isDark ? (overrides.accent || "#b8bb26") : (overrides.accent || "#79740e")
    property color accentYellow: isDark ? (overrides.accentYellow || "#fabd2f") : (overrides.accentYellow || "#b57614")
    property color accentRed: isDark ? (overrides.accentRed || "#cc241d") : (overrides.accentRed || "#9d0006")
    property color accentRedBright: isDark ? (overrides.accentRedBright || "#fb4934") : (overrides.accentRedBright || "#cc241d")
    property color accentBlue: isDark ? (overrides.accentBlue || "#458588") : (overrides.accentBlue || "#076678")
    property color accentBlueBright: isDark ? (overrides.accentBlueBright || "#83a598") : (overrides.accentBlueBright || "#076678")

    property color iconWidget: isDark ? (overrides.iconWidget || "#b8bb26") : (overrides.iconWidget || "#32302f")
    property color iconWidgetOpen: isDark ? (overrides.iconWidgetOpen || "#fabd2f") : (overrides.iconWidgetOpen || "#b8bb26")

    property string fontFamily: "FiraCode Nerd Font"
    property int fontSize8: 8
    property int fontSize9: 9
    property int fontSize10: 10
    property int fontSize11: 11
    property int fontSize12: 12
    property int fontSize13: 13
    property int fontSize14: 14
    property int fontSize16: 16
    property int fontSize48: 48

    property int fontWeightNormal: Font.Normal
    property int fontWeightMedium: Font.Medium
    property int fontWeightDemiBold: Font.DemiBold
    property int fontWeightBold: Font.Bold

    property int radius3: 3
    property int radius4: 4
    property int radius6: 6
    property int radius8: 8
    property int radius16: 16

    property real opacityHigh: 0.9
    property real opacityDim: 0.7
    property real opacityMedium: 0.6
    property real opacityDisabled: 0.4
    property real opacityFaint: 0.15
    property real opacitySubtle: 0.35

    function setOverride(key, value) {
        var target = isDark ? darkOverrides : lightOverrides
        var o = {}
        for (var k in target) o[k] = target[k]
        o[key] = value
        if (isDark) darkOverrides = o; else lightOverrides = o
        overrides = isDark ? darkOverrides : lightOverrides
    }

    function removeOverride(key) {
        var target = isDark ? darkOverrides : lightOverrides
        var o = {}
        for (var k in target) o[k] = target[k]
        delete o[key]
        if (isDark) darkOverrides = o; else lightOverrides = o
        overrides = isDark ? darkOverrides : lightOverrides
    }

    function loadOverrides(dark, light) {
        darkOverrides = dark || {}
        lightOverrides = light || {}
        overrides = isDark ? darkOverrides : lightOverrides
    }

    function toggle() {
        isDark = !isDark
        overrides = isDark ? darkOverrides : lightOverrides
    }
}
