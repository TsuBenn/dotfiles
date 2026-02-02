pragma Singleton

import qs.services

import Quickshell
import QtQuick

Singleton {
    id: root

    property var colorList: Object.entries(colors).map(
        ([id, theme]) => {
            id: id

        }
    )

    property string current: "hutao"

    onCurrentChanged: {
        apply()
    }

    property color accentStrong
    property color accentSoft
    property color bgBase
    property color bgSurface
    property color bgMuted
    property color textPrimary
    property color textSecondary
    property color textDisabled

    property color info
    property color error
    property color warn
    property color success

    function saturate(c, factor) {
        return Qt.hsla(
            c.hslHue,
            Math.min(c.hslSaturation * factor, 1.0),
            c.hslLightness,
            c.a
        )
    }

    function transparent(c, factor) {
        return Qt.rgba(
            c.r,
            c.g,
            c.b,
            factor
        )
    }

    function mix(c1, c2, t) {
        if (t > 1) {t = 1}
        return blend(c1, c2, t)
    }

    function blend(c1: color, c2: color, t: real): color {
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            c1.a + (c2.a - c1.a) * t
        )
    }

    function apply() {
        const theme = colors[current]
        if (!theme) theme = colors["hutao"]

        accentStrong  = theme.accentStrong
        accentSoft    = theme.accentSoft
        bgBase        = theme.bgBase
        bgSurface     = theme.bgSurface
        bgMuted       = theme.bgMuted
        textPrimary   = theme.textPrimary
        textSecondary = theme.textSecondary
        textDisabled  = theme.textDisabled
        info          = theme.info
        error         = theme.error
        warn          = theme.warn
        success       = theme.success
    }

    Component.onCompleted: apply()

    property var colors: ({
        hutao: {
            id: "hutao",
            accentStrong:  "#a32435",
            accentSoft:    "#f59b75",

            bgBase:        "#151214",
            bgSurface:     "#1D191C",
            bgMuted:       "#2A2428",

            textPrimary:   "#EDE6E8",
            textSecondary: "#EDE6E8",
            textDisabled:  "#7A6F74",

            info:          "#2fbcf0",
            error:         "#ec2727",
            warn:          "#eea022",
            success:       "#38de31"
        },

        kazuha: {
            id: "kazuha",
            accentStrong:  "#5FB3A2", // jade / wind teal
            accentSoft:    "#D97C6B", // maple red

            bgBase:        "#121614",
            bgSurface:     "#171C19",
            bgMuted:       "#2A322E",

            textPrimary:   "#DDE5E1",
            textSecondary: "#121614",
            textDisabled:  "#6F7F78",

            info:          "#6EC4B8",
            error:         "#E06C75",
            warn:          "#E5B567",
            success:       "#98C379"
        },

        gruvbox: {
            id: "gruvbox",
            accentStrong:  "#D79921",
            accentSoft:    "#FABD2F",

            bgBase:        "#1D2021",
            bgSurface:     "#282828",
            bgMuted:       "#3C3836",

            textPrimary:   "#EBDBB2",
            textSecondary: "#1D2021",
            textDisabled:  "#7C6F64",

            info:          "#83A598",
            error:         "#FB4934",
            warn:          "#FE8019",
            success:       "#B8BB26"
        },

        rosePine: {
            id: "rosePine",
            accentStrong:  "#EBBCBA",
            accentSoft:    "#F6C177",

            bgBase:        "#191724",
            bgSurface:     "#1F1D2E",
            bgMuted:       "#26233A",

            textPrimary:   "#E0DEF4",
            textSecondary: "#191724",
            textDisabled:  "#6E6A86",

            info:          "#9CCFD8",
            error:         "#EB6F92",
            warn:          "#F6C177",
            success:       "#31748F"
        },

        kanagawa: {
            id: "kanagawa",
            accentStrong:  "#7E9CD8",
            accentSoft:    "#DCA561",

            bgBase:        "#1F1F28",
            bgSurface:     "#2A2A37",
            bgMuted:       "#363646",

            textPrimary:   "#DCD7BA",
            textSecondary: "#1F1F28",
            textDisabled:  "#727169",

            info:          "#7FB4CA",
            error:         "#E46876",
            warn:          "#E6C384",
            success:       "#98BB6C"
        },

        monokaiPro: {
            id: "monokaiPro",
            accentStrong:  "#FC9867",
            accentSoft:    "#FFD866",

            bgBase:        "#1C1C1C",
            bgSurface:     "#2D2A2E",
            bgMuted:       "#403E41",

            textPrimary:   "#FCFCFA",
            textSecondary: "#1C1C1C",
            textDisabled:  "#727072",

            info:          "#78DCE8",
            error:         "#FF6188",
            warn:          "#FFD866",
            success:       "#A9DC76"
        },

        emeraldNight: {
            id: "emeraldNight",
            accentStrong:  "#2EC4B6",
            accentSoft:    "#90DBD0",

            bgBase:        "#081B1B",
            bgSurface:     "#0E2424",
            bgMuted:       "#163636",

            textPrimary:   "#D7F5F2",
            textSecondary: "#081B1B",
            textDisabled:  "#6F9E9A",

            info:          "#48CAE4",
            error:         "#E63946",
            warn:          "#F4A261",
            success:       "#2A9D8F"
        },

        sunsetEmber: {
            id: "sunsetEmber",
            accentStrong:  "#FF7A18",
            accentSoft:    "#FFD166",

            bgBase:        "#1A0F0A",
            bgSurface:     "#24140D",
            bgMuted:       "#3A2014",

            textPrimary:   "#FFEDE0",
            textSecondary: "#1A0F0A",
            textDisabled:  "#B18B73",

            info:          "#5BC0EB",
            error:         "#E5383B",
            warn:          "#FFB703",
            success:       "#80ED99"
        },

    })

}

