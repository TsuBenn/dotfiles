pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string path: SystemInfo.configdir + "/scripts/pacman-filter.py"

    property var packages: []

    Process {

        id: searcher

        property string query: ""

        command: ["python", root.path, "-s", query]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.packages = JSON.parse(text)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log("PacmanInfo (loader): " + text)
                }
            }
        }

    }

    Process {

        id: loader

        command: ["python", root.path, "-l"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.packages = JSON.parse(text)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log("PacmanInfo (loader): " + text)
                }
            }
        }

    }

    Process {

        id: cacher

        running: true
        command: ["python", root.path, "-l", "-r"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.packages = JSON.parse(text)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log("PacmanInfo (cacher): " + text)
                }
            }
        }

    }

}
