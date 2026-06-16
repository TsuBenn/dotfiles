pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string path: SystemInfo.configdir + "/scripts/pacman-filter.py"

    property bool fetching: fetcher.running

    property string query: ""

    onInstalledChanged: {
        queryChanged()
    }

    onSearch_modeChanged: {
        queryChanged()
    }

    onPackagesChanged: {
        queryChanged()
    }

    onQueryChanged: {
        if (!query) {
            search_results = packages
            return
        }

        const q = query.toLowerCase()

        search_results = packages.filter((item) => {
            const matchName = item.name.toLowerCase().includes(q)
            const matchDesc = item.description.toLowerCase().includes(q)
            const matchRepo = item.repository.toLowerCase().includes(q)

            let matchesQuery = matchName

            if (search_mode == 0) {
                matchesQuery = matchesQuery || matchDesc || matchRepo
            } else if (search_mode == 2) {
                matchesQuery = item.name.trim() == q.trim()
            }

            // If filter_installed is true, it MUST be installed. 
            // If false, return everything that matches regardless of install status.
            return installed ? (matchesQuery && item.installed) : matchesQuery
        })
    }

    property bool installed: false

    /* search mode
     * 0 -> pretty_fuzzy
     * 1 -> name_only
     * 2 -> exact_match
     */
    property int search_mode: 0

    property var packages: []

    property var search_results: packages

    property var info: ({})

    function getInfo(pkg: string) {
        if (!pkg) {
            info = ({})
            return
        }
        if (info.running) info.running = false
        info.pkg = pkg
        info.running = true
    }

    function search(query: string) {
        if (!query) {
            root.query = ""
            return
        }
        root.query = query.toLowerCase()
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

        id: lister

        command: ["python", root.path, "list-all"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    //console.log(text)
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

        id: fetcher

        running: true
        command: ["python", root.path, "fetch"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log(text)
                    lister.running = true
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
