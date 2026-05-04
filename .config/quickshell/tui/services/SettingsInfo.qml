pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property bool hints: true
    property bool minimal: false
    property bool optimizeMemory: false // Reduce memory usage significantly, but takes more time to load UI elements

    signal showGrid()
    signal toggleMinimal()

    function notification_check() {
        NotificationsInfo.send("", "", "Notification Check", "Check check check!\nClick here to show another similar notification!", 0, false, () => notification_check())
    }

    function audio_check() {
        const rng = Math.random()
        const sound = Math.round(rng*3)
        const sounds = ["hallo","mambo","mambo_tongye","mambo_wow"]
        AudioInfo.playSound(sounds[sound], 1)
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
        function toggle_minimal(): void {root.minimal = !root.minimal; root.toggleMinimal()}
        function toggle_memory_optimize(): void {root.optimizeMemory = !root.optimizeMemory}
        function toggle_hints(): void {root.hints = !root.hints}


        function dummy(): void {
            // Contains debugging features that can be accessed by SUPER + P

            //HyprInfo.getCursorPos()
        }
    }

    Process {
        id: exec
    }

}
