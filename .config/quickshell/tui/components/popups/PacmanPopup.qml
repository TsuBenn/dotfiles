pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    id: root

    w: 90
    h: 44

    property string pacmanState: PacmanInfo.pacmanState

    onVisibleChanged: {
        list.selected_index = 0
        list.selected_pkg = ""
        PacmanInfo.query = ""
        list.reset()
    }

    onPromoted: {
        search_field.grabFocus()
    }

    shortcuts: [
        {
            binds: ["Up", "Shift+Tab"],
            action: () => {
                if (list.selected_pkg == "") {
                    list.selected_pkg = list.datas[list.offset].name
                    return
                }
                if (list.selected_index-1 < 0) {
                    list.offset -= list.h
                }
                list.selected_pkg = list.datas[list.offset + (list.selected_index+list.h-1)%list.h].name
            }
        },
        {
            binds: ["Down", "Tab"],
            action: () => {
                if (list.selected_pkg == "") {
                    list.selected_pkg = list.datas[list.offset].name
                    return
                }
                if (list.selected_index+1 >= list.h) {
                    list.offset += list.h
                }
                list.selected_pkg = list.datas[list.offset + (list.selected_index+list.h+1)%list.h].name
            }
        },
        {
            binds: "Ctrl+S",
            action: () => {
                PacmanInfo.search_mode = (PacmanInfo.search_mode + 1)%4
            }
        },
        {
            binds: "Ctrl+R",
            action: () => {
                if (
                    root.pacmanState == "idle"
                ) {
                    PacmanInfo.fetch()
                }
            }
        }
    ]

    Cells {

        w: parent.w
        h: parent.h

        color: "transparent"

        CellBox {

            id: box

            w: parent.w
            h: parent.h

            ColumnLayout {

                spacing: 0

                // Header
                RowLayout {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    spacing: 0

                    CellText {
                        text: "PACMAN " + root.pacmanState
                        color: Colors.secondary
                        font: Cell.fontBB
                    }

                    CellText {
                        text: " ("
                        color: Colors.fgDim
                    }

                    CellText {
                        text: list.datas.length.toString().padStart(PacmanInfo.packages.length.toString().length, " ")
                        color: Colors.info
                    }

                    CellText {
                        text: "/" + PacmanInfo.packages.length + " packages)"
                        color: Colors.fgDim
                    }

                }

                // Separator for header
                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                }

                // Package list
                CellScrollView {

                    visible: (
                        root.pacmanState == "idle"
                        || root.pacmanState == "prepare"
                        || root.pacmanState == "pre-flight"
                        || root.pacmanState == "authentication"
                        || root.pacmanState == "checking_updates"
                        || root.pacmanState == "fetching"
                    )

                    id: list

                    w: box.contentW
                    h: 14

                    property int selected_index: 0
                    property string selected_pkg: ""
                    property var multi_selected_pkg: []

                    property var datas: PacmanInfo.outdated ? PacmanInfo.search_results.filter(item => item.latest_version != "") : (PacmanInfo.installed ? PacmanInfo.search_results.filter(item => item.installed) : PacmanInfo.search_results)

                    property var optimized_data: datas.slice(list.offset,list.offset+list.h)

                    virtualH: true

                    contentH: Cell.h(1)*datas.length

                    source: ColumnLayout {

                        spacing: 0

                        Repeater {

                            model: list.optimized_data

                            delegate: Cells {

                                id: pkg

                                required property int index
                                required property var modelData

                                property string name: modelData.name
                                property string repo: modelData.repository
                                property string version: modelData.version
                                property string latest_version: modelData.latest_version
                                property bool installed: modelData.installed
                                property bool update_available: pkg.latest_version != ""

                                property bool selected: list.selected_pkg == name && !disabled

                                property bool disabled: PacmanInfo.fetching || PacmanInfo.checking_updates

                                w: list.contentW
                                h: 1

                                color: (selected ? Colors.accentStrong : (pkg_mouse.hovered ? Colors.bgOverlay : "transparent"))

                                onSelectedChanged: {
                                    if (selected) {
                                        list.selected_index = index
                                    }
                                }

                                RowLayout {

                                    x: Cell.w(1)

                                    spacing: Cell.w(1)

                                    CellText {
                                        text: pkg.installed ? "*" : " "
                                        color: pkg.disabled ? Colors.fgSubtle : (pkg.selected ? Colors.onAccent : Colors.success)
                                        font: Cell.fontB
                                    }

                                    CellText {
                                        text: pkg.name
                                        preferedW: list.contentW - 5 - pkg_version.w
                                        color: pkg.disabled ? Colors.fgSubtle : (pkg.selected ? Colors.onAccent : Colors.fgBase)
                                    }

                                    RowLayout {

                                        id: pkg_version

                                        property int w: Cell.wCount(implicitWidth)


                                        spacing: 0

                                        CellText {
                                            text: "("
                                            color: pkg.disabled ? Colors.fgSubtle : (pkg.selected ? Colors.onAccent : Colors.fgSubtle)
                                        }

                                        CellText {
                                            text: pkg.version
                                            color: pkg.disabled ? Colors.fgSubtle : (pkg.selected ? Colors.onAccent : (pkg.update_available ? Colors.blend(Colors.fgSubtle,Colors.danger,0.5) : Colors.fgSubtle))
                                        }

                                        CellText {
                                            visible: pkg.update_available
                                            text: " -> "
                                            color: pkg.disabled ? Colors.fgSubtle : (pkg.selected ? Colors.onAccent : Colors.fgSubtle)
                                        }

                                        CellText {
                                            visible: pkg.update_available
                                            text: pkg.latest_version
                                            color: pkg.disabled ? Colors.fgSubtle : (pkg.selected ? Colors.onAccent : Colors.success)
                                        }

                                        CellText {
                                            text: ")"
                                            color: pkg.disabled ? Colors.fgSubtle : (pkg.selected ? Colors.onAccent : Colors.fgSubtle)
                                        }

                                    }

                                }

                                MouseControl {

                                    id: pkg_mouse

                                    visible: !parent.disabled

                                    anchors.fill: parent

                                    onReleased: (button) => {
                                        if (button == "L") {
                                            if (list.selected_pkg == pkg.name) {
                                                list.selected_pkg = ""
                                                return
                                            }
                                            list.selected_pkg = pkg.name
                                        }
                                    }

                                }
                            }


                        }

                    }

                }

                // Search bar
                Cells {

                    visible: (
                        root.pacmanState == "idle"
                        || root.pacmanState == "prepare"
                        || root.pacmanState == "pre-flight"
                        || root.pacmanState == "authentication"
                        || root.pacmanState == "fetching"
                        || root.pacmanState == "checking_updates"
                    )

                    w: box.contentW
                    h: 3

                    CellBox {

                        w: parent.w
                        h: 3

                        RowLayout {

                            x: Cell.w(1)

                            spacing: Cell.w(1)

                            CellTextField {

                                id: search_field

                                w: box.contentW - 30 - search_mode.text.length - 3*PacmanInfo.fetching
                                h: 1

                                placeholder: "Search package"

                                escapeToUnFocus: false
                                unfocusOnEntered: false

                                onTextInput: (input) => {
                                    PacmanInfo.search(input)
                                }

                            }

                            CellLoading {
                                visible: PacmanInfo.fetching
                                style: 2
                            }

                            CellButton {

                                id: search_mode

                                text: PacmanInfo.search_modes[PacmanInfo.search_mode]

                                color: Colors.bgOverlay
                                fg:    Colors.fgBase

                                onReleased: (button) => {
                                    if (button == "L") {
                                        PacmanInfo.search_mode = (PacmanInfo.search_mode + 1)%4
                                    }
                                }

                            }

                            CellButton {

                                text: "Installed"

                                color: PacmanInfo.installed ? Colors.accentStrong : Colors.bgOverlay
                                fg:    PacmanInfo.installed ? Colors.onAccent : Colors.fgBase

                                onReleased: (button) => {
                                    if (button == "L") {
                                        PacmanInfo.installed = !PacmanInfo.installed
                                    }
                                }

                            }

                            CellButton {

                                text: "Outdated"

                                color: PacmanInfo.outdated ? Colors.accentStrong : Colors.bgOverlay
                                fg:    PacmanInfo.outdated ? Colors.onAccent : Colors.fgBase

                                onReleased: (button) => {
                                    if (button == "L") {
                                        PacmanInfo.outdated = !PacmanInfo.outdated
                                    }
                                }

                            }


                        }

                    }


                }

                // Breadcrumbs
                RowLayout {

                    visible: (
                        root.pacmanState == "idle"
                        || root.pacmanState == "fetching"
                    )

                    Layout.leftMargin: {
                        let result = list.selected_pkg.length + 2
                        for (const dep of info.deps) {
                            result += dep.length + 2*PacmanInfo.isInstalled(dep) + 4
                        }
                        return Cell.w(1 - Math.max(result - 76,0))
                    }

                    spacing: Cell.w(1)

                    CellText {
                        text: "* " + list.selected_pkg
                        color: info.deps.length > 0 ? Colors.fgSubtle : Colors.fgBase
                        font: Cell.fontB

                        MouseControl {

                            anchors.fill: parent

                            onReleased: (button) => {
                                if (button == "L") {
                                    info.deps = []
                                }
                            }

                        }
                    }

                    RowLayout {

                        spacing: Cell.w(1)

                        Repeater {

                            model: info.deps

                            delegate: RowLayout {

                                id: dep_crumb

                                required property int index
                                required property string modelData

                                property bool current: index == info.deps.length - 1

                                spacing: Cell.w(1)

                                CellText {
                                    text: "->"
                                    color: Colors.fgSubtle
                                }

                                CellText {
                                    visible: PacmanInfo.isInstalled(parent.modelData)
                                    text: "*"
                                    color: Colors.success
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: parent.modelData
                                    color: parent.current ? Colors.fgBase : Colors.fgSubtle
                                    font: parent.current ? Cell.fontB : Cell.font

                                    MouseControl {

                                        anchors.fill: parent
                                        anchors.leftMargin: -Cell.w(3)

                                        onReleased: (button) => {
                                            if (button == "L") {
                                                info.deps = info.deps.slice(0, dep_crumb.index+1)
                                            }
                                        }

                                    }

                                }

                            }

                        }

                    }

                }

                // Installing header
                CellText {
                    Layout.leftMargin: Cell.centerWCell(implicitWidth,parent.implicitWidth)

                    visible: (
                        root.pacmanState == "prepare"
                        || root.pacmanState == "pre-flight"
                        || root.pacmanState == "authentication"
                    )
                    text: "Installing <b>" + PacmanInfo.installTarget + "</b>"
                    color: Colors.secondary
                }

                // Check updates header
                CellText {
                    Layout.leftMargin: Cell.centerWCell(implicitWidth,parent.implicitWidth)

                    visible: (
                        root.pacmanState == "checking_updates"
                    )
                    text: "Synchronizing packages database"
                    color: Colors.secondary
                }

                // Separator for Breadcrumbs and Installing header
                CellSeparator {
                    visible: (
                        root.pacmanState == "idle"
                        || root.pacmanState == "prepare"
                        || root.pacmanState == "pre-flight"
                        || root.pacmanState == "authentication"
                        || root.pacmanState == "fetching"
                        || root.pacmanState == "checking_updates"
                    )
                    w: box.contentW
                    color: Colors.accentStrong
                }

                // Info
                RowLayout {

                    spacing: 0

                    CellScrollView {

                        visible: (
                            root.pacmanState == "idle"
                            || root.pacmanState == "fetching"
                        )

                        id: info

                        w: box.contentW
                        h: box.contentH - list.h - 9

                        property int dep_index: PacmanInfo.packages.findIndex(item => item.name == deps[deps.length-1])

                        property int index: PacmanInfo.packages.findIndex(item => item.name == list.selected_pkg)

                        onIndexChanged: {
                            deps = []
                        }

                        onDepsChanged: {
                            if (deps[deps.length-1] == list.selected_pkg) {
                                deps = []
                                depsChanged()
                                return
                            }
                            for (let i = 0; i < deps.length-1; i++) {
                                if (deps[deps.length-1] == deps[i]) {
                                    deps = deps.slice(0, i+1)
                                    depsChanged()
                                    return
                                }
                            }
                        }

                        property var datas: PacmanInfo.packages[deps.length > 0 ? dep_index : index]

                        property var deps: []

                        property int magic: 22

                        // ── Section visibility flags (for separator conditionals) ──
                        property bool hasIdentity:  (datas?.description ?? "").length > 0
                        || (datas?.url ?? "").length > 0
                        || (datas?.version ?? "").length > 0
                        || (datas?.licenses ?? []).length > 0

                        property bool hasSource:    (datas?.repository ?? "").length > 0
                        || (datas?.arch ?? "").length > 0
                        || (datas?.groups ?? []).length > 0

                        property bool hasFootprint: (datas?.download_size ?? "").length > 0
                        || (datas?.installed_size ?? "").length > 0
                        || (datas?.conflicts_with ?? []).length > 0
                        || (datas?.replaces ?? []).length > 0
                        || (datas?.provides ?? []).length > 0

                        // "Installed" is always rendered when index != -1, so hasStatus is always
                        // true alongside a real selection. Kept here for symmetry / future-proofing.
                        property bool hasStatus:    index != -1

                        property bool hasRelations: (datas?.required_by ?? []).length > 0
                        || (datas?.optional_for ?? []).length > 0
                        || (datas?.depends ?? []).length > 0
                        || (datas?.optional_deps ?? []).length > 0
                        || (datas?.make_deps ?? []).length > 0
                        || (datas?.check_deps ?? []).length > 0

                        component Info: RowLayout {

                            visible: value.length > 0 && info.index != -1

                            property string key: "Name"

                            property string value: info.datas.name

                            Layout.leftMargin: Cell.w(1)

                            spacing: 0

                            CellText {
                                Layout.alignment: Qt.AlignTop
                                text: (parent.key).padEnd(info.magic-4, " ") + ": "
                                color: Colors.fgDim
                            }

                            CellText {
                                text: parent.value
                                preferedW: info.contentW - info.magic
                                wrap: true
                            }

                        }

                        component Deps: RowLayout {

                            id: deps

                            property string key: "Dependencies"
                            property var values: info.datas?.depends ?? []

                            // ── Collapse behavior ──
                            // Initial visible rows, and step size for each "+N more" click.
                            // 5 / 5 keeps the default footprint small (longest list takes 5 rows)
                            // while making each expansion click cheap (~1ms for 5 new delegates).
                            property int collapseThreshold: 5
                            property int expandStep: 5

                            property var shownValues: deps.values?.slice(0, deps.shownCount)

                            // How many rows are currently visible. Initialized to the threshold,
                            // bumped by expandStep on "+N more", set to values.length on "show all",
                            // reset to collapseThreshold on "show less" or when the package changes.
                            property int shownCount: collapseThreshold

                            onValuesChanged: shownCount = collapseThreshold

                            Layout.leftMargin: Cell.w(1)

                            spacing: 0

                            CellText {
                                Layout.alignment: Qt.AlignTop
                                text: (parent.key).padEnd(info.magic-4, " ") + ":"
                                color: Colors.fgDim
                            }

                            ColumnLayout {

                                Layout.alignment: Qt.AlignTop

                                spacing: 0

                                Repeater {

                                    model: deps.shownValues

                                    delegate: Cells {

                                        id: dep

                                        required property string name
                                        required property bool installed

                                        // A "real" package exists in the cache as its own entry.
                                        // Virtual names (e.g. "sh" provided by bash, "java-runtime"
                                        // provided by java-runtime-common) are NOT in the cache and
                                        // must not be navigable — clicking them would push a
                                        // non-existent name onto the breadcrumb and break the panel.
                                        property bool isReal: PacmanInfo.packages.some(
                                            item => item.name == dep.dep_name
                                        )

                                        property var dep_data: {
                                            if (name.includes("<="))      return name.split("<=")
                                            else if (name.includes("<"))      return name.split("<")
                                            else if (name.includes(">=")) return name.split(">=")
                                            else if (name.includes(">")) return name.split(">")
                                            else if (name.includes("="))  return name.split("=")
                                            return [name]
                                        }
                                        property string version_ops: {
                                            if (name.includes("<="))      return "<="
                                            else if (name.includes("<"))      return "<"
                                            else if (name.includes(">=")) return ">="
                                            else if (name.includes(">"))      return ">"
                                            else if (name.includes("="))  return ""
                                            return ""
                                        }
                                        property string dep_name: dep_data[0]
                                        property string dep_version: dep_data[1] ?? ""

                                        // No hover highlight for virtual packages — reinforces
                                        // unclickability at the visual level.
                                        color: (dep.isReal && dep_mouse.hovered)
                                        ? Colors.bgOverlay
                                        : "transparent"

                                        w: info.contentW - info.magic + 2
                                        h: 1

                                        RowLayout {

                                            x: Cell.w(1)

                                            spacing: Cell.w(1)

                                            CellText {
                                                // Star column legend:
                                                //   *  = real package, installed      (green, clickable)
                                                //      = real package, not installed  (default, clickable)
                                                //   ~  = virtual / provided name      (dim, unclickable)
                                                text: dep.installed
                                                ? "*"
                                                : (dep.isReal ? "-" : "~")
                                                color: dep.installed
                                                ? Colors.success
                                                : Colors.fgSubtle
                                                font: Cell.fontB
                                            }

                                            CellText {
                                                text: dep.dep_name
                                                preferedW: Math.min(dep.w - 3, text.length)
                                                // Dim virtual names so they read as "informational"
                                                // rather than "navigable".
                                                color: dep.isReal ? Colors.fgBase : Colors.fgSubtle
                                            }

                                            CellText {
                                                id: dep_version
                                                text: dep.version_ops + dep.dep_version
                                                preferedW: dep.w - dep.dep_name.length - 5
                                                color: Colors.fgSubtle
                                            }

                                        }

                                        MouseControl {

                                            id: dep_mouse

                                            anchors.fill: parent

                                            // Disabled MouseControls don't track hover or fire
                                            // onReleased — exactly what we want for virtuals.
                                            enabled: dep.isReal

                                            onReleased: (button) => {
                                                if (button == "L") {
                                                    info.deps.push(dep.dep_name)
                                                    info.depsChanged()
                                                }
                                            }

                                        }

                                    }

                                }

                                // ──────────────────────────────────────────────────────────
                                // Footer: progressive +5 / show all / show less
                                //
                                // State machine (for a list of 23 items, threshold=5, step=5):
                                //
                                //   Initial       (5 shown)   →  [ + 18 more ]
                                //   1st click     (10 shown)  →  [ + 13 more ]  [ show all (23) ]
                                //   2nd click     (15 shown)  →  [ + 8 more  ]  [ show all (23) ]
                                //   "show all"    (23 shown)  →  [ show less ]
                                //   "show less"   (5 shown)   →  [ + 18 more ]
                                //
                                // The "show all" button only appears after the first expansion —
                                // progressive disclosure of the UI itself. Users who just want to
                                // peek at 5 more rows don't see the audit-nuclear option until
                                // they've shown they want to expand at all.
                                //
                                // "show less" replaces the other two when fully expanded, giving
                                // a clean single-action way back to the collapsed state.
                                // ──────────────────────────────────────────────────────────
                                RowLayout {

                                    spacing: Cell.w(1)

                                    // Footer only renders at all when there's something to expand.
                                    visible: deps.values?.length > deps.collapseThreshold

                                    // ── "+N more" — progressive expansion ──
                                    // Visible whenever we haven't shown everything yet.
                                    CellButton {
                                        padding: 0
                                        visible: deps.shownCount < deps.values?.length
                                        text: "[+ " + (deps.values?.length - deps.shownCount) + " more]"
                                        color: ["transparent",Colors.bgOverlay,Colors.bgOverlay]
                                        fg:    Colors.info
                                        onReleased: (button) => {
                                            if (button == "L") {
                                                deps.shownCount = Math.min(
                                                    deps.shownCount + deps.expandStep,
                                                    deps.values.length
                                                )
                                            }
                                        }
                                    }

                                    // ── "show all (N)" — audit escape hatch ──
                                    // Only after the first expansion, and only when there's still
                                    // more to show. Disappears once "+N more" has reached the end
                                    // (because "show less" takes over).
                                    CellButton {
                                        padding: 0
                                        visible: deps.shownCount > deps.collapseThreshold
                                        && deps.shownCount < deps.values?.length
                                        text: "[Show all (" + deps.values?.length + ")]"
                                        color: ["transparent",Colors.bgOverlay,Colors.bgOverlay]
                                        fg:    Colors.info
                                        onReleased: (button) => {
                                            if (button == "L") {
                                                deps.shownCount = deps.values?.length
                                            }
                                        }
                                    }

                                    // ── "show less" — collapse back to threshold ──
                                    // Only visible when fully expanded (and the list was collapsible
                                    // in the first place, i.e. exceeds the threshold).
                                    CellButton {
                                        padding: 0
                                        visible: deps.shownCount == deps.values?.length
                                        && deps.values?.length > deps.collapseThreshold
                                        text: "[Show less]"
                                        color: ["transparent",Colors.bgOverlay,Colors.bgOverlay]
                                        fg:    Colors.info
                                        onReleased: (button) => {
                                            if (button == "L") {
                                                deps.shownCount = deps.collapseThreshold
                                            }
                                        }
                                    }

                                }

                            }

                        }

                        source: ColumnLayout {

                            spacing: 0

                            // ── No selection placeholder ──
                            CellText {

                                visible: info.index == -1

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, info.implicitWidth)

                                text: "\nNo package selected"
                                color: Colors.fgDim

                            }

                            // ════════════ Section 1: Identity ════════════
                            Info {
                                key: "Description"
                                value: info.datas?.description ?? ""
                            }
                            Info {
                                key: "URL"
                                value: info.datas?.url ?? ""
                            }
                            Info {
                                key: "Version"
                                value: info.datas?.version ?? ""
                            }
                            Info {
                                key: "Licenses"
                                value: (info.datas?.licenses ?? []).join(", ")
                            }

                            CellSeparator {
                                w: info.contentW
                                visible: info.index != -1 && info.hasIdentity && info.hasSource
                                color: Colors.bgOverlay
                            }

                            // ════════════ Section 2: Source ════════════
                            Info {
                                key: "Repository"
                                value: info.datas?.repository ?? ""
                            }
                            Info {
                                key: "Architecture"
                                value: info.datas?.arch ?? ""
                            }
                            Info {
                                key: "Groups"
                                value: (info.datas?.groups ?? []).join(", ")
                            }

                            CellSeparator {
                                w: info.contentW
                                visible: info.index != -1 && info.hasSource && (info.hasFootprint || info.hasStatus || info.hasRelations)
                                color: Colors.bgOverlay
                            }

                            // ════════════ Section 3: Footprint ════════════
                            Info {
                                key: "Download size"
                                value: info.datas?.download_size ?? ""
                            }
                            Info {
                                key: "Installed size"
                                value: info.datas?.installed_size ?? ""
                            }
                            Deps {
                                visible: (info.datas?.conflicts_with ?? []).length > 0
                                key: "Conflicts with"
                                collapseThreshold: 10   // generous — this field is almost always short
                                values: (info.datas?.conflicts_with ?? []).map(
                                    n => ({ name: n, installed: PacmanInfo.isInstalled(n) })
                                )
                            }
                            Deps {
                                visible: (info.datas?.replaces ?? []).length > 0
                                key: "Replaces"
                                values: (info.datas?.replaces ?? []).map(
                                    n => ({ name: n, installed: PacmanInfo.isInstalled(n) })
                                )
                            }
                            Deps {
                                visible: (info.datas?.provides ?? []).length > 0
                                key: "Provides"
                                values: (info.datas?.provides ?? []).map(
                                    n => ({ name: n, installed: PacmanInfo.isInstalled(n) })
                                )
                            }

                            CellSeparator {
                                w: info.contentW
                                visible: info.index != -1 && info.hasFootprint && (info.hasStatus || info.hasRelations)
                                color: Colors.bgOverlay
                            }

                            // ════════════ Section 4: Status ════════════
                            Info {
                                key: "Installed"
                                value: info.datas?.installed ? "Yes" : "Nope"
                            }
                            Info {
                                key: "Install reason"
                                value: info.datas?.install_reason ?? ""
                            }
                            Info {
                                key: "Install date"
                                value: info.datas?.install_date ?? ""
                            }
                            Info {
                                key: "Last sync"
                                value: {
                                    const ls = info.datas?.last_sync
                                    if (!ls) return ""
                                    return ls.action + " on " + ls.timestamp
                                }
                            }
                            Info {
                                key: "Build date"
                                value: info.datas?.build_date ?? ""
                            }

                            CellSeparator {
                                w: info.contentW
                                visible: info.index != -1 && info.hasStatus && info.hasRelations
                                color: Colors.bgOverlay
                            }

                            // ════════════ Section 5: Relations ════════════
                            // Reverse deps first — they answer "what breaks if I remove this?"
                            Deps {
                                visible: (info.datas?.required_by ?? []).length > 0
                                key: "Required by"
                                collapseThreshold: 3    // tighter — this field gets huge for base libs
                                values: (info.datas?.required_by ?? []).map(
                                    n => ({ name: n, installed: PacmanInfo.isInstalled(n) })
                                )
                            }
                            Deps {
                                visible: (info.datas?.optional_for ?? []).length > 0
                                key: "Optional for"
                                values: (info.datas?.optional_for ?? []).map(
                                    n => ({ name: n, installed: PacmanInfo.isInstalled(n) })
                                )
                            }
                            // Forward deps — "what does this need?"
                            Deps {
                                visible: (info.datas?.depends ?? []).length > 0
                                key: "Dependencies"
                            }
                            Deps {
                                visible: (info.datas?.optional_deps ?? []).length > 0
                                key: "Optional depends"
                                values: info.datas?.optional_deps
                            }
                            Deps {
                                visible: (info.datas?.make_deps ?? []).length > 0
                                key: "Make depends"
                                values: info.datas?.make_deps
                            }
                            Deps {
                                visible: (info.datas?.check_deps ?? []).length > 0
                                key: "Check depends"
                                values: info.datas?.check_deps
                            }

                        }

                    }
                }

                // Prepare for pre-flight
                Cells {

                    visible: (
                        root.pacmanState == "prepare"
                    )

                    w: box.contentW
                    h: box.contentH - list.h - 9

                    color: "transparent"

                    RowLayout {

                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                        y: Cell.centerHCell(implicitHeight, parent.implicitHeight)

                        spacing: 0

                        CellText {
                            text: "Computing transaction"
                        }

                        CellLoading {
                            style: 2
                        }

                    }

                }

                // Checking for updates
                Cells {

                    visible: (
                        root.pacmanState == "checking_updates"
                    )

                    w: box.contentW
                    h: box.contentH - list.h - 9

                    color: "transparent"

                    RowLayout {

                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                        y: Cell.centerHCell(implicitHeight, parent.implicitHeight)

                        spacing: 0

                        CellText {
                            text: "Checking for updates"
                        }

                        CellLoading {
                            style: 2
                        }

                    }

                }

                // Pre-flight
                ColumnLayout {

                    visible: (
                        root.pacmanState == "pre-flight"
                        || root.pacmanState == "authentication"
                    )

                    spacing: 0

                    CellScrollView {

                        w: box.contentW
                        h: box.contentH - list.h - 12

                        source: ColumnLayout {

                            id: preflight

                            spacing: 0

                            property var installPlan: PacmanInfo.installPlan
                            property var installTarget: preflight.installPlan.toInstall.filter(item => item.isTarget)

                            CellText {
                                Layout.leftMargin: Cell.w(1)
                                text: "To Install:"
                                font: Cell.fontB
                                color: Colors.info
                            }

                            component ToInstall: RowLayout {

                                property string name
                                property color  name_color: Colors.fgBase
                                property string version
                                property string downloadSize
                                property string installedSize

                                property string prefix: "+"

                                property int maxW: box.contentW

                                spacing: Cell.w(1)

                                CellText {

                                    text: parent.prefix
                                    color: Colors.fgSubtle

                                }

                                CellText {

                                    text: parent.name
                                    preferedW: parent.maxW - 32 - parent.version.length
                                    color: parent.name_color

                                }

                                CellText {

                                    text: parent.version
                                    color: Colors.fgSubtle

                                }

                                CellText {

                                    text: parent.downloadSize
                                    color: Colors.info
                                    preferedW: 11
                                    alignRight: true

                                }

                                CellText {

                                    text: "->"
                                    color: Colors.fgSubtle

                                }

                                CellText {

                                    text: parent.installedSize
                                    color: Colors.success
                                    preferedW: 11
                                    alignRight: true

                                }

                            }

                            Repeater {

                                model: parent.installTarget

                                delegate: ToInstall {

                                    required property var modelData

                                    Layout.leftMargin: Cell.w(2)

                                    maxW: box.contentW - 2
                                    prefix: "*"

                                    name: modelData?.name ?? ""
                                    version: modelData?.version ?? ""
                                    downloadSize: modelData?.downloadSize ?? ""
                                    installedSize: modelData?.installedSize ?? ""

                                }
                            }

                            ColumnLayout {

                                id: preflight_dep

                                spacing: 0

                                property int collapseThreshold: 3

                                property int maxShown: collapseThreshold 
                                property int maxItems: preflight.installPlan.toInstall.length
                                property var shownItems: preflight.installPlan.toInstall.filter(item => !item.isTarget).slice(0, maxShown)

                                Repeater {

                                    model: parent.shownItems

                                    delegate: ToInstall {

                                        Layout.leftMargin: Cell.w(4)

                                        maxW: box.contentW - 4

                                        required property var modelData

                                        name: modelData.name
                                        name_color: Colors.blend(Colors.fgSubtle,Colors.fgBase,0.5)
                                        version: modelData.version
                                        downloadSize: modelData.downloadSize
                                        installedSize: modelData.installedSize

                                    }

                                }

                                RowLayout {

                                    Layout.leftMargin: Cell.w(4)

                                    spacing: Cell.w(1)

                                    CellButton {

                                        visible: preflight_dep.maxShown < preflight_dep.maxItems

                                        padding: 0
                                        text: "[+ " + (preflight_dep.maxItems - preflight_dep.maxShown) + " more]"
                                        color: ["transparent", Colors.bgOverlay, Colors.bgOverlay]
                                        fg: Colors.info

                                        onReleased: (button) => {
                                            if (button == "L") {
                                                preflight_dep.maxShown = Math.min(preflight_dep.maxShown+5,preflight_dep.maxItems)
                                            }
                                        }

                                    }

                                    CellButton {

                                        visible: preflight_dep.maxShown < preflight_dep.maxItems && preflight_dep.maxShown > preflight_dep.collapseThreshold

                                        padding: 0
                                        text: "[Show all ("+preflight_dep.maxItems+")]"
                                        color: ["transparent", Colors.bgOverlay, Colors.bgOverlay]
                                        fg: Colors.info

                                        onReleased: (button) => {
                                            if (button == "L") {
                                                preflight_dep.maxShown = preflight_dep.maxItems
                                            }
                                        }

                                    }

                                    CellButton {

                                        visible: preflight_dep.maxShown == preflight_dep.maxItems

                                        padding: 0
                                        text: "[Show less]"
                                        color: ["transparent", Colors.bgOverlay, Colors.bgOverlay]
                                        fg: Colors.info

                                        onReleased: (button) => {
                                            if (button == "L") {
                                                preflight_dep.maxShown = preflight_dep.collapseThreshold
                                            }
                                        }

                                    }

                                }


                            }

                            CellSeparator {
                                visible: preflight.installPlan.willReplace.length > 0
                                w: box.contentW - 1
                                color: Colors.bgOverlay
                            }

                            CellText {
                                visible: preflight.installPlan.willReplace.filter(item => !item.installed).length > 0
                                Layout.leftMargin: Cell.w(1)
                                text: "Replaces:"
                                font: Cell.fontB
                                color: Colors.blend(Colors.warning,Colors.fgBase, 0.5)
                            }

                            ColumnLayout {

                                visible: datas.length > 0

                                spacing: 0

                                property var datas: preflight.installPlan.willReplace.filter(item => !item.installed)

                                Repeater {

                                    model: parent.datas

                                    delegate: ToInstall {

                                        Layout.leftMargin: Cell.w(2)

                                        required property var modelData

                                        maxW: box.contentW - 2

                                        prefix: "-"

                                        name: modelData.name
                                        version: modelData.version
                                        downloadSize: "-"
                                        installedSize: "-"

                                    }

                                }

                            }

                            CellSeparator {
                                visible: preflight.installPlan.conflictsWith.length > 0
                                w: box.contentW - 1
                                color: Colors.bgOverlay
                            }

                            CellText {
                                visible: preflight.installPlan.conflictsWith.length > 0
                                Layout.leftMargin: Cell.w(1)
                                text: "Conflicts with:"
                                font: Cell.fontB
                                color: Colors.danger
                            }

                            ColumnLayout {

                                visible: preflight.installPlan.conflictsWith.length > 0

                                spacing: 0

                                Repeater {

                                    model: preflight.installPlan.conflictsWith

                                    delegate: ToInstall {

                                        Layout.leftMargin: Cell.w(2)

                                        required property var modelData

                                        maxW: box.contentW - 2

                                        prefix: "-"

                                        name: modelData.name
                                        name_color: Colors.danger
                                        version: modelData.version
                                        downloadSize: "-"
                                        installedSize: "-"

                                    }

                                }

                            }

                        }

                    }

                    CellSeparator {
                        w: box.contentW
                        color: Colors.accentDim
                    }

                    RowLayout {

                        Layout.leftMargin: Cell.w(1)

                        spacing: 0

                        CellText {
                            text: "Total download size     : "
                            color: Colors.fgSubtle
                        }

                        CellText {
                            text: PacmanInfo.installPlan.totalDownload
                            color: Colors.info
                            font: Cell.fontB
                            alignRight: true
                        }

                    }

                    RowLayout {

                        Layout.leftMargin: Cell.w(1)

                        spacing: 0

                        CellText {
                            text: "Total installation size : "
                            color: Colors.fgSubtle
                        }

                        CellText {
                            text: PacmanInfo.installPlan.totalInstalled
                            color: Colors.success
                            font: Cell.fontB
                            alignRight: true
                        }

                    }


                }

                // Installation screen
                ColumnLayout {

                    visible: (
                        root.pacmanState == "installing"
                        || root.pacmanState == "success"
                        || root.pacmanState == "failed"
                    )

                    spacing: 0

                    CellScrollView {

                        Layout.leftMargin: Cell.w(1)

                        id: install_log

                        w: box.contentW - 1
                        h: box.contentH - 4 - (install_footer.h)

                        snapToMax: true

                        source: CellText {

                            id: install_log_text

                            preferedW: install_log.contentW - 2

                            text: ""
                            wrap: true

                            Timer {
                                id: install_log_delay
                                interval: SettingsInfo.frameTime
                                onTriggered: {
                                    install_log_text.text = PacmanInfo.installLog.replace(/^\n/,"").replace(/\n$/,"")
                                }
                            }

                            Connections {
                                target: PacmanInfo
                                function onInstallLogChanged() {
                                    if (install_log_delay.running) return
                                    // console.log(PacmanInfo.installLog.replace(/^\n/,"").replace(/\n$/,""))
                                    install_log_delay.restart()
                                }
                            }

                        }

                    }

                    Cells {

                        id: install_footer

                        w: box.contentW
                        h: Cell.hCount(install_footer_content.implicitHeight)

                        color: Colors.bgSurface

                        ColumnLayout {

                            id: install_footer_content

                            spacing: 0

                            CellSeparator {
                                w: box.contentW
                                color: Colors.accentDim
                            }

                            RowLayout {

                                visible: root.pacmanState == "installing"

                                Layout.leftMargin: Cell.centerWCell(implicitWidth,install_footer.implicitWidth)

                                spacing: 0

                                CellText {

                                    text: " Installing <b>" + PacmanInfo.installTarget + "</b>"
                                    color: Colors.info

                                }

                                CellLoading {
                                    style: 2
                                }

                            }

                            CellText {

                                visible: root.pacmanState == "success"

                                text: " Installation completed successfully!"
                                color: Colors.success
                                font: Cell.fontB

                                preferedW: box.contentW
                                centered: true

                            }


                        }

                    }

                }

                // Separator for footer
                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                }

                // Footer
                Cells {

                    w: box.contentW
                    h: 1

                    color: "transparent"

                    // Check updates and fetching
                    RowLayout {

                        visible: (
                            root.pacmanState == "idle"
                            || root.pacmanState == "prepare"
                            || root.pacmanState == "fetching"
                            || root.pacmanState == "checking_updates"
                        )

                        x: Cell.w(1)

                        spacing: Cell.w(1)

                        CellButton {

                            text: "Check Updates"

                            clickable: !PacmanInfo.fetching && !PacmanInfo.checking_updates

                            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                            fg:    clickable ? [Colors.onAccent,     Colors.fgBase]    : Colors.fgSubtle

                            onReleased: (button) => {
                                if (button == "L") {
                                    PacmanInfo.check_updates()
                                }
                            }

                        }

                        CellButton {

                            text: "Refresh"

                            clickable: !PacmanInfo.fetching && !PacmanInfo.checking_updates

                            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                            fg:    clickable ? [Colors.onAccent,     Colors.fgBase]    : Colors.fgSubtle

                            onReleased: (button) => {
                                if (button == "L") {
                                    PacmanInfo.fetch()
                                }
                            }

                        }

                    }

                    // Install
                    RowLayout {

                        anchors.right: parent.right
                        anchors.rightMargin: Cell.w(1)

                        spacing: Cell.w(1)

                        CellButton {

                            visible: (
                                root.pacmanState == "idle"
                                || root.pacmanState == "prepare"
                                || root.pacmanState == "fetching"
                                || root.pacmanState == "checking_updates"
                            ) && !PacmanInfo.isInstalled(list.selected_pkg)

                            property bool in_queue: list.multi_selected_pkg.some(item => item == list.selected_pkg)

                            text: in_queue ? "Remove from queue" : "Add to queue"

                            clickable: list.selected_pkg != ""

                            color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                            fg:    clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                            onReleased: (button) => {
                                if (button == "L") {
                                    if (in_queue) {
                                        list.multi_selected_pkg.splice(list.multi_selected_pkg.findIndex(item=>item == list.selected_pkg),1)
                                        list.multi_selected_pkgChanged()
                                    } else {
                                        list.multi_selected_pkg.push(list.selected_pkg) 
                                        list.multi_selected_pkgChanged()
                                    }
                                }
                            }

                        }

                        CellButton {

                            visible: (
                                root.pacmanState == "idle"
                                || root.pacmanState == "prepare"
                                || root.pacmanState == "fetching"
                                || root.pacmanState == "checking_updates"
                            ) && !PacmanInfo.isInstalled(list.selected_pkg)

                            text: list.multi_selected_pkg.length > 0 ? "Install all" : "Install"

                            clickable: list.selected_pkg != ""

                            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                            fg:    clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                            onReleased: (button) => {
                                if (button == "L") {
                                    if (list.multi_selected_pkg.length > 0) {
                                        PacmanInfo.requestInstallation(list.multi_selected_pkg)
                                    } else {
                                        PacmanInfo.requestInstallation(info.deps.length > 0 ? [info.deps[info.deps.length-1]] : [list.selected_pkg])
                                    }
                                }
                            }

                        }
                    }

                    // Success
                    CellButton {

                        visible: root.pacmanState == "success"

                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                        text: "Return"

                        color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                        fg:    clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                        onReleased: (button) => {
                            if (button == "L") {
                                PacmanInfo.cancelInstallation()
                            }
                        }

                    }

                    // Cancel mid installation
                    CellButton {

                        visible: root.pacmanState == "installing"

                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                        text: "Cancel"

                        color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                        fg:    clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                        onReleased: (button) => {
                            if (button == "L") {
                                PacmanInfo.cancelInstallation()
                            }
                        }

                    }

                    // Installation confirmation
                    RowLayout {

                        visible: (
                            root.pacmanState == "pre-flight"
                        )

                        anchors.right: parent.right
                        anchors.rightMargin: Cell.w(1)

                        spacing: Cell.w(1)

                        CellButton {

                            text: "Confirm"

                            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                            fg:    clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                            onReleased: (button) => {
                                if (button == "L") {
                                    PacmanInfo.confirmInstallation()
                                }
                            }

                        }

                        CellButton {

                            text: "Cancel"

                            color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                            fg:    clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                            onReleased: (button) => {
                                if (button == "L") {
                                    PacmanInfo.cancelInstallation()
                                }
                            }

                        }

                    }

                }

            }

        }

    }

}
