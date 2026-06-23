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
    property var installTarget: []
    property var installPlan: {
        "toInstall": [], // Dependencies (install)
        "willReplace": [], // Replaces (remove)
        "conflictsWith": [], // Conflicts (remove)
        "totalDownload": "",
        "totalInstalled": "",
    }
    property string installLog: sanitizeTerminalOutput(processANSI(rawInstallLog))
    property string rawInstallLog: ""
    property int installLogCursor: 0
    property int installLogLastNewline: 0
    property string pendingPrompt: ""
    property int installExitCode: 0

    signal promptRequested(prompt: string)
    signal installCompleted(exitCode: int)

    function cancelInstallation() {
        if (installer.running) {
            installer.signal(2)
            pacmanState = "cancel"
            return
        }
        pacmanState = "idle"
        installTarget = []
        installPlan = {
            "toInstall": [], // Dependencies (install)
            "willReplace": [], // Replaces (remove)
            "conflictsWith": [], // Conflicts (remove)
            "totalDownload": "",
            "totalInstalled": "",
        }
        rawInstallLog = ""
        installLogCursor = 0
        pendingPrompt = ""
    }

    function requestInstallation(pkgs: var) {
        if (pacmanState != "idle") return
        for (const pkg of pkgs) {
            if (isInstalled(pkg)) {
                console.log("PacmanInfo (requestIntallation): " + name + " has already been installed. Rejecting request.")
                return
            }
        }
        installTarget = pkgs
        //fetch()
        pacmanState = "prepare"
        preparePreFlight()
    }

    function prepareInstallation() {
        for (const pkg of installTarget) {
            if (isInstalled(pkg)) {
                console.log("PacmanInfo (prepareInstallation): " + installTarget + " has already been installed. Rejecting request.")
                cancelInstallation()
                return
            }
        }
        pacmanState = "pre-flight"
    }

    function confirmInstallation() {
        pacmanState = "authentication"
        installer.running = true
    }

    function sanitizeTerminalOutput(rawText) {
        // 1. Strip OSC sequences (host/user context logs)
        let noOsc = rawText.replace(/\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)/g, '');

        // 2. Strip ALL standard ANSI/CSI escape codes (including those with '?')
        let clean = noOsc.replace(/\x1b\[\??[0-9;]*[a-zA-Z]/g, '');

        return clean;
    }

    // State tracking object
    property var installState: {
        "currentPhase": "START", // START, DOWNLOAD, CHECKS, INSTALL, HOOKS, DONE
        "progressData": {},
        "overallProgress": 0     // 0 to 100
    };

    function trackPacmanProgress(line) {
        if (line.includes(":: Running post-transaction hooks...")) {
            installState.currentPhase = "HOOKS"
        } else if (line.includes(":: Processing package changes...")) {
            installState.currentPhase = "INSTALL"
        } else if (line.includes(":: Retrieving packages...")) {
            installState.currentPhase = "DOWNLOAD"
        } else if (line.includes("resolving dependencies...")) {
            installState.currentPhase = "START"
        }

        if (installState.currentPhase == "DOWNLOAD") {
            let data = []
            let currentPkg = 1
            let totalPkg = 1
            let downloadedSize = "0 B"
            let downloadSpeed = "0 B/s"
            let estimateTime = "inf"
            let percentage = 0
            if (installPlan.toInstall.length > 1) {
                data = line.match(/Total\s+\((\d+)\/(\d+)\)\s+(\d+.\d+\s+(B|MiB|KiB|GiB))\s+(\d+(.\d+)?\s+(B|MiB|KiB|GiB)\/s)\s+((\d+|--):(\d+|--))\s+\[.*?]\s+(\d+)%/)
                if (data) {
                    currentPkg = parseInt(data[1])
                    totalPkg = parseInt(data[2])
                    downloadedSize = data[3]
                    downloadSpeed = data[5]
                    estimateTime = data[8]
                    percentage = parseInt(data[11])
                }
            } else {
                data = line.match(/.*\s+(\d+(.\d+)?\s+(B|MiB|KiB|GiB))\s+(\d+(.\d+)?\s+(B|MiB|KiB|GiB)\/s)\s+((\d+|[-]+):(\d+|[-]+))\s+\[.*?]\s+(\d+)%/)
                currentPkg = 1
                totalPkg = 1
                if (data)  {
                    downloadedSize = data[1]
                    downloadSpeed = data[4]
                    estimateTime = data[7]
                    percentage = parseInt(data[10])
                }
            }
            installState.progressData = {
                "currentPkg": currentPkg,
                "totalPkg": totalPkg,
                "downloadedSize": downloadedSize,
                "downloadSpeed": downloadSpeed,
                "estimateTime": estimateTime,
                "percentage": parseInt(percentage),
            }
            installState.overallProgress = Math.round(percentage*0.7)
        }

        if (installState.currentPhase == "INSTALL") {
            let lines = line.split("\n")
            let data
            for (let i = lines.length - 1; i >= 0; i--) {
                data = lines[i].match(/\((\d+)\/(\d+)\).*\[.*\]\s+(\d+)%/)
                if (data) {
                    break
                }
            }
            let currentPkg = parseInt(data[1])
            let totalPkg = parseInt(data[2])
            let percentage = parseInt(data[3])
            installState.progressData = {
                "currentPkg": currentPkg,
                "totalPkg": totalPkg,
                "percentage": Math.round(percentage*(1/(totalPkg)) + ((currentPkg-1)/totalPkg)*100),
            }
            installState.overallProgress = 70 + Math.round((percentage*(1/(totalPkg)) + ((currentPkg-1)/totalPkg)*100)*0.2)
        }

        if (installState.currentPhase == "HOOKS") {
            console.log(line)
            let lines = line.split("\n")
            let data
            for (let i = lines.length - 1; i >= 0; i--) {
                data = lines[i].match(/\((\d+)\/(\d+)\).*/)
                if (data) {
                    break
                }
            }
            let currentStep = parseInt(data[1])
            let totalStep = parseInt(data[2])
            installState.progressData = {
                "currentStep": currentStep,
                "totalStep": totalStep,
                "percentage": Math.round((currentStep/totalStep)*100)
            }
            installState.overallProgress = 90 + Math.round((currentStep/totalStep)*100*0.1)
        }

        //console.log(JSON.stringify(installState,null,2))
    }

    function processANSI(rawText) {
        let lines = [""];
        let cursorLine = 0;
        let cursorCol = 0;

        // Updated regex: Supports optional '?' for private modes like ?25l
        const ansiRegex = /\x1B\[(\??[0-9;]*)([A-Za-z])/g;
        let match;
        let lastIndex = 0;

        while ((match = ansiRegex.exec(rawText)) !== null) {
            let normalText = rawText.substring(lastIndex, match.index);
            if (normalText.length > 0) {
                for (let i = 0; i < normalText.length; i++) {
                    let char = normalText[i];
                    if (char === '\n') {
                        cursorLine++;
                        if (cursorLine >= lines.length) lines.push("");
                        cursorCol = 0;
                    } else if (char === '\r') {
                        cursorCol = 0;
                    } else {
                        let currentLine = lines[cursorLine];
                        if (cursorCol < currentLine.length) {
                            lines[cursorLine] = currentLine.substring(0, cursorCol) + char + currentLine.substring(cursorCol + 1);
                        } else {
                            lines[cursorLine] += char;
                        }
                        cursorCol++;
                    }
                }
            }

            let params = match[1]; // e.g., "7" or "?25"
            let command = match[2]; // e.g., "m" or "l"

            // If it's a private mode command (starts with ?), we safely ignore it 
            // without letting it bleed into the text.
            if (!params.startsWith('?')) {
                let value = params ? parseInt(params) : 1;
                if (isNaN(value)) value = 1;

                switch (command) {
                    case 'F':
                    cursorLine = Math.max(0, cursorLine - value);
                    cursorCol = 0;
                    break;
                    case 'E':
                    cursorLine += value;
                    while (cursorLine >= lines.length) lines.push("");
                    cursorCol = 0;
                    break;
                    case 'A':
                    cursorLine = Math.max(0, cursorLine - value);
                    break;
                    case 'B':
                    cursorLine += value;
                    while (cursorLine >= lines.length) lines.push("");
                    break;
                    case 'C':
                    cursorCol += value;
                    break;
                    case 'D':
                    cursorCol = Math.max(0, cursorCol - value);
                    break;
                    default:
                    break;
                }
            }

            lastIndex = ansiRegex.lastIndex;
        }

        let remainingText = rawText.substring(lastIndex);
        if (remainingText.length > 0) {
            for (let i = 0; i < remainingText.length; i++) {
                let char = remainingText[i];
                if (char === '\n') {
                    cursorLine++;
                    if (cursorLine >= lines.length) lines.push("");
                    cursorCol = 0;
                } else if (char === '\r') {
                    cursorCol = 0;
                } else {
                    let currentLine = lines[cursorLine];
                    if (cursorCol < currentLine.length) {
                        lines[cursorLine] = currentLine.substring(0, cursorCol) + char + currentLine.substring(cursorCol + 1);
                    } else {
                        lines[cursorLine] += char;
                    }
                    cursorCol++;
                }
            }
        }

        return lines.join("\n");
    }

    function appendLog(text: string) {
        rawInstallLog += text
        trackPacmanProgress(installLog)
        if (installLog.split("\n").slice(-1).toString().toLowerCase().includes("[y/n]")) {
            installer.write("y\n")
        }
    }

    Process {

        id: installer

        property string pkg: root.installTarget

        property string rawLog: ""

        onRunningChanged: {
            if (running) {
                rawLog = ""
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

        command: ["script", "-qc", `sudo -S -k -p '' env COLUMNS=84 LINES=0 pacman -S ${pkg}`, "/dev/null"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: (text) => {
                root.appendLog(text)
            }
        }

        stderr: SplitParser {
            splitMarker: ""
            onRead: (text) => {
                console.log("PacmanInfo (installer) error: " + text)
            }
        }

        onExited: (exitCode, exitStatus) => {
            console.log("PacmanInfo (installer): exitCode: " + exitCode + ", exitStatus: " + exitStatus)
            fetch()
            if (root.pacmanState == "cancel") {
                root.pacmanState = "idle"
                root.installTarget = ""
                root.installPlan = {
                    "toInstall": [], // Dependencies (install)
                    "willReplace": [], // Replaces (remove)
                    "conflictsWith": [], // Conflicts (remove)
                    "totalDownload": "",
                    "totalInstalled": "",
                }
                root.installLog = ""
                root.pendingPrompt = ""
                return
            }
            if (exitCode == 0) {
                root.pacmanState = "success"
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
            } else if (search_mode == 3) {
                matchesQuery = item.name.trim() == q.trim()
            }

            // If filter_installed is true, it MUST be installed. 
            // If false, return everything that matches regardless of install status.
            return installed ? (matchesQuery && item.installed) : matchesQuery
        })
    }

    property bool installed: false

    property bool outdated: false

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

        command: ["python", root.preflight_path, ...root.installTarget]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.installPlan = JSON.parse(text)
                    // console.log(text)
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

        environment: ({
            COLUMNS: 71,
        })

        stdout: SplitParser {
            splitMarker: ""
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
