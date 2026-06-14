pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string path: SystemInfo.configdir + "/scripts/pacman-filter.py"

    property var packages: []

    property var installed_packages: []

    property var search_results: []

    property var info: []

    function getInfo(pkg: string) {
        if (info.running) info.running = false
        info.pkg = pkg
        info.running = true
    }

    function search(query: string) {
        if (query == "") {
            searcher.running = false
            search_results = []
            return
        }
        if (searcher.running) searcher.running = false
        searcher.query = query
        searcher.running = true
    }

    function list() {
        if (lister.running) lister.running = false
        lister.running = true
    }

    function fetch() {
        if (fetcher.running) fetcher.running = false
        fetcher.running = true
    }

    Process {

        id: info

        property string pkg: ""

        command: ["python", root.path, "info", pkg]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.info = JSON.parse(text)
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

        id: searcher

        property string query: ""

        command: ["python", root.path, "search", query]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.search_results = JSON.parse(text)
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

        id: searcher_fresh

        property string query: searcher.query

        command: ["python", root.path, "search", query, "--fresh"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.search_results = JSON.parse(text)
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

        id: lister

        command: ["python", root.path, "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.installed_packages = JSON.parse(text)
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

        id: fetcher

        running: true
        command: ["python", root.path, "fetcher"]

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
