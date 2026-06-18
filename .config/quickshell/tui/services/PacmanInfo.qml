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

        let q = query

        search_results = packages.filter((item) => {

            let matchName
            let matchDesc
            let matchRepo

            if (search_mode == 1) {
                q = q.replace(/ /g, "").replace(/-/g, "")
                matchName = item.name.toLowerCase().replace(/ /g, "").replace(/-/g, "").includes(q)
                matchDesc = item.description.toLowerCase().replace(/ /g, "").replace(/-/g, "").includes(q)
                matchRepo = item.repository.toLowerCase().replace(/ /g, "").replace(/-/g, "").includes(q)
            } else {
                matchName = item.name.toLowerCase().includes(q)
                matchDesc = item.description.toLowerCase().includes(q)
                matchRepo = item.repository.toLowerCase().includes(q)
            }


            let matchesQuery = matchName

            if (search_mode == 0 || search_mode == 1) {
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

    property var search_modes: [
        "Normal",
        "Fuzzy",
        "Name",
        "Exact",
    ]

    property var packages: []

    property var search_results: packages

    function isInstalled(pkg: string): bool {
        return packages.some(item => item.name == pkg && item.installed)
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
