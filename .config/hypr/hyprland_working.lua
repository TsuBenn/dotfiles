-- Programs

local terminal = "ghostty"
local filemanager = "dolphin"
local menu = "rofi -show drun"
local emoji = "rofi -mode emoji -show emoji"
local browser = "zen-browser"

-- Monitor

hl.monitor({
    output = "", -- e.g DP-1 
    mode = "1920x1080@60", -- e.g 1920x1080@60
    position = "0x0",
    scale = 1,
})

require("~/hyprmonitor.conf")

hl.on("hyprland.start", function () 
    hl.exec_cmd(browser)
    hl.exec_cmd("systemctl --user enable opentabletdriver.service --now")
    hl.exec_cmd("hyprctl dispatch workspace 2 && "..terminal)
    hl.exec_cmd("vesktop")
    hl.exec_cmd("steam")
    hl.exec_cmd("qs -c ~/.config/quickshell/tui/ -d")
    hl.exec_cmd("easyeffects --gapplication-service")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("wl-paste --watch clipvault store")
end)

hl.env("XCURSOR_THEME", "MiyabiLinuxCursor")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "MiyabiLinuxCursor")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("INPUT_METHOD", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on

        allow_tearing = true,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 7,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 2,
            passes    = 3,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.curve("easeOutQuint",   { type = "bezier", points = { 0.23, 1},    { 0.32, 1} })
hl.curve("easeInOutCubic", { type = "bezier", points = { 0.65, 0.05}, { 0.36, 1} })
hl.curve("linear",         { type = "bezier", points = { 0,    0},    { 1,    1} })
hl.curve("almostLinear",   { type = "bezier", points = { 0.5,  0.5},  { 0.75, 1} })
hl.curve("quick",          { type = "bezier", points = { 0.15, 0},    { 0.1,  1} })

-- Default springs

hl.animation({ leaf = "global",              enabled = 1, speed = 10,   bezier = "    default"})
hl.animation({ leaf = "border",              enabled = 1, speed = 5.39, bezier = "  easeOutQuint"})
hl.animation({ leaf = "windows",             enabled = 1, speed = 4,    bezier = "     easeOutQuint"})
hl.animation({ leaf = "windowsIn",           enabled = 1, speed = 4,    bezier = "     easeOutQuint", style = " popin 1%"})
hl.animation({ leaf = "windowsOut",          enabled = 1, speed = 4,    bezier = "     easeOutQuint", style = " popin 1%"})
hl.animation({ leaf = "windowsMove",         enabled = 1, speed = 4,    bezier = "     easeOutQuint"})
hl.animation({ leaf = "fadeIn",              enabled = 1, speed = 1,    bezier = "     almostLinear"})
hl.animation({ leaf = "fadeOut",             enabled = 1, speed = 1,    bezier = "     almostLinear"})
hl.animation({ leaf = "fade",                enabled = 1, speed = 5,    bezier = "     quick"})
hl.animation({ leaf = "layers",              enabled = 1, speed = 3.81, bezier = "  easeOutQuint"})
hl.animation({ leaf = "layersIn",            enabled = 1, speed = 4,    bezier = "     easeOutQuint", style = " fade"})
hl.animation({ leaf = "layersOut",           enabled = 1, speed = 1.5,  bezier = "   linear",         style = "       fade"})
hl.animation({ leaf = "fadeLayersIn",        enabled = 1, speed = 1.79, bezier = "  almostLinear"})
hl.animation({ leaf = "fadeLayersOut",       enabled = 1, speed = 1.39, bezier = "  almostLinear"})
hl.animation({ leaf = "workspaces",          enabled = 1, speed = 1.94, bezier = "  almostLinear",    style = " fade"})
hl.animation({ leaf = "workspacesIn",        enabled = 1, speed = 4,    bezier = "     easeOutQuint"})
hl.animation({ leaf = "workspacesOut",       enabled = 1, speed = 4,    bezier = "     easeOutQuint"})
hl.animation({ leaf = "specialWorkspaceIn",  enabled = 1, speed = 3,    bezier = "     easeOutQuint", style = " slidevert top 50%"})
hl.animation({ leaf = "specialWorkspaceOut", enabled = 1, speed = 3,    bezier = "     easeOutQuint", style = " slidevert bottom 50%"})
hl.animation({ leaf = "zoomFactor",          enabled = 1, speed = 7,    bezier = "     easeOutQuint"})
