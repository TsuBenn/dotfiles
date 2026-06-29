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
    property int installExitCode: 0

    signal promptRequested(prompt: string)
    signal installCompleted(exitCode: int)

    function reset() {
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
        installState = {
            "currentPhase": "START", // START, DOWNLOAD, CHECKS, INSTALL, HOOKS, DONE
            "progressData": {},
            "overallProgress": 0     // 0 to 100
        }
    }

    function cancelInstallation() {
        if (installer.running) {
            installer.write("\x03")
            pacmanState = "cancel"
            return
        }
        reset()
    }

    function requestInstallation(pkgs: var) {
        if (pacmanState != "idle") return
        for (const pkg of pkgs) {
            if (isInstalled(pkg)) {
                console.log("PacmanInfo (requestInstallation): " + pkg + " has already been installed. Rejecting request.")
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
            if (installPlan.toInstall.filter(item => item.downloadBytes > 0).length > 1) {
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
                data = line.match(/.*\s+(\d+(.\d+)?\s+(B|MiB|KiB|GiB))\s+(\d+(.\d+)?\s+(B|MiB|KiB|GiB)\/s)\s+((\d+|--):(\d+|--))\s+\[.*?]\s+(\d+)%/)
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
            installState.overallProgress = 90 + Math.round((currentStep/totalStep)*10)
        }

        //console.log(JSON.stringify(installState,null,2))
        installStateChanged()
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

        property string pkg: root.installTarget.join(" ")

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

        command: ["script", "-qc", `sudo -S -k -p '' env COLUMNS=94 LINES=0 pacman -S ${pkg}`, "/dev/null"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: (text) => {
                //console.log(text)
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
            root.installExitCode = exitCode
            fetch()
            if (root.pacmanState == "cancel") {
                root.reset()
                return
            }
            if (exitCode == 0) {
                root.pacmanState = "success"
            }
        }

    }

    // ─── Search & Filter ──────────────────────────────────────────
    //
    // All filtering (query + installed + outdated) happens in a single
    // pass inside onQueryChanged.  PacmanPopup.list.datas no longer
    // needs a secondary .filter().

    property bool installed: false

    property bool outdated: false

    onInstalledChanged:  { queryChanged() }
    onOutdatedChanged:   { queryChanged() }
    onSearch_modeChanged: { queryChanged() }
    onPackagesChanged:    { rebuildIndices(); queryChanged() }

    property int search_mode: 0

    property var search_modes: [
        "Normal",      // Just includes
        "Fuzzy",       // Remove spaces and connectors ("-", "_")
        "Name",        // Search using names only
        "Exact",       // Exact match
        "Auto select", // Act as pacman args for pacman -S "pkg1" "pkg2" with each pkg between space would use the search capability to act as auto complete for that specific package
    ]

    property var packages: []

    property var search_results: packages

    // ─── Lookup Indices ───────────────────────────────────────────
    //
    // Built once in rebuildIndices() whenever `packages` changes.
    //
    //   nameIndex   : { [pkgName]: arrayIndex }   — O(1) by name
    //   installedSet: { [pkgName]: true }          — O(1) installed check
    //
    // Pre-computed search fields are also attached directly onto each
    // package object at the same time so onQueryChanged never has to
    // .toLowerCase() or .replace() per-item per-keystroke.

    property var nameIndex: ({})

    property var installedSet: ({})

    function rebuildIndices() {
        nameIndex = {}
        installedSet = {}
        for (let i = 0; i < packages.length; i++) {
            let p = packages[i]
            nameIndex[p.name] = i
            if (p.installed) installedSet[p.name] = true

            // Pre-computed search fields (one-time cost at load)
            p.name_lower = p.name.toLowerCase()
            p.desc_lower = p.description.toLowerCase()
            p.repo_lower = p.repository.toLowerCase()
            p.name_fuzzy = p.name_lower.replace(/[-_ ]/g, "")
            p.desc_fuzzy = p.desc_lower.replace(/[-_ ]/g, "")
            p.repo_fuzzy = p.repo_lower.replace(/[-_ ]/g, "")
        }
    }

    // ─── O(1) Lookups ─────────────────────────────────────────────

    function isInstalled(pkg: string): bool {
        return installedSet[pkg] === true
    }

    function getPackage(pkg: string): var {
        let idx = nameIndex[pkg]
        return idx !== undefined ? packages[idx] : null
    }

    function getPackageIndex(pkg: string): int {
        let idx = nameIndex[pkg]
        return idx !== undefined ? idx : -1
    }

    // ─── Search Entry Point ───────────────────────────────────────

    function search(query: string) {
        if (!query) {
            root.query = ""
            return
        }
        root.query = query.toLowerCase()
    }

    // ─── Unified Filter ───────────────────────────────────────────
    //
    // Single-pass: query matching + installed filter + outdated filter
    // are all evaluated together.  No secondary .filter() needed in
    // PacmanPopup.

    onQueryChanged: {
        // ── No query: apply only installed/outdated filters ──
        if (!query) {
            if (installed && outdated) {
                search_results = packages.filter(i => i.installed && i.latest_version != "")
            } else if (installed) {
                search_results = packages.filter(i => i.installed)
            } else if (outdated) {
                search_results = packages.filter(i => i.latest_version != "")
            } else {
                search_results = packages
            }
            return
        }

        let q = query

        // ── Mode 3: Exact match — O(1) lookup ──
        if (search_mode == 3) {
            let idx = nameIndex[q.trim()]
            if (idx !== undefined) {
                let item = packages[idx]
                if (installed && !item.installed) { search_results = []; return }
                if (outdated && !item.latest_version) { search_results = []; return }
                search_results = [item]
            } else {
                search_results = []
            }
            return
        }

        // ── Pre-process query once (not per-item) ──
        let qFuzzy
        if (search_mode == 1) {
            qFuzzy = q.replace(/[-_ ]/g, "")
        }
        let qTrimmed = q.trim()

        // ── Single-pass filter ──
        search_results = packages.filter((item) => {

            let matchesQuery

            switch (search_mode) {
                case 0: // Normal — includes on name/desc/repo
                matchesQuery = item.name_lower.includes(q)
                || item.desc_lower.includes(q)
                || item.repo_lower.includes(q)
                break

                case 1: // Fuzzy — stripped includes on name/desc/repo
                matchesQuery = item.name_fuzzy.includes(qFuzzy)
                || item.desc_fuzzy.includes(qFuzzy)
                || item.repo_fuzzy.includes(qFuzzy)
                break

                case 2: // Name — includes on name only
                matchesQuery = item.name_lower.includes(q)
                break

                case 4: // Auto select — startsWith on name
                matchesQuery = item.name_lower.startsWith(qTrimmed)
                break

                default:
                matchesQuery = false
            }

            if (!matchesQuery) return false

            // Combined installed/outdated filter in the same pass
            if (installed && !item.installed) return false
            if (outdated && !item.latest_version) return false

            return true
        })
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
                cancelInstallation()
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
                    const data = JSON.parse(text)
                    if (data.error) {
                        root.installPlan = {
                            "error": (data.error.match(/error:\s+(.*)/)[1] ?? "Something went wrong") + ", confirm the installation to see more details.",
                            "toInstall": [],
                            "willReplace": [],
                            "conflictsWith": [],
                            "totalDownload": "",
                            "totalInstalled": "",
                        }
                    } else {
                        root.installPlan = data
                    }
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

    function formatBytes(bytes, decimals = 1) {
        if (bytes === 0) return "0 B"
        if (!bytes || bytes < 0) return ""

        const units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
        const k = 1024

        const i = Math.floor(Math.log(bytes) / Math.log(k))
        const unit = units[Math.min(i, units.length - 1)]

        // For B, no decimals (it's an integer). For larger units, show decimals.
        if (i === 0) return bytes + " B"

        const value = bytes / Math.pow(k, i)
        return value.toFixed(decimals) + " " + unit
    }

    function convertToBytes(str) {
        if (!str) return 0

        const s = str.trim().toLowerCase()
        if (!s) return 0

        // Match a number (with optional decimals) followed by an optional unit.
        // The unit can be: b, kib/kb/k, mib/mb/m, gib/gb/g, tib/tb/t, pib/pb/p
        // We treat decimal (KB) and binary (KiB) units the same — both 1024,
        // because pacman uses MiB but users might type MB and we want to be
        // forgiving. The lowercase "b" by itself is bytes.
        const match = s.match(/^([\d.]+)\s*(b|kib|kb|k|mib|mb|m|gib|gb|g|tib|tb|t|pib|pb|p)?$/)
        if (!match) return 0

        const value = parseFloat(match[1])
        if (isNaN(value)) return 0

        const unit = match[2] || "b"

        const multipliers = {
            "b": 1,
            "k": 1024, "kib": 1024, "kb": 1024,
            "m": 1024 * 1024, "mib": 1024 * 1024, "mb": 1024 * 1024,
            "g": 1024 * 1024 * 1024, "gib": 1024 * 1024 * 1024, "gb": 1024 * 1024 * 1024,
            "t": 1024 ** 4, "tib": 1024 ** 4, "tb": 1024 ** 4,
            "p": 1024 ** 5, "pib": 1024 ** 5, "pb": 1024 ** 5,
        }

        const mult = multipliers[unit]
        if (!mult) return 0

        return Math.round(value * mult)
    }

}
