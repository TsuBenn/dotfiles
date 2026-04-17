pragma Singleton

import qs.services

import Quickshell
import QtQuick

Singleton {
    id: root

    property string current: "hutao"

    onCurrentChanged: {
        if (Object.keys(colors).includes(current)) {
            apply()
        } else {
            NotificationsInfo.send("","","System",`Color palette "${current}" not found!`)
        }
    }

    signal applied()

    // Background
    property color bgBase
    property color bgSurface
    property color bgOverlay

    // Foreground
    property color fgBase
    property color onAccent
    property color fgDim
    property color fgSubtle

    // Accent
    property color accentStrong
    property color accentDim
    property color secondary
    property color info

    // Semantic
    property color success
    property color warning
    property color danger

    // Border
    property color borderActive
    property color borderInactive

    Behavior on bgBase {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on bgSurface {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on bgOverlay {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on fgBase {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on onAccent {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on fgDim {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on fgSubtle {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on accentStrong {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on accentDim {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on secondary {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on info {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on success {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on warning {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on danger {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}

    // Helpers
    function transparent(c, factor) {
        return Qt.rgba(c.r, c.g, c.b, factor)
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
        const theme = colors[current] ?? colors["hutao"]

        bgBase         = theme.bgBase
        bgSurface      = theme.bgSurface
        bgOverlay      = theme.bgOverlay

        fgBase         = theme.fgBase
        onAccent       = theme.onAccent
        fgDim          = theme.fgDim
        fgSubtle       = theme.fgSubtle

        accentStrong   = theme.accentStrong
        accentDim      = theme.accentDim
        secondary      = theme.secondary
        info           = theme.info

        success        = theme.success
        warning        = theme.warning
        danger         = theme.danger

        borderActive   = theme.borderActive
        borderInactive = theme.borderInactive

        root.applied()
    }

    Component.onCompleted: apply()

    property var colors: ({
        hutao:            {
            bgBase:       "#151214", bgSurface:      "#1D191C", bgOverlay: "#302A2F",
            fgBase:       "#EDE6E8", onAccent:       "#EDE6E8", fgDim:     "#A89BA0", fgSubtle: "#7A6F74",
            accentStrong: "#a32435", accentDim:      "#6B1825", secondary: "#f59b75", info:     "#3AA5DE",
            success:      "#98BB6C", warning:        "#eea022", danger:    "#ec2727",
            borderActive: "#a32435", borderInactive: "#2A2428",
        },
        seele:            {
            bgBase:       "#0e0913", bgSurface:      "#1f1d3e", bgOverlay: "#3b3a7a",
            fgBase:       "#f1eff7", onAccent:       "#ffffff", fgDim:     "#c2c6e1", fgSubtle: "#9796bf",
            accentStrong: "#ff3b5c", accentDim:      "#ba2d4a", secondary: "#ff52bf", info:     "#94afe1",
            success:      "#b8e986", warning:        "#f8a5c2", danger:    "#ff3b5c",
            borderActive: "#ff3b5c", borderInactive: "#2d2b55",
        },
        kazuha:           {
            bgBase:       "#1A1817", bgSurface:      "#24211F", bgOverlay: "#36322E",
            fgBase:       "#E6E1DC", onAccent:       "#1A1817", fgDim:     "#B5AEA8", fgSubtle: "#857D75",
            accentStrong: "#C24636", accentDim:      "#7A2C22", secondary: "#D9A166", info:     "#89A7A7",
            success:      "#8DA171", warning:        "#D4A052", danger:    "#AC4433",
            borderActive: "#C24636", borderInactive: "#2E2A27"
        },
        frieren:          {
            bgBase:       "#1B1C20", bgSurface:      "#25272E", bgOverlay: "#353945",
            fgBase:       "#F0F0F5", onAccent:       "#1B1C20", fgDim:     "#AAB0C0", fgSubtle: "#787E91",
            accentStrong: "#E2D1F9", accentDim:      "#9A8EB3", secondary: "#F8BBD0", info:     "#B3E5FC",
            success:      "#C8E6C9", warning:        "#FFF9C4", danger:    "#FFCDD2",
            borderActive: "#E2D1F9", borderInactive: "#2C2E36"
        },
        furina:           {
            bgBase:       "#0F1724", bgSurface:      "#182336", bgOverlay: "#26354D",
            fgBase:       "#E0F2FE", onAccent:       "#0F1724", fgDim:     "#94A3B8", fgSubtle: "#64748B",
            accentStrong: "#38BDF8", accentDim:      "#0369A1", secondary: "#F0ABFC", info:     "#7DD3FC",
            success:      "#4ADE80", warning:        "#FB923C", danger:    "#F87171",
            borderActive: "#38BDF8", borderInactive: "#1E293B"
        },
        nahida:           {
            bgBase:       "#121915", bgSurface:      "#1C261F", bgOverlay: "#2A382E",
            fgBase:       "#ECFDF5", onAccent:       "#121915", fgDim:     "#A7F3D0", fgSubtle: "#6EE7B7",
            accentStrong: "#34D399", accentDim:      "#065F46", secondary: "#FDE68A", info:     "#67E8F9",
            success:      "#10B981", warning:        "#FBBF24", danger:    "#EF4444",
            borderActive: "#34D399", borderInactive: "#223026"
        },
        raiden:           {
            bgBase:       "#12101A", bgSurface:      "#1B1829", bgOverlay: "#2D2845",
            fgBase:       "#F1E9FF", onAccent:       "#F1E9FF", fgDim:     "#B0A1D1", fgSubtle: "#7E71A1",
            accentStrong: "#9D72FF", accentDim:      "#5E4599", secondary: "#FFB8FF", info:     "#82AAFF",
            success:      "#C3E88D", warning:        "#FFCB6B", danger:    "#F07178",
            borderActive: "#9D72FF", borderInactive: "#242036"
        },
        yaemiko:          {
            bgBase:       "#1A1012", bgSurface:      "#26181B", bgOverlay: "#3D262B",
            fgBase:       "#FFE4E9", onAccent:       "#1A1012", fgDim:     "#DBB4BC", fgSubtle: "#A68087",
            accentStrong: "#F06292", accentDim:      "#AD4769", secondary: "#F8BBD0", info:     "#BA68C8",
            success:      "#81C784", warning:        "#FFB74D", danger:    "#E57373",
            borderActive: "#F06292", borderInactive: "#2E1D21"
        },
        catppuccin:       {
            bgBase:       "#1E1E2E", bgSurface:      "#313244", bgOverlay: "#45475A",
            fgBase:       "#CDD6F4", onAccent:       "#1E1E2E", fgDim:     "#BAC2DE", fgSubtle: "#A6ADC8",
            accentStrong: "#CBA6F7", accentDim:      "#94E2D5", secondary: "#FAB387", info:     "#89B4FA",
            success:      "#A6E3A1", warning:        "#F9E2AF", danger:    "#F38BA8",
            borderActive: "#CBA6F7", borderInactive: "#313244"
        },
        nord:             {
            bgBase:       "#2E3440", bgSurface:      "#3B4252", bgOverlay: "#434C5E",
            fgBase:       "#ECEFF4", onAccent:       "#2E3440", fgDim:     "#D8DEE9", fgSubtle: "#4C566A",
            accentStrong: "#88C0D0", accentDim:      "#5E81AC", secondary: "#81A1C1", info:     "#8FBCBB",
            success:      "#A3BE8C", warning:        "#EBCB8B", danger:    "#BF616A",
            borderActive: "#88C0D0", borderInactive: "#3B4252"
        },
        gruvbox:          {
            bgBase:       "#282828", bgSurface:      "#3C3836", bgOverlay: "#504945",
            fgBase:       "#EBDBB2", onAccent:       "#282828", fgDim:     "#BDAE93", fgSubtle: "#928374",
            accentStrong: "#FE8019", accentDim:      "#D65D0E", secondary: "#FABD2F", info:     "#83A598",
            success:      "#B8BB26", warning:        "#FABD2F", danger:    "#FB4934",
            borderActive: "#FE8019", borderInactive: "#3C3836"
        },
        rosepine:         {
            bgBase:       "#191724", bgSurface:      "#1f1d2e", bgOverlay: "#26233a",
            fgBase:       "#e0def4", onAccent:       "#191724", fgDim:     "#908caa", fgSubtle: "#6e6a86",
            accentStrong: "#c4a7e7", accentDim:      "#ebbcba", secondary: "#f6c177", info:     "#31748f",
            success:      "#9ccfd8", warning:        "#f6c177", danger:    "#eb6f92",
            borderActive: "#c4a7e7", borderInactive: "#1f1d2e"
        },
        tokyonight:       {
            bgBase:       "#1a1b26", bgSurface:      "#24283b", bgOverlay: "#414868",
            fgBase:       "#c0caf5", onAccent:       "#1a1b26", fgDim:     "#a9b1d6", fgSubtle: "#565f89",
            accentStrong: "#7aa2f7", accentDim:      "#3d59a1", secondary: "#bb9af7", info:     "#0db9d7",
            success:      "#9ece6a", warning:        "#e0af68", danger:    "#f7768e",
            borderActive: "#7aa2f7", borderInactive: "#24283b"
        },
        everforest:       {
            bgBase:       "#2b3339", bgSurface:      "#323c41", bgOverlay: "#3a454a",
            fgBase:       "#d3c6aa", onAccent:       "#2b3339", fgDim:     "#9da9a0", fgSubtle: "#859289",
            accentStrong: "#a7c080", accentDim:      "#738254", secondary: "#d699b6", info:     "#7fbbb3",
            success:      "#a7c080", warning:        "#dbbc7f", danger:    "#e67e80",
            borderActive: "#a7c080", borderInactive: "#323c41"
        },
        kanagawa:         {
            bgBase:       "#1f1f28", bgSurface:      "#2a2a37", bgOverlay: "#363646",
            fgBase:       "#dcd7ba", onAccent:       "#1f1f28", fgDim:     "#727169", fgSubtle: "#54546d",
            accentStrong: "#957fb8", accentDim:      "#7e9cd8", secondary: "#ffa066", info:     "#7aa89f",
            success:      "#98bb6c", warning:        "#e6c384", danger:    "#c34043",
            borderActive: "#957fb8", borderInactive: "#223249"
        },
        dracula:          {
            bgBase:       "#282a36", bgSurface:      "#44475a", bgOverlay: "#6272a4",
            fgBase:       "#f8f8f2", onAccent:       "#282a36", fgDim:     "#bd93f9", fgSubtle: "#44475a",
            accentStrong: "#ff79c6", accentDim:      "#bd93f9", secondary: "#8be9fd", info:     "#50fa7b",
            success:      "#50fa7b", warning:        "#ffb86c", danger:    "#ff5555",
            borderActive: "#ff79c6", borderInactive: "#44475a"
        },
        monokai:          {
            bgBase:       "#272822", bgSurface:      "#3e3d32", bgOverlay: "#75715e",
            fgBase:       "#f8f8f2", onAccent:       "#272822", fgDim:     "#cfcfc2", fgSubtle: "#a59f85",
            accentStrong: "#a6e22e", accentDim:      "#66d9ef", secondary: "#ae81ff", info:     "#66d9ef",
            success:      "#a6e22e", warning:        "#e6db74", danger:    "#f92672",
            borderActive: "#a6e22e", borderInactive: "#3e3d32"
        },
        oxocarbon:        {
            bgBase:       "#161616", bgSurface:      "#262626", bgOverlay: "#393939",
            fgBase:       "#ffffff", onAccent:       "#161616", fgDim:     "#dde1e6", fgSubtle: "#525252",
            accentStrong: "#ee5396", accentDim:      "#be95ff", secondary: "#33b1ff", info:     "#08bdba",
            success:      "#42be65", warning:        "#ffe97b", danger:    "#fa4d56",
            borderActive: "#ee5396", borderInactive: "#262626"
        }
    })
}
