pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property string cache_path: SystemInfo.configdir + "/scripts/screenshot_cache.ppm"

    property string path: SystemInfo.homedir + "/Screenshots/"

    property int x: 0
    property int y: 0

    property int w: 0
    property int h: 0

    signal cached()

    function requestCache() {
        cacher.running = true
    }

    function screenshot(x: int, y: int, w: int, h: int, name = "", copy = true, save = true) {
        const now = new Date();

        const day     = now.getDate().toString().padStart(2, "0");
        const month   = (now.getMonth() + 1).toString().padStart(2, "0");   
        const year    = now.getFullYear();  
        const hours   = now.getHours().toString().padStart(2, "0");   
        const minutes = now.getMinutes().toString().padStart(2, "0"); 
        const seconds = now.getSeconds().toString().padStart(2, "0"); 

        if (!name) name = `screenshot_${day}_${month}_${year}_${hours}${minutes}${seconds}`;

        const path = `${root.path}${name}.png`; // Added a slash to prevent folder name mashup

        // Build the base crop command with single-quoted paths to handle spaces safely
        let shellScript = `magick '${root.cache_path}' -crop ${w}x${h}+${x}+${y} +repage png:-`;

        // Dynamically append the pipeline stages based on booleans
        if (save && copy) {
            shellScript += ` | tee '${path}' | wl-copy`;
        } else if (save) {
            shellScript += ` > '${path}'`; 
        } else if (copy) {
            shellScript += ` | wl-copy`;
        }

        // Pass the single unified string to bash -c
        const command = ["bash", "-c", shellScript];

        // Execution trigger fix: run even if it's JUST a copy operation
        if (save || copy) {
            SystemInfo.runDetached(command);
            NotificationsInfo.send(
                "SCREENSHOTS", "",
                "Screenshot " + (save ? (copy ? "saved and copied" : "saved") : "copied"),
                save ? "Saved in <i>" + path : "Copied to clipboard",
                0, false,
                save ? "dolphin --select " + path : "echo Copied"
            )
        }
    }

    Process {

        id: cacher

        command: ["grim","-c","-t","ppm", root.cache_path]

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) return
                root.cached()
            }
        }

    }

}
