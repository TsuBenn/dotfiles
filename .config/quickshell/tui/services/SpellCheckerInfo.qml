pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var results: []

    function check(text: string) {
    }

    Process {

        onRunningChanged: {
            if (!running) {
                console.log("SpellChecker closed unexpectingly, restarting...");
                running = true;
            }
        }
        running: true
        command: [SystemInfo.configdir + "/scripts/spellchecker"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    if (text == "*") {
                        root.results = [];
                    } else {
                        const suggestions = text.split(" ");
                        root.results = suggestions;
                    }
                }
            }
        }
    }
}
