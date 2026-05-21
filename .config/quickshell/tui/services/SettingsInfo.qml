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

    property int fps: fpsMonitor.smoothFrameTime > 0 ? Math.round(1.0 / fpsMonitor.smoothFrameTime) : 0

    Timer {
        running: true
        repeat: true
        interval: 200
        onTriggered: root.fps = fpsMonitor.smoothFrameTime > 0 ? Math.round(1.0 / fpsMonitor.smoothFrameTime) : 0
    }

    property bool hints             : true  // Show keyboard hints
    property bool minimal           : false // Reduce UI elements
    property bool safeNotifications : false // Hide notifications' messages
    property bool dnd               : false // Do not disturb
    property bool optimizeMemory    : false // Reduce memory usage significantly, but takes more time to load UI elements

    property bool hyprAnim          : false // Toggles Hyprland animations
    property bool hyprBlur          : false // Toggles Hyprland background blur for windows

    property bool bgCava            : true  // Run cava on top of the wallpaper

    property bool debug            : true  // Used for random debugging

    property var toggles: [
        "hints",
        "minimal",
        "optimizeMemory",
        "safeNotifications",
        "dnd",
        "hyprAnim",
        "hyprBlur",
        "bgCava",
        "debug",
    ]

    signal showGrid()

    function get_state(text) {
        let state = -1
        for (const toggle of toggles) {
            if (text == toggle) {
                state = root[toggle]
                break
            }
        }
        if (state != -1) {
            return state ? "[X]" : "[ ]"
        }
        return ""
    }

    FileView {

        id: load_config

        path: SystemInfo.configdir + "/scripts/config.json"

        onLoaded: {

            const config = JSON.parse(text())

            for (const toggle of root.toggles) {
                root[toggle] = config[toggle] ?? false
            }

        }

    }

    function saveConfig() {

        let config = ({})

        for (const toggle of toggles) {
            config[toggle] = root[toggle] ?? false
        }

        //console.log(JSON.stringify(config, null, 2))

        exec.exec(["bash", "-c", `echo '${JSON.stringify(config)}' > ${SystemInfo.configdir + "/scripts/config.json"}`])

    }

    function notification_check() {
        NotificationsInfo.send("System", "", "Notification Check", "Check check check!\nClick here to show another similar notification!", 0, false, "qs -c tui ipc call config notification_check")
    }

    function audio_check() {
        const rng = Math.random()
        const sound = Math.round(rng*3)
        const sounds = ["hallo","mambo","mambo_tongye","mambo_wow"]
        AudioInfo.playSound(sounds[sound], 1)
    }

    function toggle(config) {
        root[config] = !root[config]
        saveConfig()
    }

    IpcHandler {
        target: "config"
        function open_popup(popup: string): void {PopupManager.open(popup); console.log(popup)}
        function close_popup(popup: string): void {PopupManager.close(popup)}
        function toggle_popup(popup: string): void {PopupManager.toggle(popup)}
        function send_popup_sig(id: string, sig: string, open: bool): void {
            PopupManager.sendSignal(id, sig)
            if (open) {
                PopupManager.open(id)
            }
        }
        function set_color_theme(color: string): void {Colors.current = color}
        function notification_check(): void {
            root.notification_check()
        }
        function audio_check(): void {
            root.audio_check()
        }
        function toggle_grids(): void              { root.showGrid() }
        function toggle_minimal(): void            { root.toggle("minimal") }
        function toggle_memory_optimize(): void    { root.toggle("optimizeMemory") }
        function toggle_safe_notifications(): void { root.toggle("safeNotifications") }
        function toggle_hints(): void              { root.toggle("hints") }
        function toggle_dnd(): void                { root.toggle("dnd") }
        function toggle_hypranim(): void           { root.toggle("hyprAnim") }
        function toggle_hyprblur(): void           { root.toggle("hyprBlur") }
        function toggle_bgcava(): void             { root.toggle("bgCava") }


        function dummy(): void {
            // Contains debugging features that can be accessed by SUPER + P
            root.toggle("debug")
            PopupManager.open("emoji")
        }
    }

    Process {
        id: exec

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    load_config.reload()
                }
            }
        }
    }

}
