import json
import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
COLORS_FILE = os.path.join(SCRIPT_DIR, "colors.json")

COLORS = {}

with open(COLORS_FILE, "r") as f:
    COLORS = json.load(f)

SETTINGS = [
    {
        "label": "<b>Pacman</b>",
        "description": "Manage your Arch Linux packages.",
        "category": "settings",
        "type": "exec",
        "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_float", "pacman"],
    },
    {
        # These are hidden items that are only show up when searched.
        # Mainly for options within another menu that can still be accessed quickly without using that menu.

        "label": "",
        "description": "Changes how your shells color.",
        "category": "settings",
        "type": "menu",
        "value": [
            *[
                {
                    "label": COLORS[color]["name"],
                    "description": COLORS[color]["description"],
                    "category": "settings",
                    "type": "exec",
                    "value": ["qs", "-c", "tui", "ipc", "call", "config", "set_color_theme", color],
                } for color in COLORS
            ],
            {
                "label": "Sleep",
                "description": "(aka. Suspend) Put your PC to sleep.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "sleep"],
            },
            {
                "label": "Reboot",
                "description": "(aka. Restart) Turn your PC off then turn it back on again.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "reboot"],
            },
            {
                "label": "Shutdown",
                "description": "Turn off your PC for good.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "shutdown"],
            },
            {
                "label": "Lock",
                "description": "Lock yourself out.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "lock"],
            },
            {
                "label": "Logout",
                "description": "Someone else is using this computer?",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "logout"],
            },
        ]
    },
    {
        "label": "Color themes",
        "description": "Changes how your shell looks and feels.",
        "category": "settings",
        "type": "exec",
        "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "color"]
    },
    {
        "label": "Wallpapers",
        "description": "Changes how your wallpaper looks and behaves.",
        "category": "settings",
        "type": "exec",
        "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "wallpaper"]
    },
    {
        "id": "system_checks",
        "label": "System checks",
        "description": "Making sure that your shell is working normally.",
        "category": "settings",
        "type": "menu",
        "value": [
            {
                "label": "Authentication check",
                "description": "Check authentication capability.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "auth_check"],
            },
            {
                "label": "Notification check",
                "description": "Send a dummy notification.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "notification_check"],
            },
            {
                "label": "Audio check",
                "description": "Play a random cute anime girl sound effect at MAX volume.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "audio_check"],
            },
            {
                "label": "Audio restart",
                "description": "Having trouble with the audio? Try restarting it.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "audio_restart"],
            },
            {
                "label": "Toggle grids",
                "description": "Show terminal cells grid making sure everything is aligned properly.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_grids"],
            },
        ]
    },
    {
        "id": "toggles",
        "label": "Toggles",
        "description": "Shell toggles.",
        "category": "settings",
        "type": "menu",
        "value": [
            {
                "label": "{appearance} Shell appearance",
                "description": "Light mode, dark mode or auto mode.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_appearance"],
            },
            {
                "label": "{userLightMode} Light mode",
                "description": "Turn on light mode If you're not a vampire.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_light_mode"],
            },
            {
                "label": "{autoLightMode} Auto light mode",
                "description": "Choose whether your current wallpaper should be light or dark.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_auto_light_mode"],
            },
            {
                "label": "{screenshotNotify} Screenshot notification",
                "description": "Send a notification when taking a screenshot.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_screenshot_notify"],
            },
            {
                "label": "{hints} Show hints",
                "description": "Show key binds for navigating menus.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_hints"],
            },
            {
                "label": "{minimal} Minimal mode",
                "description": "Remove icons, condense interface elements.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_minimal"],
            },
            {
                "label": "{hideBar} Hide status bar",
                "description": "Hide status bar, hover to peek at it.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_hidebar"],
            },
            {
                "label": "{optimizeMemory} Memory optimization mode",
                "description": "Trading <i>performace</i> for memory optimization.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_memory_optimize"],
            },
            {
                "label": "{safeNotifications} Safe notifications mode",
                "description": "Notification popup won't reveal its content.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_safe_notifications"],
            },
            {
                "label": "{dnd} Do not disturb",
                "description": "Remove notification popups.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_dnd"],
            },
            {
                "label": "{hyprAnim} Hyprland animations",
                "description": "Toggling Hyprland's animations.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_hypranim"],
            },
            {
                "label": "{shadow} Shadows",
                "description": "Show shadows for UI elements (Including Hyprland windows).",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_shadow"],
            },
            {
                "label": "{hyprBlur} Hyprland background blur",
                "description": "Toggling Hyprland's blur for window backgrounds.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_hyprblur"],
            },
            {
                "label": "{bgCava} Cava in the background",
                "description": "Having cava run on top of the wallpaper.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_bgcava"],
            },
            {
                "label": "{lockScreenMusic} Lock screen music",
                "description": "Play music during lock session.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_lock_screen_music"],
            },
            {
                "label": "{sfx} Sound effects",
                "description": "Random anime sound effects for everything.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_sfx"],
            },
            {
                "label": "{quickStart} Quick start",
                "description": "Run dependencies check procedure at maximum speed.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "toggle_quickstart"],
            },
        ],
    },
    {
        "label": "Power",
        "description": "Choose what to do to your computer's power.",
        "category": "settings",
        "type": "exec",
        "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "power"],
    },
    {
        "label": "Restart Quickshell",
        "description": "Restart this current shell.",
        "category": "settings",
        "type": "exec",
        "value": ["qs", "-c", "tui", "ipc", "call", "config", "restart"],
    },
    {
        "id": "utilities",
        "label": "Utilities",
        "description": "System essential utilities.",
        "category": "settings",
        "type": "menu",
        "value": [
            {
                "label": "System Info",
                "description": "Show system infomations and its usage.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "system"],
            },
            {
                "label": "Control Panel",
                "description": "Essential system settings and notifications.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "control_panel"],
            },
            {
                "label": "Audio Mixer",
                "description": "Fine control over each program's audio.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "send_popup_sig", "control_panel", "mixer", "true"],
            },
            {
                "label": "Notifications",
                "description": "Read all your tracked notifications.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "send_popup_sig", "control_panel", "notif", "true"],
            },
            {
                "label": "Calendar",
                "description": "Time, calendar and reminders.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "calendar"],
            },
            {
                "label": "Media player",
                "description": "Finer control over media players.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "media_player"],
            },
            {
                "label": "Clipboard history",
                "description": "Clipboard history (text and image).",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "clipboard"],
            },
            {
                "label": "Emoji picker",
                "description": "Search and copy/type your desired emoji.",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "emoji"],
            },
            {
                "label": "Quick menu",
                "description": "Map any action to any key binds you want (most of the time).",
                "category": "settings",
                "type": "exec",
                "value": ["qs", "-c", "tui", "ipc", "call", "config", "open_popup", "quick_menu"],
            },
        ],
    },
]

CALC = [
    {
        "label": "abs()",
        "description": "Absolute",
        "category": "calc_preset",
        "type": "exec",
        "value": ["wtype", "abs()", "-k", "Left"],
    },
    {
        "label": "sqrt()",
        "description": "Square root",
        "category": "calc_preset",
        "type": "exec",
        "value": ["wtype", "sqrt()", "-k", "Left"],
    },
    {
        "label": "pow()",
        "description": "Power",
        "category": "calc_preset",
        "type": "exec",
        "value": ["wtype", "pow()", "-k", "Left"],
    },
    {
        "label": "sin()",
        "description": "Sine",
        "category": "calc_preset",
        "type": "exec",
        "value": ["wtype", "sin()", "-k", "Left"],
    },
    {
        "label": "cos()",
        "description": "Cosine",
        "category": "calc_preset",
        "type": "exec",
        "value": ["wtype", "cos()", "-k", "Left"],
    },
    {
        "label": "tan()",
        "description": "Tangent",
        "category": "calc_preset",
        "type": "exec",
        "value": ["wtype", "tan()", "-k", "Left"],
    },
    {
        "label": "log()",
        "description": "Logarith",
        "category": "calc_preset",
        "type": "exec",
        "value": ["wtype", "log()", "-k", "Left"],
    },
    {
        "label": "pi",
        "description": "Pi",
        "category": "calc_preset",
        "type": "exec",
        "value": ["wtype", "pi"],
    },
    {
        "label": "e",
        "description": "E",
        "category": "calc_preset",
        "type": "exec",
        "value": ["wtype", "e"],
    },
]


def main():
    if len(sys.argv) > 1:
        if sys.argv[1] == "--colors":
            print(json.dumps(COLORS))

main()
