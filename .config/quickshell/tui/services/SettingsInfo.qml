pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    FrameAnimation {
        id: fpsMonitor
        running: true
    }

    property real frameTime: fpsMonitor.smoothFrameTime

    property int fps: fpsMonitor.smoothFrameTime > 0 ? Math.round(1.0 / fpsMonitor.smoothFrameTime) : 0

    Timer {
        running: true
        repeat: true
        interval: 200
        onTriggered: root.fps = fpsMonitor.smoothFrameTime > 0 ? Math.round(1.0 / fpsMonitor.smoothFrameTime) : 0
    }

    property bool initialized: dependenciesChecked && colorsLoaded && wallpaperCached
    property bool dependenciesChecked: false // Use to initiallize the bar
    property bool colorsLoaded: false // Use to initiallize the bar
    property bool wallpaperCached: false // Use to initiallize the bar

    property bool purify: false // Reduce everything down to ascii only, better compatibility with more fonts
    property bool compat: false // Reduce everything down to extended ascii.

    property bool quickStart: false // Quick dependencies check. Super fast

    property bool lightMode: autoLightMode ? Colors.preferredLightMode : userLightMode // Light mode of system
    property bool userLightMode: false // Light mode of user input
    property bool autoLightMode: true  // Decide whether the wallpaper needs a light mode or dark mode
    property string appearance: {     // Light mode, dark mode or auto mode?
        if (autoLightMode) {
            return "Auto";
        } else if (lightMode) {
            return "Light";
        } else {
            return "Dark";
        }
    }

    property bool moveFloatOnFocus: false // When requesting an already opened Float, move it to current workspace instead of focusing onto the workspace that it's in

    property bool hints: true  // Show keyboard hints
    property bool minimal: false // Reduce UI elements
    property bool textBasedVolume: false // Bar's volume rocker do be text
    property bool hideBar: false // Hide status bar
    property bool bottomBar: false // Status bar placed on the bottom of the screen instead of top
    property bool safeNotifications: false // Hide notifications' messages
    property bool dnd: false // Do not disturb
    property bool optimizeMemory: false // Reduce memory usage significantly, but takes more time to load UI elements

    property bool wallpaperAutoAdvance: true  // Advance selection as you scroll through the wallpaper selections
    property bool wallpaperCleanReccan: false // Force re-caching wallpaper else it will only cache new files found.

    property bool shadow: false // Shadows for UI elements

    property bool hyprAnim: false // Toggles Hyprland animations
    property bool hyprBlur: false // Toggles Hyprland background blur for windows

    property bool bgCava: true  // Run cava on top of the wallpaper
    property bool bgCavaLock: false // Run cava on top of the wallpaper (lockscreen)

    property bool screenshotNotify: false // Send a notification when taking a screenshot
    property bool screenshotStay: false // Keep the screenshot buffer after screenshotting
    property bool screenshotCursor: true  // Capture cursor

    property bool lockScreenMusic: false // Music playing during lock session
    property bool onlyFocusedMonitorLockScreen: false // Whether the other monitor should also show the wallpaper or left black

    property bool sfx: true  // Random ahh sound effects

    property bool debug: true  // Used for random debugging

    property int pacmanSearchMode: 0

    signal debugSig

    property var toggles: ["hints", "quickStart", "minimal", "textBasedVolume", "hideBar", "bottomBar", "optimizeMemory", "safeNotifications", "dnd", "wallpaperAutoAdvance", "shadow", "hyprAnim", "hyprBlur", "bgCava", "bgCavaLock", "screenshotStay", "screenshotNotify", "screenshotCursor", "lockScreenMusic", "sfx", "userLightMode", "autoLightMode", "debug", "moveFloatOnFocus", "purify", "compat"]

    property var enums: ["pacmanSearchMode"]

    property var states: ["appearance",]

    signal showGrid

    function restart() {
        SystemInfo.runDetached(["bash", "-c", SystemInfo.configdir + "/scripts/revive.sh"]);
    }

    function get_state(text) {
        let result = -1;
        for (const toggle of toggles) {
            if (text == toggle) {
                result = root[toggle];
                break;
            }
        }
        for (const state of states) {
            if (text == state) {
                return `[${root[state].toUpperCase()}]`;
            }
        }
        if (result != -1) {
            return result ? "[X]" : "[ ]";
        }
        return "";
    }

    Connections {
        target: SystemInfo
        function onInitializedSystemInfo() {
            load_config.preload = true;
        }
    }

    FileView {
        id: load_config

        preload: false

        path: SystemInfo.configdir + "/scripts/config.json"

        printErrors: false

        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.saveConfig();
            }
        }

        onLoaded: {
            const config = JSON.parse(text());

            for (const toggle of root.toggles) {
                root[toggle] = config[toggle] ?? false;
            }
            for (const e of root.enums) {
                root[e] = config[e] ?? 0;
            }
        }
    }

    function iterateAppearance() { // Dark -> Light -> Auto -> Repeats
        if (autoLightMode) {
            if (userLightMode)
                toggle("userLightMode");
            toggle("autoLightMode");
        } else if (lightMode) {
            if (!autoLightMode)
                toggle("autoLightMode");
            if (userLightMode)
                toggle("userLightMode");
        } else {
            if (autoLightMode)
                toggle("autoLightMode");
            if (!userLightMode)
                toggle("userLightMode");
        }
    }

    function saveConfig() {
        let config = ({});

        for (const toggle of toggles) {
            config[toggle] = root[toggle] ?? false;
        }
        for (const e of enums) {
            config[e] = root[e] ?? false;
        }

        //console.log(JSON.stringify(config, null, 2))

        load_config.setText(JSON.stringify(config, null, 2));
    }

    function notification_check() {
        NotificationsInfo.send("System", "", "Notification Check", "Check check check!\nClick here to show another similar notification!", 0, false, "qs -c tui ipc call config notification_check");
    }

    function audio_check() {
        const rng = Math.random();
        const sound = Math.round(rng * 3);
        const sounds = ["hallo", "mambo", "mambo_tongye", "mambo_wow"];
        AudioInfo.playSound(sounds[sound], 1);
    }

    function iterate(config, maxIter) {
        root[config] = (root[config] + 1) % maxIter;
        saveConfig();
    }

    function toggle(config) {
        root[config] = !root[config];
        saveConfig();
    }

    IpcHandler {
        target: "config"
        function open_popup(popup: string): void {
            PopupManager.open(popup);
        }
        function open_float(float: string): void {
            FloatsManager.open(float);
        }
        function close_popup(popup: string): void {
            PopupManager.close(popup);
        }
        function open_close(float: string): void {
            FloatsManager.close(float);
        }
        function toggle_popup(popup: string): void {
            PopupManager.toggle(popup);
        }
        function send_popup_sig(id: string, sig: string, open: bool): void {
            PopupManager.sendSignal(id, sig);
            if (open) {
                PopupManager.open(id);
            }
        }
        function shutdown(): void {
            PowerManager.call("Shutdown", 3);
        }
        function sleep(): void {
            PowerManager.call("Sleep", 3);
        }
        function reboot(): void {
            PowerManager.call("Reboot", 3);
        }
        function logout(): void {
            PowerManager.call("Logout", 3);
        }
        function lock(): void {
            SystemInfo.lock();
        }
        function set_color_theme(color: string): void {
            Colors.current = color;
        }
        function notification_check(): void {
            root.notification_check();
        }
        function auth_check(): void {
            SystemInfo.runDetached(["pkexec", "id"]);
        }
        function audio_check(): void {
            root.audio_check();
        }
        function audio_restart(): void {
            AudioInfo.restart();
        }
        function screenshot(full: bool): void {
            if (PopupManager.isOpen("screenshot")) {
                PopupManager.sendSignal("screenshot", "full_now");
                return;
            }
            ScreenshotInfo.requestCache();
            if (full)
                PopupManager.sendSignal("screenshot", "full");
        }
        function toggle_grids(): void {
            root.showGrid();
        }
        function toggle_minimal(): void {
            root.toggle("minimal");
        }
        function toggle_hidebar(): void {
            root.toggle("hideBar");
        }
        function toggle_memory_optimize(): void {
            root.toggle("optimizeMemory");
        }
        function toggle_safe_notifications(): void {
            root.toggle("safeNotifications");
        }
        function toggle_hints(): void {
            root.toggle("hints");
        }
        function toggle_dnd(): void {
            root.toggle("dnd");
        }
        function toggle_hypranim(): void {
            root.toggle("hyprAnim");
        }
        function toggle_hyprblur(): void {
            root.toggle("hyprBlur");
        }
        function toggle_bgcava(): void {
            root.toggle("bgCava");
        }
        function toggle_bgcava_lock(): void {
            root.toggle("bgCavaLock");
        }
        function toggle_lock_screen_music(): void {
            root.toggle("lockScreenMusic");
        }
        function toggle_bottom_bar(): void {
            root.toggle("bottomBar");
        }
        function toggle_text_based_volume(): void {
            root.toggle("textBasedVolume");
        }
        function toggle_sfx(): void {
            root.toggle("sfx");
        }
        function toggle_light_mode(): void {
            root.toggle("userLightMode");
        }
        function toggle_auto_light_mode(): void {
            root.toggle("autoLightMode");
        }
        function toggle_appearance(): void {
            root.iterateAppearance();
        }
        function toggle_shadow(): void {
            root.toggle("shadow");
        }
        function toggle_quickstart(): void {
            root.toggle("quickStart");
        }
        function toggle_screenshot_notify(): void {
            root.toggle("screenshotNotify");
        }
        function toggle_wallpaper_auto_advance(): void {
            root.toggle("wallpaperAutoAdvance");
        }
        function toggle_movefloatonfocus(): void {
            root.toggle("moveFloatOnFocus");
        }
        function toggle_purify(): void {
            root.toggle("purify");
        }
        function toggle_compat(): void {
            root.toggle("compat");
        }

        function restart(): void {
            root.restart();
        }

        function lock_screen(): void {
            SystemInfo.lock();
        }

        function dummy(): void {
            root.toggle("debug");
            root.debugSig();

            // console.log(PacmanInfo.packages.length);
        }
    }

    Process {
        id: exec

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    load_config.reload();
                }
            }
        }
    }
}
