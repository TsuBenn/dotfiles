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

        tokyoNight: {
            id: "tokyoNight",
            accentStrong:  "#7AA2F7",
            accentSoft:    "#BB9AF7",

            bgBase:        "#16161E",
            bgSurface:     "#1A1B26",
            bgMuted:       "#292E42",

            textPrimary:   "#C0CAF5",
            textSecondary: "#1A1B26",
            textDisabled:  "#565F89",

            info:          "#7DCFFF",
            error:         "#F7768E",
            warn:          "#E0AF68",
            success:       "#9ECE6A"
        },

        catppuccin: {
            id: "catppuccin",
            accentStrong:  "#CBA6F7",
            accentSoft:    "#F5C2E7",

            bgBase:        "#1E1E2E",
            bgSurface:     "#181825",
            bgMuted:       "#313244",

            textPrimary:   "#CDD6F4",
            textSecondary: "#1E1E2E",
            textDisabled:  "#6C7086",

            info:          "#89DCEB",
            error:         "#F38BA8",
            warn:          "#F9E2AF",
            success:       "#A6E3A1"
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

        nord: {
            id: "nord",
            accentStrong:  "#88C0D0",
            accentSoft:    "#8FBCBB",

            bgBase:        "#2E3440",
            bgSurface:     "#3B4252",
            bgMuted:       "#434C5E",

            textPrimary:   "#ECEFF4",
            textSecondary: "#2E3440",
            textDisabled:  "#6D7486",

            info:          "#81A1C1",
            error:         "#BF616A",
            warn:          "#EBCB8B",
            success:       "#A3BE8C"
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

        solarizedDark: {
            id: "solarizedDark",
            accentStrong:  "#268BD2",
            accentSoft:    "#2AA198",

            bgBase:        "#002B36",
            bgSurface:     "#073642",
            bgMuted:       "#586E75",

            textPrimary:   "#EEE8D5",
            textSecondary: "#002B36",
            textDisabled:  "#657B83",

            info:          "#268BD2",
            error:         "#DC322F",
            warn:          "#B58900",
            success:       "#859900"
        },

        onedark: {
            id: "onedark",
            accentStrong:  "#61AFEF",
            accentSoft:    "#C678DD",

            bgBase:        "#1E2127",
            bgSurface:     "#282C34",
            bgMuted:       "#3E4451",

            textPrimary:   "#ABB2BF",
            textSecondary: "#1E2127",
            textDisabled:  "#5C6370",

            info:          "#56B6C2",
            error:         "#E06C75",
            warn:          "#E5C07B",
            success:       "#98C379"
        },

        ayuDark: {
            id: "ayuDark",
            accentStrong:  "#FFCC66",
            accentSoft:    "#FFAE57",

            bgBase:        "#0F1419",
            bgSurface:     "#131721",
            bgMuted:       "#272D38",

            textPrimary:   "#E6E1CF",
            textSecondary: "#0F1419",
            textDisabled:  "#5C6773",

            info:          "#5CCFE6",
            error:         "#FF3333",
            warn:          "#FFD173",
            success:       "#BAE67E"
        },

        materialOcean: {
            id: "materialOcean",
            accentStrong:  "#82AAFF",
            accentSoft:    "#C792EA",

            bgBase:        "#0F111A",
            bgSurface:     "#1A1C25",
            bgMuted:       "#303340",

            textPrimary:   "#EEFFFF",
            textSecondary: "#0F111A",
            textDisabled:  "#545B77",

            info:          "#89DDFF",
            error:         "#FF5370",
            warn:          "#FFCB6B",
            success:       "#C3E88D"
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

        nightFox: {
            id: "nightFox",
            accentStrong:  "#719CD6",
            accentSoft:    "#C94F6D",

            bgBase:        "#192330",
            bgSurface:     "#1E293B",
            bgMuted:       "#2A3B54",

            textPrimary:   "#CDCECF",
            textSecondary: "#192330",
            textDisabled:  "#738091",

            info:          "#63CDCF",
            error:         "#C94F6D",
            warn:          "#E0C989",
            success:       "#81B29A"
        },

        duskFox: {
            id: "duskFox",
            accentStrong:  "#7AA2F7",
            accentSoft:    "#F7768E",

            bgBase:        "#252434",
            bgSurface:     "#2C2B3C",
            bgMuted:       "#3A3A5A",

            textPrimary:   "#E0DEF4",
            textSecondary: "#252434",
            textDisabled:  "#6E6A86",

            info:          "#9CCFD8",
            error:         "#F7768E",
            warn:          "#E0AF68",
            success:       "#9ECE6A"
        },

        midnightBloom: {
            id: "midnightBloom",
            accentStrong:  "#C792EA",
            accentSoft:    "#82AAFF",

            bgBase:        "#0B0E14",
            bgSurface:     "#131721",
            bgMuted:       "#1E2433",

            textPrimary:   "#DADFEF",
            textSecondary: "#0B0E14",
            textDisabled:  "#5C6370",

            info:          "#89DDFF",
            error:         "#FF5370",
            warn:          "#FFCB6B",
            success:       "#C3E88D"
        },

        coffee: {
            id: "coffee",
            accentStrong:  "#C08B5C",
            accentSoft:    "#E3C29B",

            bgBase:        "#1A1410",
            bgSurface:     "#221A15",
            bgMuted:       "#2F241D",

            textPrimary:   "#F1E8E3",
            textSecondary: "#1A1410",
            textDisabled:  "#8C7A6B",

            info:          "#7FA1C3",
            error:         "#C85C5C",
            warn:          "#D9A441",
            success:       "#8FB573"
        },

        sakuraNight: {
            id: "sakuraNight",
            accentStrong:  "#F28FAD",
            accentSoft:    "#F5C2E7",

            bgBase:        "#140F14",
            bgSurface:     "#1C1620",
            bgMuted:       "#2B2230",

            textPrimary:   "#F4E7EE",
            textSecondary: "#140F14",
            textDisabled:  "#9A8A96",

            info:          "#89B4FA",
            error:         "#F38BA8",
            warn:          "#F9E2AF",
            success:       "#A6E3A1"
        },

        obsidian: {
            id: "obsidian",
            accentStrong:  "#4FC1FF",
            accentSoft:    "#9CDCFE",

            bgBase:        "#0F1117",
            bgSurface:     "#151820",
            bgMuted:       "#1F2430",

            textPrimary:   "#D4D4D4",
            textSecondary: "#0F1117",
            textDisabled:  "#6A6A6A",

            info:          "#4FC1FF",
            error:         "#F44747",
            warn:          "#FFAF00",
            success:       "#6A9955"
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

        abyss: {
            id: "abyss",
            accentStrong:  "#5DA9E9",
            accentSoft:    "#9AD1F5",

            bgBase:        "#05080E",
            bgSurface:     "#0B1220",
            bgMuted:       "#162038",

            textPrimary:   "#DCE7F5",
            textSecondary: "#05080E",
            textDisabled:  "#5B6B8C",

            info:          "#5DA9E9",
            error:         "#E5533D",
            warn:          "#F2A65A",
            success:       "#7BD389"
        },

        neonVoid: {
            id: "neonVoid",
            accentStrong:  "#FF3CAC",
            accentSoft:    "#784BA0",

            bgBase:        "#0B0715",
            bgSurface:     "#120C1F",
            bgMuted:       "#24193A",

            textPrimary:   "#F5ECFF",
            textSecondary: "#0B0715",
            textDisabled:  "#8B7FAE",

            info:          "#2DE2E6",
            error:         "#FF3864",
            warn:          "#FFB000",
            success:       "#3DFFAE"
        },

        frostbite: {
            id: "frostbite",
            accentStrong:  "#8FD3F4",
            accentSoft:    "#84FAB0",

            bgBase:        "#0A141C",
            bgSurface:     "#10202C",
            bgMuted:       "#1B3446",

            textPrimary:   "#E6F7FF",
            textSecondary: "#0A141C",
            textDisabled:  "#6B8799",

            info:          "#5BC0EB",
            error:         "#E85D75",
            warn:          "#FFD166",
            success:       "#4ADE80"
        },

        cyberpunk: {
            id: "cyberpunk",
            accentStrong:  "#FCEE0C",
            accentSoft:    "#FF2A6D",

            bgBase:        "#0D0221",
            bgSurface:     "#1A093D",
            bgMuted:       "#2E1A63",

            textPrimary:   "#EAF2FF",
            textSecondary: "#0D0221",
            textDisabled:  "#8677A8",

            info:          "#00F0FF",
            error:         "#FF0054",
            warn:          "#FF9F1C",
            success:       "#2AFF00"
        },

        jadeMist: {
            id: "jadeMist",
            accentStrong:  "#2EC4B6",
            accentSoft:    "#CBF3F0",

            bgBase:        "#081C1A",
            bgSurface:     "#0E2A27",
            bgMuted:       "#17413C",

            textPrimary:   "#E8F9F6",
            textSecondary: "#081C1A",
            textDisabled:  "#7FAAA3",

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

        voidLotus: {
            id: "voidLotus",
            accentStrong:  "#C77DFF",
            accentSoft:    "#E0AAFF",

            bgBase:        "#0A0614",
            bgSurface:     "#120B24",
            bgMuted:       "#24164A",

            textPrimary:   "#F4EFFF",
            textSecondary: "#0A0614",
            textDisabled:  "#8F7FB3",

            info:          "#4CC9F0",
            error:         "#F72585",
            warn:          "#FFCA3A",
            success:       "#72EFDD"
        }

    })

}

