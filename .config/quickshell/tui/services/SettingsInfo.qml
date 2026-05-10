pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property bool hints             : true  // Show keyboard hints
    property bool minimal           : false // Reduce UI elements
    property bool safeNotifications : false // Hide notifications' messages
    property bool dnd               : false // Do not disturb
    property bool optimizeMemory    : false // Reduce memory usage significantly, but takes more time to load UI elements

    signal showGrid()

    function get_state(text) {
        let state = -1
        switch (text) {
            case "hints"             : state = hints; break
            case "minimal"           : state = minimal; break
            case "optimizeMemory"    : state = optimizeMemory; break
            case "safeNotifications" : state = safeNotifications; break
            case "dnd"               : state = dnd; break
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

            root.hints             = config.hints             ?? false
            root.minimal           = config.minimal           ?? false
            root.safeNotifications = config.safeNotifications ?? false
            root.dnd               = config.dnd               ?? false
            root.optimizeMemory    = config.optimizeMemory    ?? false

        }

    }

    function saveConfig() {

        const config = {
            "hints": hints,
            "minimal": minimal,
            "safeNotifications": safeNotifications,
            "dnd": dnd,
            "optimizeMemory": optimizeMemory,
        }

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

    function toggleDND() {
        dnd = !dnd
        saveConfig()
    }

    function toggleMinimal() {
        minimal = !minimal
        saveConfig()
    }

    function toggleHints() {
        hints = !hints
        saveConfig()
    }

    function toggleSafeNotifications() {
        safeNotifications = !safeNotifications
        saveConfig()
    }

    function toggleOptimizeMemory() {
        optimizeMemory = !optimizeMemory
        saveConfig()
    }

    IpcHandler {
        target: "config"
        function open_popup(popup: string): void {PopupManager.open(popup)}
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
        function toggle_grids(): void {root.showGrid()}
        function toggle_minimal(): void {root.toggleMinimal()}
        function toggle_memory_optimize(): void {root.toggleOptimizeMemory()}
        function toggle_safe_notifications(): void {root.toggleSafeNotifications()}
        function toggle_hints(): void {root.toggleHints()}
        function toggle_dnd(): void {root.toggleDND()}


        function dummy(): void {
            // Contains debugging features that can be accessed by SUPER + P

            //HyprInfo.getCursorPos()
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
