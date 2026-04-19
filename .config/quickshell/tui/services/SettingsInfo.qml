pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property bool hints: true

    signal showGrid()

    IpcHandler {
        target: "config"
        function open_popup(popup: string): void {PopupManager.open(popup)}
        function set_color_theme(color: string): void {Colors.current = color}
        function audio_check(): void {
            const rng = Math.random()
            const sound = Math.round(rng*3)
            const sounds = ["hallo","mambo","mambo_tongye","mambo_wow"]
            AudioInfo.playSound(sounds[sound], 1)
        }
        function toggle_grids(): void {root.showGrid()}
        function toggle_hints(): void {root.hints = !root.hints}
    }

    Process {
        id: exec
    }

}
