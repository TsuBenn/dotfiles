pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property string path: SystemInfo.configdir + "/scripts/pacman-filter.py"
    property string preflight_path: SystemInfo.configdir + "/scripts/pacman-pre-flight.py"

    property bool fetching: fetcher.running
    property bool checking_updates: updates_checker.running
    property bool updates_checker_authorized: false

    signal fetched()

    property string query: ""

    onFetched: {
        if (pacmanState == "prepare") {
            preparePreFlight()
        }
    }

    /*
     1.   idle           (Show pacman list, search, info).
     1.1. prepare        (Fetch the newest data possible).
     2.   pre-flight     (Show package's requirements, conflictions, replaces before actually installing).
     3.   authentication (Authenticate for sudo).
     4.   running        (Pacman do its thing).
     4.1. prompt         (Pacman ask for user input, mostly yes or no).
     4.2. cancel         (Kill Pacman).
     5.   success        (Show that it succeed).
     5.1  failed         (Show that it failed).
     6.   reset          (Go back to Idle)
     */
    property string pacmanState: "idle"
    property string installTarget: ""
    property var installPlan: {
        "toInstall": [], // Dependencies (install)
        "willReplace": [], // Replaces (remove)
        "conflictsWith": [], // Conflicts (remove)
        "totalDownload": "",
        "totalInstalled": "",
    }
    property var installLog: []
    property string pendingPrompt: ""
    property int installExitCode: 0

    signal promptRequested(prompt: string)
    signal installCompleted(exitCode: int)

    function cancelInstallation() {
        pacmanState = "idle"
        installTarget = ""
        installPlan = {
            "toInstall": [], // Dependencies (install)
            "willReplace": [], // Replaces (remove)
            "conflictsWith": [], // Conflicts (remove)
            "totalDownload": "",
            "totalInstalled": "",
        }
        installLog = []
        pendingPrompt = ""
        installer.running = false
    }

    function requestInstallation(name: string) {
        if (pacmanState != "idle") return
        if (isInstalled(name)) {
            console.log("PacmanInfo (requestIntallation): " + name + " has already been installed. Rejecting request.")
            return
        }
        installTarget = name
        fetch()
        pacmanState = "prepare"
    }

    function prepareInstallation() {
        if (isInstalled(installTarget)) {
            console.log("PacmanInfo (prepareInstallation): " + installTarget + " has already been installed. Rejecting request.")
            cancelInstallation()
            return
        }
        pacmanState = "pre-flight"
    }

    function confirmInstallation() {
        pacmanState = "authentication"
        installer.running = true
    }

    SequentialAnimation {
        id: succeed
        ScriptAction {
            script: {
                root.pacmanState = "success"
            }
        }
        PauseAnimation {
            duration: 1000
        }
        ScriptAction {
            script: {
                root.pacmanState = "idle"
            }
        }
    }

    Process {

        id: installer

        property string pkg: root.installTarget

        onRunningChanged: {
            if (running) {
                AuthInfo.verify("Installing <b>" + root.installTarget + "</b>", "Authenticate for installation.", function(s, p) {
                    if (s) {
                        installer.write(p+"\n")
                        root.pacmanState = "installing"
                    } else {
                        root.cancelInstallation()
                    }
                })
            }
        }

        command: ["sudo", "-S", "-k", "-p", "", "pacman", "-S", "--noconfirm", pkg]

        stdout: SplitParser {
            splitMarker: ""
            onRead: (text) => {
                console.log(text)
                root.installLog.push(text)
            }
        }

        stderr: SplitParser {
            splitMarker: ""
            onRead: (text) => {
                root.installLog.push(text)
            }
        }

        onExited: (exitCode, exitStatus) => {
            console.log("PacmanInfo (installer): exitCode: " + exitCode + ", exitStatus: " + exitStatus)
            if (exitCode == 0) {
                succeed.start()
            }
        }

    }

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
                q = q.replace(/ /g, "").replace(/-/g, "").replace(/_/g, "")
                matchName = item.name.toLowerCase().replace(/ /g, "").replace(/-/g, "").replace(/_/g, "").includes(q)
                matchDesc = item.description.toLowerCase().replace(/ /g, "").replace(/-/g, "").replace(/_/g, "").includes(q)
                matchRepo = item.repository.toLowerCase().replace(/ /g, "").replace(/-/g, "").replace(/_/g, "").includes(q)
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

    property bool outdated: false

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

    function preparePreFlight() {
        if (preflighter.running) preflighter.running = false
        preflighter.running = true
    }

    function check_updates() {
        updates_checker.running = true
        if (pacmanState != "idle") {
            return
        } else {
            pacmanState = "checking_updates"
        }
        AuthInfo.verify("Authenticate", "Synchronize package databases.", function(s, p) {
            if (s) {
                console.log("Authorize updates checker success!")
                root.updates_checker_authorized = true
                updates_checker.write(p+"\n")
            } else {
                console.log("Authorize updates checker failed!")
                root.updates_checker_authorized = false
                updates_checker.running = false
            }
        })
    }

    function fetch() {
        if (pacmanState == "idle") {
            pacmanState = "fetching"
        }
        if (fetcher.running) fetcher.running = false
        fetcher.running = true
    }

    Process {

        id: preflighter

        command: ["python", root.preflight_path, root.installTarget]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.installPlan = JSON.parse(text)
                    prepareInstallation()
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log("PacmanInfo (preflighter): " + text)
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
                    if (root.pacmanState == "fetching") root.pacmanState = "idle"
                    console.log(text)
                    root.fetched()
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

    Process {

        id: updates_checker

        command: ["sudo", "-S", "-k", "-p", "", "pacman", "-Sy"]

        onRunningChanged: {
            root.updates_checker_authorized = false
        }

        stdout: SplitParser {
            splitMarker: ["\n", "\r"]
            onRead: (text) => {
                console.log("PacmanInfo (updates_checker): " + text)
            }
        }

        onExited: (exitCode, exitStatus) => {
            console.log("PacmanInfo (updates_checker): exitCode: " + exitCode + ", exitStatus: " + exitStatus)
            if (exitCode == 0) {
                root.fetch()
            }
            root.pacmanState = "idle"
        }

    }

}
