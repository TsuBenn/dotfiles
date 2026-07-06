pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var files: ({})

    function getValue(filename: string): string {
        return files[filename] ?? "File not found";
    }

    Process {

        command: ["python", SystemInfo.configdir + "/scripts/readme_loader.py", SystemInfo.configdir + "/scripts/readme"]

        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // console.log(text);
                root.files = JSON.parse(text);
            }
        }
    }
}
