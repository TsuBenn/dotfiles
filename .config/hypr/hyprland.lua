-- Programs

local terminal = "ghostty"
local fileManager = "dolphin"
local menu = "rofi -show drun"
local emoji = "rofi -mode emoji -show emoji"
local browser = "zen-browser"
local discord = "discord"
local spotify = "LD_PRELOAD=/usr/local/lib/spotify-adblock.so spotify"

-- Monitor

hl.monitor({
    output = "", -- e.g DP-1
    mode = "prefered", -- e.g 1920x1080@60
    position = "auto",
    scale = "1",
})

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

package.path = package.path .. ";" .. os.getenv("HOME") .. "/?.lua"
if file_exists(os.getenv("HOME") .. "/hyprmonitor.lua") then
    require("hyprmonitor")
else
    hl.exec_cmd('notify-send "HYPRLAND" "<i>hyprmonitor.lua</i> can not be found in the HOME directory.\nIf you want to configure your monitor settings, please create a file named <i>hyprmonitor.lua</i> in the home directory and put your monitor configuration there." --app-name="System"')
end

hl.on("hyprland.start", function ()
    hl.exec_cmd(browser)
    hl.exec_cmd("systemctl --user enable opentabletdriver.service --now")
    -- hl.exec_cmd('hyprctl "dispatch hl.dsp.focus({workspace = \"2\"})" && '..terminal)
    hl.exec_cmd(discord)
    hl.exec_cmd("steam")
    hl.exec_cmd("qs -c ~/.config/quickshell/tui/ -d")
    hl.exec_cmd("easyeffects --gapplication-service")
    --hl.exec_cmd("awww-daemon")
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("wl-paste --watch clipvault store")
end)

--hl.env("__GL_THREADED_OPTIMIZATIONS", 1)
--hl.env("__NV_PRIME_RENDER_OFFLOAD", 1)
--hl.env("__VK_LAYER_NV_optimus","NVIDIA_only")

hl.env("XCURSOR_THEME", "MiyabiLinuxCursor")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "MiyabiLinuxCursor")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("INPUT_METHOD", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

hl.config({
    general = {
        gaps_in  = {top = 8, left = 3, bottom = 8, right = 3},
        gaps_out = {top = 8, left = 3, bottom = 8, right = 3},

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

        dim_special = 0.5,

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

----------------------
----  ANIMATIONS  ----
----------------------

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.curve("easeOutQuint",   { type = "bezier", points = {{ 0.23, 1},    { 0.32, 1}} })
hl.curve("easeInOutCubic", { type = "bezier", points = {{ 0.65, 0.05}, { 0.36, 1}} })
hl.curve("linear",         { type = "bezier", points = {{ 0,    0},    { 1,    1}} })
hl.curve("almostLinear",   { type = "bezier", points = {{ 0.5,  0.5},  { 0.75, 1}} })
hl.curve("quick",          { type = "bezier", points = {{ 0.15, 0},    { 0.1,  1}} })

-- Default springs

hl.animation({ leaf = "global",              enabled = 1, speed = 10,   bezier = "default"})
hl.animation({ leaf = "border",              enabled = 1, speed = 5.39, bezier = "easeOutQuint"})
hl.animation({ leaf = "windows",             enabled = 1, speed = 4,    bezier = "easeOutQuint"})
hl.animation({ leaf = "windowsIn",           enabled = 1, speed = 4,    bezier = "easeOutQuint", style = "popin 1%"})
hl.animation({ leaf = "windowsOut",          enabled = 1, speed = 4,    bezier = "easeOutQuint", style = "popin 1%"})
hl.animation({ leaf = "windowsMove",         enabled = 1, speed = 4,    bezier = "easeOutQuint"})
hl.animation({ leaf = "fadeIn",              enabled = 1, speed = 1,    bezier = "almostLinear"})
hl.animation({ leaf = "fadeOut",             enabled = 1, speed = 1,    bezier = "almostLinear"})
hl.animation({ leaf = "fade",                enabled = 1, speed = 5,    bezier = "quick"})
hl.animation({ leaf = "layers",              enabled = 1, speed = 3.81, bezier = "easeOutQuint"})
hl.animation({ leaf = "layersIn",            enabled = 1, speed = 4,    bezier = "easeOutQuint", style = "fade"})
hl.animation({ leaf = "layersOut",           enabled = 1, speed = 1.5,  bezier = "linear",         style = "fade"})
hl.animation({ leaf = "fadeLayersIn",        enabled = 1, speed = 1.79, bezier = "almostLinear"})
hl.animation({ leaf = "fadeLayersOut",       enabled = 1, speed = 1.39, bezier = "almostLinear"})
hl.animation({ leaf = "workspaces",          enabled = 1, speed = 1.94, bezier = "almostLinear",    style = "fade"})
hl.animation({ leaf = "workspacesIn",        enabled = 1, speed = 4,    bezier = "easeOutQuint"})
hl.animation({ leaf = "workspacesOut",       enabled = 1, speed = 4,    bezier = "easeOutQuint"})
hl.animation({ leaf = "specialWorkspaceIn",  enabled = 1, speed = 3,    bezier = "easeOutQuint", style = "slidevert top 50%"})
hl.animation({ leaf = "specialWorkspaceOut", enabled = 1, speed = 3,    bezier = "easeOutQuint", style = "slidevert bottom 50%"})
hl.animation({ leaf = "zoomFactor",          enabled = 1, speed = 7,    bezier = "easeOutQuint"})


-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "caps:escape",
        kb_rules   = "",

        follow_mouse = 1,

        force_no_accel = true,
        accel_profile= "flat",

        sensitivity = -0.5, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.4,
            drag_lock = 0,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local SUPER = "SUPER+" -- Sets "Windows" key as main modifier
local ALT = "ALT+" -- Sets "Windows" key as main modifier
local SHIFT = "SHIFT+" -- Sets "Windows" key as main modifier
local CTRL = "CTRL+" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(SUPER.."Q", hl.dsp.exec_cmd(terminal))
hl.bind(SUPER.."B", hl.dsp.exec_cmd(browser))
hl.bind(SUPER.."C", hl.dsp.window.close())
hl.bind(SUPER..SHIFT.."C", hl.dsp.window.kill())
hl.bind(SUPER.."F1", hl.dsp.exit())
hl.bind(SUPER.."E", hl.dsp.exec_cmd(fileManager))
hl.bind(SUPER.."F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(SUPER.."space", hl.dsp.exec_cmd(menu))

hl.bind(SUPER.."+ slash",  hl.dsp.exec_cmd("hypruler"))

local screenshot_window = "hyprshot -m window -o ~/Screenshots/"
local screenshot_full = "hyprshot -m output -m active -o ~/Screenshots/"
local screenshot_region = "hyprshot -m region -o ~/Screenshots/"

hl.bind(CTRL.."end",  hl.dsp.exec_cmd(screenshot_window))
hl.bind(SUPER.."end",  hl.dsp.exec_cmd(screenshot_full))
hl.bind("end",  hl.dsp.exec_cmd(screenshot_region))
hl.bind(CTRL.."print",  hl.dsp.exec_cmd(screenshot_window))
hl.bind(SUPER.."print",  hl.dsp.exec_cmd(screenshot_full))
hl.bind("print",  hl.dsp.exec_cmd(screenshot_region))

hl.bind(SUPER.."N", hl.dsp.exec_cmd(spotify))

hl.bind(SUPER.."V", hl.dsp.exec_cmd("clipvault list | rofi -dmenu -display-columns 2 | clipvault get | wl-copy"))

hl.bind(SUPER.."period", hl.dsp.exec_cmd(emoji))

hl.bind(SUPER.."delete", hl.dsp.exec_cmd("qalculate-qt"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd("qalculate-qt"))

hl.bind(SUPER.."A", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(SUPER..SHIFT.."A", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

local zoom = 1
local zoom_strength = 1.5

-- Scroll through existing workspaces with SUPER + scroll
hl.bind(SUPER .. "grave", function()
    zoom = math.max(zoom/zoom_strength, 1)
    hl.config({
        cursor = {
            zoom_factor = zoom
        }
    })
end
)

hl.bind(SUPER .. SHIFT .. "grave", function()
    zoom = math.max(zoom * zoom_strength, 1)
    hl.config({
        cursor = {
            zoom_factor = zoom
        }
    })
end
)

-- local closeWindowBind = hl.bind(SUPER .. " + C", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)

-- Move focus with SUPER + arrow keys
hl.bind(SUPER .. "J",  hl.dsp.focus({ direction = "left" }))
hl.bind(SUPER .. "L", hl.dsp.focus({ direction = "right" }))
hl.bind(SUPER .. "I",    hl.dsp.focus({ direction = "up" }))
hl.bind(SUPER .. "K",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with SUPER + [0-9]
-- Move active window to a workspace with SUPER + SHIFT + [0-9]
for i = 1, 10 do
    local key = i%10
    hl.bind(SUPER..key, hl.dsp.focus({ workspace = i}))
    hl.bind(SUPER..SHIFT..key,hl.dsp.window.move({ workspace = i }))
end

for i = 6, 9 do
    local key = i
    hl.bind(SUPER..CTRL..key-5, hl.dsp.focus({ workspace = i}))
    hl.bind(SUPER..SHIFT..CTRL..key-5,hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(SUPER .. "S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(SUPER .. "SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(SUPER .. "D",         hl.dsp.workspace.toggle_special("mahou"))
hl.bind(SUPER .. "SHIFT + D", hl.dsp.window.move({ workspace = "special:mahou" }))

-- Move/resize windows with SUPER + LMB/RMB and dragging
hl.bind(SUPER .. "mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(SUPER .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })



--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    match = {
        class = ".*localsend.*|.*qimgv.*",
    },

    float = true,
    size = {"(monitor_w*0.5)","(monitor_h*0.5)"}
})
hl.window_rule({
    match = {
        class = "org.*freedesktop.*impl.*portal.*desktop.*",
    },

    float = true,
    size = {"(monitor_w*0.5)","(monitor_h*0.5)"}
})
hl.window_rule({
    match = {
        class = ".*dolphin.*",
        float = false,
    },

    float = true,
    size = {"(monitor_w*0.7)","(monitor_h*0.8)"}
})
hl.window_rule({
    match = {
        class = ".*qalculate-qt.*",
    },

    float = true,
    size = {"(monitor_w*0.3)","(monitor_h*0.5)"}
})
hl.window_rule({
    match = {
        class = ".*steam.*",
        title = "Friends List",
    },

    float = true,
    size = {"(monitor_w*0.2)","(monitor_h*0.8)"}
})
hl.window_rule({
    match = {
        class = ".*mpv.*|.*vlc.*",
    },

    float = true,
    -- size = {"(monitor_w*0.7)","(monitor_h*0.7)"}
})

hl.window_rule({
    match = {
        class = ".*obs.*",
    },

    workspace = "special:magic",
})
hl.window_rule({
    match = {
        class = ".*spotify.*",
    },

    workspace = "special:mahou",
})
hl.window_rule({
    match = {
        class = "zen",
    },

    workspace = "1",
})
hl.window_rule({
    match = {
        class = ".*"..discord..".*",
    },

    workspace = "4",
})
hl.window_rule({
    match = {
        class = ".*steam.*",
    },

    workspace = "5",
})
hl.window_rule({
    match = {
        class = ".*"..terminal..".*",
    },

    workspace = "2",
})

-- for i = 1, 5 do
--     hl.workspace_rule({workspace = '"'..i..'"', persistent = true})
-- end

hl.workspace_rule({workspace = "2", on_created_empty="ghostty"})
hl.workspace_rule({workspace = "4", on_created_empty=discord})
hl.workspace_rule({workspace = "special:mahou", on_created_empty=spotify})



-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    match = { class = "^(steam_app_.*)$" },
    immediate = true
})

hl.window_rule({
    match = { class = ".*" },
    focus_on_activate = true
})
