pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {
    id: root

    w: 100
    h: 44

    property string pacmanState: PacmanInfo.pacmanState

    property int selected_index: 0
    property string selected_pkg: ""
    property var multi_selected_pkg: []

    Connections {
        target: PacmanInfo
        function onSearch_modeChanged() {
            search_field.textChanged();
        }
        function onFetched() {
            info.index = PacmanInfo.getPackageIndex(root.selected_pkg);
            search_field.textChanged();
        }
    }

    onSelected_pkgChanged: {
        info.index = PacmanInfo.getPackageIndex(root.selected_pkg);
    }

    onPacmanStateChanged: {
        if (pacmanState == "success") {
            multi_selected_pkg = [];
            selected_pkg = "";
            search_field.set("");
            PacmanInfo.search("");
        }
    }

    /*
     onVisibleChanged: {
         selected_index = 0
         multi_selected_pkg = []
         selected_pkg = ""
         PacmanInfo.query = ""
         list.reset()
     }
     */

    onPromoted: {
        search_field.grabFocus();
    }

    escapeToClose: false

    shortcuts: [
        {
            binds: ["Up", "Backtab"],
            action: () => {
                if (PacmanInfo.fetching)
                    return;
                let index = PacmanInfo.search_results.findIndex(item => item.name == root.selected_pkg);
                if (index == -1 || index < list.offset || index > list.offset + list.h) {
                    root.selected_pkg = "";
                }
                if (root.selected_pkg == "") {
                    root.selected_pkg = list.datas[list.offset].name;
                    return;
                }
                if (root.selected_index - 1 < 0) {
                    list.offset -= list.h;
                }
                root.selected_pkg = list.datas[list.offset + (root.selected_index + list.h - 1) % list.h].name;
            }
        },
        {
            binds: ["Down", "Tab"],
            action: () => {
                if (PacmanInfo.fetching)
                    return;
                let index = PacmanInfo.search_results.findIndex(item => item.name == root.selected_pkg);
                if (index == -1 || index < list.offset || index > list.offset + list.h) {
                    root.selected_pkg = "";
                }
                if (root.selected_pkg == "") {
                    root.selected_pkg = list.datas[list.offset].name;
                    return;
                }
                if (root.selected_index + 1 >= list.h) {
                    list.offset += list.h;
                }
                root.selected_pkg = list.datas[list.offset + (root.selected_index + list.h + 1) % list.h].name;
            }
        },
        {
            binds: "Escape",
            action: () => {
                if (root.pacmanState == "success" || root.pacmanState == "failed" || root.pacmanState == "pre-flight") {
                    PacmanInfo.cancel();
                } else {
                    root.close();
                }
            }
        },
        {
            binds: "Ctrl+S",
            action: () => {
                PacmanInfo.search_mode = (PacmanInfo.search_mode + 1) % PacmanInfo.search_modes.length;
            }
        },
        {
            binds: "Ctrl+R",
            action: () => {
                if (root.pacmanState == "idle") {
                    PacmanInfo.fetch();
                }
            }
        },
        {
            binds: "Ctrl+C",
            action: () => {
                if (root.pacmanState == "running") {
                    PacmanInfo.cancel();
                }
            }
        },
        {
            binds: "Return",
            action: () => {
                if (PacmanInfo.fetching)
                    return;
                if (selected_pkg == "" && multi_selected_pkg.length == 0)
                    return;
                if (root.pacmanState == "idle") {
                    if (root.multi_selected_pkg.length > 0) {
                        PacmanInfo.requestInstallation(root.multi_selected_pkg);
                    } else if (PacmanInfo.isInstalled(root.selected_pkg)) {
                        PacmanInfo.requestRemoval([root.selected_pkg]);
                    } else {
                        PacmanInfo.requestInstallation(info.deps.length > 0 ? [info.deps[info.deps.length - 1]] : [root.selected_pkg]);
                    }
                } else if (root.pacmanState == "pre-flight") {
                    if (PacmanInfo.pacmanMode == "install" && confirm_install.countdown == 0)
                        PacmanInfo.confirmInstallation();
                    else if (PacmanInfo.pacmanMode == "remove" && confirm_remove.countdown == 0)
                        PacmanInfo.confirmRemoval();
                }
            }
        },
    ]

    // ════════════════════════════════════════════════════════════════
    // INLINE COMPONENTS (shared across install & remove pre-flight)
    // ════════════════════════════════════════════════════════════════

    // ── CollapseFooter ──────────────────────────────────────────────
    //
    // Owns the maxShown state for any list that uses the
    // "+N more / Show all / Show less" progressive-disclosure pattern.
    // The parent binds its Repeater's model to footer.maxShown and
    // sets maxItems / collapseThreshold / expandStep.  When the
    // underlying list changes (maxItems changes), maxShown resets
    // to collapseThreshold automatically.
    //
    // Used by: Deps (info panel), preflight_dep (install),
    //          remove_preflight_dep (remove), req (broken dependents).

    component CollapseFooter: RowLayout {
        id: footer

        property int maxItems
        property int collapseThreshold
        property int expandStep: 5

        property int maxShown: collapseThreshold

        onMaxItemsChanged: maxShown = collapseThreshold

        spacing: Cell.w(1)

        visible: maxItems > collapseThreshold

        CellButton {

            visible: footer.maxShown < footer.maxItems

            padding: 0
            text: "[+ " + (footer.maxItems - footer.maxShown) + " more]"
            color: ["transparent", Colors.bgOverlay, Colors.bgOverlay]
            fg: Colors.info

            onReleased: button => {
                if (button == "L") {
                    footer.maxShown = Math.min(footer.maxShown + footer.expandStep, footer.maxItems);
                }
            }
        }

        CellButton {

            visible: footer.maxShown < footer.maxItems && footer.maxShown > footer.collapseThreshold

            padding: 0
            text: "[Show all (" + footer.maxItems + ")]"
            color: ["transparent", Colors.bgOverlay, Colors.bgOverlay]
            fg: Colors.info

            onReleased: button => {
                if (button == "L") {
                    footer.maxShown = footer.maxItems;
                }
            }
        }

        CellButton {

            visible: footer.maxShown >= footer.maxItems && footer.maxItems > footer.collapseThreshold

            padding: 0
            text: "[Show less]"
            color: ["transparent", Colors.bgOverlay, Colors.bgOverlay]
            fg: Colors.info

            onReleased: button => {
                if (button == "L") {
                    footer.maxShown = footer.collapseThreshold;
                }
            }
        }
    }

    // ── TransactionRow ──────────────────────────────────────────────
    //
    // Unified row for both install and remove pre-flight lists.
    // mode: "install"  →  prefix | name | version | downloadSize -> installedSize
    // mode: "remove"   →  prefix | name | version | +freedSize
    //
    // Prefix color coding is shared:
    //   !  → danger   (conflict)
    //   =  → warning  (replacement)
    //   *  → fgSubtle (explicit target)
    //   +  → fgSubtle (install dep)
    //   -  → fgSubtle (remove dep)

    component TransactionRow: RowLayout {
        id: row

        property string mode: "install"
        property string name
        property color name_color: Colors.fgBase
        property string version
        property string downloadSize
        property string installedSize
        property string freedSize
        property string prefix: mode == "install" ? "+" : "-"

        property int maxW: box.contentW

        readonly property int _sizeCols: mode == "install" ? 32 : 18

        spacing: Cell.w(1)

        CellText {

            text: row.prefix
            color: {
                if (text == "!")
                    return Colors.danger;
                if (text == "=")
                    return Colors.warning;
                return Colors.fgSubtle;
            }
        }

        CellText {

            text: row.name
            preferedW: row.maxW - row._sizeCols - row.version.length
            color: row.name_color
        }

        CellText {

            text: row.version
            color: Colors.fgSubtle
        }

        // ── Install-only columns: download -> installed ──

        CellText {

            visible: row.mode == "install"

            text: row.downloadSize
            color: Colors.info
            preferedW: 11
            alignRight: true
        }

        CellText {

            visible: row.mode == "install"

            text: "->"
            color: Colors.fgSubtle
        }

        CellText {

            visible: row.mode == "install"

            text: row.installedSize
            color: Colors.success
            preferedW: 11
            alignRight: true
        }

        // ── Remove-only column: +freedSize ──

        CellText {

            visible: row.mode == "remove"

            text: "+" + row.freedSize.toString().padStart(11, " ")
            color: Colors.success
            preferedW: 12
            alignRight: true
        }
    }

    // ── CountdownConfirm ────────────────────────────────────────────
    //
    // A two-button row (confirm + cancel) with an optional 3-second
    // countdown gating the confirm button.  Used by both the install
    // and remove pre-flight confirmation footers.
    //
    // requiresCountdown: when true (and the row becomes visible), a
    //   3-second countdown starts.  The confirm button is disabled
    //   until it reaches 0.
    //
    // countdownLabel: shown while countdown > 0.  Use %1 as a
    //   placeholder for the seconds remaining, e.g. "Continue anyway (%1)".
    // standbyLabel: shown when countdown finished but requiresCountdown
    //   is still true (i.e. the dangerous condition still applies).
    // confirmLabel: shown when requiresCountdown is false (safe to
    //   proceed immediately).
    //
    // confirmed(): emitted when the confirm button is activated.

    component CountdownConfirm: RowLayout {
        id: confirm

        property bool requiresCountdown: false

        property string countdownLabel: "Continue anyway (%1)"
        property string standbyLabel: "Continue anyway"
        property string confirmLabel: "Confirm"

        signal confirmed

        anchors.right: parent.right
        anchors.rightMargin: Cell.w(1)

        spacing: Cell.w(1)

        property int countdown: 0

        onVisibleChanged: {
            if (visible && requiresCountdown) {
                countdown = 3;
            }
        }

        Timer {
            running: confirm.countdown > 0
            interval: 1000
            repeat: true
            onTriggered: confirm.countdown -= 1
        }

        CellButton {

            text: {
                if (confirm.countdown > 0)
                    return confirm.countdownLabel.arg(confirm.countdown);
                return confirm.requiresCountdown ? confirm.standbyLabel : confirm.confirmLabel;
            }

            clickable: confirm.countdown == 0

            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
            fg: clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

            onReleased: button => {
                if (button == "L")
                    confirm.confirmed();
            }
        }

        CellButton {

            text: "Cancel"

            color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
            fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

            onReleased: button => {
                if (button == "L")
                    PacmanInfo.cancel();
            }
        }
    }

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
                        text: "PACMAN"
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
                    id: list

                    visible: (root.pacmanState == "idle" || root.pacmanState == "prepare" || root.pacmanState == "pre-flight" || root.pacmanState == "authentication" || root.pacmanState == "checking_updates" || root.pacmanState == "fetching")

                    w: box.contentW
                    h: 14

                    // ── Unified data source ──────────────────────────────
                    //
                    // PacmanInfo.search_results already has all filters
                    // (query + installed + outdated) applied in a single
                    // pass.  No secondary .filter() here.

                    property var datas: PacmanInfo.search_results

                    virtualH: true

                    contentH: Cell.h(1) * datas.length

                    source: ColumnLayout {

                        spacing: 0

                        Repeater {

                            model: list.h

                            delegate: Loader {
                                id: pkg_loader

                                required property int index

                                active: list.datas[list.offset + index] ?? false

                                sourceComponent: Cells {
                                    id: pkg

                                    property int index: pkg_loader.index
                                    property var modelData: list.datas[list.offset + index]

                                    property string name: modelData.name
                                    property string repo: modelData.repository
                                    property string version: modelData.version
                                    property string latest_version: modelData.latest_version
                                    property bool installed: modelData.installed
                                    property bool update_available: pkg.latest_version != ""

                                    property bool selected: root.selected_pkg == name && !disabled

                                    property bool disabled: PacmanInfo.fetching || PacmanInfo.checking_updates

                                    w: list.contentW
                                    h: 1

                                    color: (selected ? Colors.accentStrong : (pkg_mouse.hovered ? Colors.bgOverlay : "transparent"))

                                    onSelectedChanged: {
                                        if (selected) {
                                            root.selected_index = index;
                                            if (PacmanInfo.search_mode == 4) {
                                                let inputs = search_field.text.split(" ");
                                                inputs[inputs.length - 1] = pkg.name;
                                                search_field.set(inputs.join(" "));
                                            }
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
                                                color: pkg.disabled ? Colors.fgSubtle : (pkg.selected ? Colors.onAccent : (pkg.update_available ? Colors.blend(Colors.fgSubtle, Colors.danger, 0.5) : Colors.fgSubtle))
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

                                        onReleased: button => {
                                            if (button == "L") {
                                                if (root.selected_pkg == pkg.name) {
                                                    root.selected_pkg = "";
                                                    return;
                                                }
                                                root.selected_pkg = pkg.name;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Search bar
                Cells {

                    visible: (root.pacmanState == "idle" || root.pacmanState == "prepare" || root.pacmanState == "pre-flight" || root.pacmanState == "authentication" || root.pacmanState == "fetching" || root.pacmanState == "checking_updates")

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

                                w: box.contentW - 30 - search_mode.text.length - 3 * PacmanInfo.fetching
                                h: 1

                                placeholder: "Search package"

                                escapeToUnFocus: false
                                unfocusOnEntered: false

                                disabled: (root.pacmanState == "prepare" || root.pacmanState == "pre-flight" || root.pacmanState == "running" || root.pacmanState == "authentication" || root.pacmanState == "success")

                                onTextChanged: {
                                    if (PacmanInfo.search_mode == 4) {
                                        list.reset();
                                        let inputs = text.split(" ");
                                        root.multi_selected_pkg = [];
                                        for (const pkg of inputs) {
                                            // O(1) lookup via nameIndex + installedSet
                                            if (PacmanInfo.isInstalled(pkg))
                                                continue;
                                            if (PacmanInfo.getPackageIndex(pkg) !== -1) {
                                                root.multi_selected_pkg.push(pkg);
                                                root.multi_selected_pkgChanged();
                                            }
                                        }
                                    }
                                }

                                onTextInput: input => {
                                    if (PacmanInfo.search_mode == 4) {
                                        root.selected_pkg = "";
                                        let inputs = input.split(" ");
                                        let new_input = inputs[inputs.length - 1];
                                        PacmanInfo.search(new_input);
                                    } else {
                                        PacmanInfo.search(input);
                                    }
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
                                fg: Colors.fgBase

                                onReleased: button => {
                                    if (button == "L") {
                                        PacmanInfo.search_mode = (PacmanInfo.search_mode + 1) % PacmanInfo.search_modes.length;
                                    }
                                }
                            }

                            CellButton {

                                text: "Installed"

                                color: PacmanInfo.installed ? Colors.accentStrong : Colors.bgOverlay
                                fg: PacmanInfo.installed ? Colors.onAccent : Colors.fgBase

                                onReleased: button => {
                                    if (button == "L") {
                                        PacmanInfo.installed = !PacmanInfo.installed;
                                    }
                                }
                            }

                            CellButton {

                                text: "Outdated"

                                color: PacmanInfo.outdated ? Colors.accentStrong : Colors.bgOverlay
                                fg: PacmanInfo.outdated ? Colors.onAccent : Colors.fgBase

                                onReleased: button => {
                                    if (button == "L") {
                                        PacmanInfo.outdated = !PacmanInfo.outdated;
                                    }
                                }
                            }
                        }
                    }
                }

                // Breadcrumbs
                RowLayout {

                    visible: (root.pacmanState == "idle" || root.pacmanState == "fetching")

                    Layout.leftMargin: {
                        let result = root.selected_pkg.length + 2;
                        for (const dep of info.deps) {
                            result += dep.length + 2 * PacmanInfo.isInstalled(dep) + 4;
                        }
                        return Cell.w(1 - Math.max(result - info.contentW - 1, 0));
                    }

                    spacing: Cell.w(1)

                    CellText {
                        text: "* " + root.selected_pkg
                        color: info.deps.length > 0 ? Colors.fgSubtle : Colors.fgBase
                        font: Cell.fontB

                        MouseControl {

                            anchors.fill: parent

                            onReleased: button => {
                                if (button == "L") {
                                    info.deps = [];
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

                                        onReleased: button => {
                                            if (button == "L") {
                                                info.deps = info.deps.slice(0, dep_crumb.index + 1);
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
                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    visible: (root.pacmanState == "prepare" || root.pacmanState == "pre-flight" || root.pacmanState == "authentication")
                    text: (PacmanInfo.pacmanMode == "install" ? "Installing" : (PacmanInfo.forceRemove ? "Force removing" : "Removing")) + " <b>" + (PacmanInfo.pacmanMode == "install" ? PacmanInfo.installTarget.join(", ") : PacmanInfo.removeTarget.join(", ")) + "</b>"
                    color: PacmanInfo.forceRemove ? Colors.danger : Colors.secondary
                }

                // Check updates header
                CellText {
                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    visible: (root.pacmanState == "checking_updates")
                    text: "Synchronizing packages database"
                    color: Colors.secondary
                }

                // Separator for Breadcrumbs and Installing header
                CellSeparator {
                    visible: (root.pacmanState == "idle" || root.pacmanState == "prepare" || root.pacmanState == "pre-flight" || root.pacmanState == "authentication" || root.pacmanState == "fetching" || root.pacmanState == "checking_updates")
                    w: box.contentW
                    color: Colors.accentStrong
                }

                // Info
                RowLayout {

                    visible: (root.pacmanState == "idle" || root.pacmanState == "fetching")

                    spacing: 0

                    CellScrollView {
                        id: info

                        w: box.contentW - (root.multi_selected_pkg.length > 0 ? install_queue.w : 0)
                        h: box.contentH - list.h - 9

                        // ── O(1) lookups via nameIndex ──────────────────
                        property int dep_index: PacmanInfo.getPackageIndex(deps[deps.length - 1])
                        property int index: PacmanInfo.getPackageIndex(root.selected_pkg)

                        property var deps: []

                        onIndexChanged: {
                            deps = [];
                        }

                        onDepsChanged: {
                            if (deps[deps.length - 1] == root.selected_pkg) {
                                deps = [];
                                depsChanged();
                                return;
                            }
                            for (let i = 0; i < deps.length - 1; i++) {
                                if (deps[deps.length - 1] == deps[i]) {
                                    deps = deps.slice(0, i + 1);
                                    depsChanged();
                                    return;
                                }
                            }
                        }

                        property var datas: PacmanInfo.packages[deps.length > 0 ? dep_index : index]

                        property int magic: 22

                        // ── Section visibility flags (for separator conditionals) ──
                        property bool hasIdentity: (datas?.description ?? "").length > 0 || (datas?.url ?? "").length > 0 || (datas?.version ?? "").length > 0 || (datas?.licenses ?? []).length > 0

                        property bool hasSource: (datas?.repository ?? "").length > 0 || (datas?.arch ?? "").length > 0 || (datas?.groups ?? []).length > 0

                        property bool hasFootprint: (datas?.download_size ?? "").length > 0 || (datas?.installed_size ?? "").length > 0 || (datas?.conflicts_with ?? []).length > 0 || (datas?.replaces ?? []).length > 0 || (datas?.provides ?? []).length > 0

                        // "Installed" is always rendered when index != -1, so hasStatus is always
                        // true alongside a real selection. Kept here for symmetry / future-proofing.
                        property bool hasStatus: index != -1

                        property bool hasRelations: (datas?.required_by ?? []).length > 0 || (datas?.optional_for ?? []).length > 0 || (datas?.depends ?? []).length > 0 || (datas?.optional_deps ?? []).length > 0 || (datas?.make_deps ?? []).length > 0 || (datas?.check_deps ?? []).length > 0

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
                                values: (info.datas?.conflicts_with ?? []).map(n => ({
                                            name: n,
                                            installed: PacmanInfo.isInstalled(n)
                                        }))
                            }
                            Deps {
                                visible: (info.datas?.replaces ?? []).length > 0
                                key: "Replaces"
                                values: (info.datas?.replaces ?? []).map(n => ({
                                            name: n,
                                            installed: PacmanInfo.isInstalled(n)
                                        }))
                            }
                            Deps {
                                visible: (info.datas?.provides ?? []).length > 0
                                key: "Provides"
                                values: (info.datas?.provides ?? []).map(n => ({
                                            name: n,
                                            installed: PacmanInfo.isInstalled(n)
                                        }))
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
                                    const ls = info.datas?.last_sync;
                                    if (!ls)
                                        return "";
                                    return ls.action + " on " + ls.timestamp;
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
                                values: (info.datas?.required_by ?? []).map(n => ({
                                            name: n,
                                            installed: PacmanInfo.isInstalled(n)
                                        }))
                            }
                            Deps {
                                visible: (info.datas?.optional_for ?? []).length > 0
                                key: "Optional for"
                                values: (info.datas?.optional_for ?? []).map(n => ({
                                            name: n,
                                            installed: PacmanInfo.isInstalled(n)
                                        }))
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

                    Cells {
                        id: install_queue

                        visible: root.multi_selected_pkg.length > 0

                        w: 41
                        h: box.contentH - list.h - 9

                        color: Colors.bgSurface

                        RowLayout {

                            y: -Cell.h(2)

                            spacing: 0

                            CellSeparator {
                                vertical: true
                                h: box.contentH - list.h - 7
                                color: Colors.accentStrong
                            }

                            ColumnLayout {

                                spacing: 0

                                CellText {
                                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                                    text: "Selected packages"
                                    color: Colors.info
                                }

                                CellSeparator {
                                    w: install_queue.w - 1
                                    color: Colors.accentStrong
                                }

                                CellScrollView {
                                    id: selected_pkg_list

                                    w: install_queue.w - 1
                                    h: box.contentH - list.h - 12

                                    source: ColumnLayout {

                                        spacing: 0

                                        Repeater {

                                            model: root.multi_selected_pkg

                                            delegate: Cells {
                                                id: selected_pkgs

                                                required property string modelData

                                                w: selected_pkg_list.contentW
                                                h: 1

                                                color: selected_pkgs_mouse.hovered ? Colors.bgOverlay : "transparent"

                                                RowLayout {

                                                    x: Cell.w(1)

                                                    spacing: Cell.w(1)

                                                    CellText {

                                                        text: selected_pkgs.modelData
                                                        preferedW: selected_pkg_list.contentW - selected_pkgs_version.text.length - 3
                                                    }

                                                    CellText {
                                                        id: selected_pkgs_version

                                                        // O(1) lookup via getPackage()
                                                        text: {
                                                            let p = PacmanInfo.getPackage(selected_pkgs.modelData);
                                                            return p ? p.version : "";
                                                        }
                                                        color: Colors.fgSubtle
                                                    }
                                                }

                                                MouseControl {
                                                    id: selected_pkgs_mouse

                                                    anchors.fill: parent

                                                    onReleased: button => {
                                                        if (button == "L") {
                                                            root.selected_pkg = selected_pkgs.modelData;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                CellSeparator {
                                    w: install_queue.w - 1
                                    color: Colors.accentDim
                                }

                                RowLayout {
                                    spacing: 0
                                    CellText {
                                        text: " Estimated download size  : "
                                        preferedW: install_queue.w - 2 - estimate_download.text.length
                                        color: Colors.fgSubtle
                                    }
                                    CellText {
                                        id: estimate_download
                                        text: {
                                            let result = 0;
                                            for (const pkg of root.multi_selected_pkg) {
                                                // O(1) lookup via getPackage()
                                                let p = PacmanInfo.getPackage(pkg);
                                                if (p)
                                                    result += PacmanInfo.convertToBytes(p.download_size);
                                            }
                                            return PacmanInfo.formatBytes(result);
                                        }
                                        color: Colors.info
                                    }
                                }

                                RowLayout {
                                    spacing: 0
                                    CellText {
                                        text: " Estimated installed size : "
                                        preferedW: install_queue.w - 2 - estimate_installed.text.length
                                        color: Colors.fgSubtle
                                    }
                                    CellText {
                                        id: estimate_installed
                                        text: {
                                            let result = 0;
                                            for (const pkg of root.multi_selected_pkg) {
                                                // O(1) lookup via getPackage()
                                                let p = PacmanInfo.getPackage(pkg);
                                                if (p)
                                                    result += PacmanInfo.convertToBytes(p.installed_size);
                                            }
                                            return PacmanInfo.formatBytes(result);
                                        }
                                        color: Colors.success
                                    }
                                }
                            }
                        }
                    }
                }

                // Prepare for pre-flight
                Cells {

                    visible: (root.pacmanState == "prepare")

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

                    visible: (root.pacmanState == "checking_updates")

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

                    visible: (root.pacmanState == "pre-flight" || root.pacmanState == "authentication")

                    spacing: 0

                    // Installation pre-flight
                    CellScrollView {

                        visible: PacmanInfo.pacmanMode == "install"

                        w: box.contentW
                        h: box.contentH - list.h - 12

                        source: ColumnLayout {
                            id: preflight

                            spacing: 0

                            property var installPlan: PacmanInfo.installPlan
                            property var installTarget: preflight.installPlan.toInstall.filter(item => item.isTarget)

                            CellText {
                                visible: PacmanInfo.installPlan.error ?? false
                                Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(box.contentW - 1))
                                text: "\n" + PacmanInfo.installPlan.error ?? ""
                                preferedW: box.contentW - 5
                                centered: true
                                wrap: true
                                color: Colors.warning
                            }

                            CellText {
                                Layout.leftMargin: Cell.w(1)
                                visible: PacmanInfo.installPlan.toInstall.length > 0
                                text: "To Install:"
                                font: Cell.fontB
                                color: Colors.info
                            }

                            Repeater {

                                model: parent.installTarget

                                delegate: TransactionRow {
                                    mode: "install"

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

                                property var dep_pkgs: preflight.installPlan.toInstall.filter(item => !item.isTarget)

                                Repeater {

                                    model: preflight_dep.dep_pkgs.slice(0, preflight_dep_footer.maxShown)

                                    delegate: TransactionRow {

                                        mode: "install"

                                        Layout.leftMargin: Cell.w(4)

                                        maxW: box.contentW - 4

                                        required property var modelData

                                        name: modelData.name
                                        name_color: Colors.blend(Colors.fgSubtle, Colors.fgBase, 0.5)
                                        version: modelData.version
                                        downloadSize: modelData.downloadSize
                                        installedSize: modelData.installedSize
                                    }
                                }

                                CollapseFooter {
                                    id: preflight_dep_footer
                                    Layout.leftMargin: Cell.w(4)
                                    maxItems: preflight_dep.dep_pkgs.length
                                    collapseThreshold: 3
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
                                color: Colors.blend(Colors.warning, Colors.fgBase, 0.5)
                            }

                            ColumnLayout {

                                visible: datas.length > 0

                                spacing: 0

                                property var datas: preflight.installPlan.willReplace.filter(item => !item.installed)

                                Repeater {

                                    model: parent.datas

                                    delegate: TransactionRow {

                                        mode: "install"

                                        Layout.leftMargin: Cell.w(2)

                                        required property var modelData

                                        maxW: box.contentW - 2

                                        prefix: "="

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

                                    delegate: TransactionRow {

                                        mode: "install"

                                        Layout.leftMargin: Cell.w(2)

                                        required property var modelData

                                        maxW: box.contentW - 2

                                        prefix: "!"

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

                    // Removal pre-flight
                    CellScrollView {

                        visible: PacmanInfo.pacmanMode == "remove"

                        w: box.contentW
                        h: box.contentH - list.h - 11 - (PacmanInfo.forceRemove ? 3 : 0)

                        source: ColumnLayout {
                            id: remove_preflight

                            spacing: 0

                            property var removalPlan: PacmanInfo.removalPlan
                            property var removeTarget: removalPlan.toRemove.filter(item => item.isTarget)

                            CellText {
                                visible: PacmanInfo.removalPlan.error ?? false
                                Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(box.contentW - 1))
                                text: "\n" + PacmanInfo.removalPlan.error ?? ""
                                preferedW: box.contentW - 5
                                centered: true
                                wrap: true
                                color: Colors.warning
                            }

                            CellText {
                                Layout.leftMargin: Cell.w(1)
                                visible: PacmanInfo.removalPlan.toRemove.length > 0
                                text: "To Remove:"
                                font: Cell.fontB
                                color: Colors.info
                            }

                            Repeater {

                                model: parent.removeTarget

                                delegate: TransactionRow {
                                    mode: "remove"

                                    required property var modelData

                                    Layout.leftMargin: Cell.w(2)

                                    maxW: box.contentW - 2
                                    prefix: "*"

                                    name: modelData?.name ?? ""
                                    version: modelData?.version ?? ""
                                    freedSize: modelData?.freedSize ?? ""
                                }
                            }

                            ColumnLayout {
                                id: remove_preflight_dep

                                spacing: 0

                                property var dep_pkgs: remove_preflight.removalPlan.toRemove.filter(item => !item.isTarget)

                                Repeater {

                                    model: remove_preflight_dep.dep_pkgs.slice(0, remove_preflight_dep_footer.maxShown)

                                    delegate: TransactionRow {

                                        mode: "remove"

                                        Layout.leftMargin: Cell.w(4)

                                        maxW: box.contentW - 4

                                        required property var modelData

                                        name: modelData?.name
                                        name_color: Colors.blend(Colors.fgSubtle, Colors.fgBase, 0.5)
                                        version: modelData?.version
                                        freedSize: modelData?.freedSize
                                    }
                                }

                                CollapseFooter {
                                    id: remove_preflight_dep_footer
                                    Layout.leftMargin: Cell.w(4)
                                    maxItems: remove_preflight_dep.dep_pkgs.length
                                    collapseThreshold: 3
                                }
                            }

                            CellText {
                                visible: remove_preflight.removalPlan.brokenDependents.length > 0
                                Layout.leftMargin: Cell.w(1)
                                text: "Broken dependencies:"
                                font: Cell.fontB
                                color: Colors.danger
                            }

                            ColumnLayout {

                                visible: remove_preflight.removalPlan.brokenDependents.length > 0

                                spacing: 0

                                Repeater {

                                    model: remove_preflight.removalPlan.brokenDependents

                                    delegate: ColumnLayout {
                                        id: broken_deps

                                        required property string target
                                        required property var dependents

                                        Layout.leftMargin: Cell.w(1)

                                        spacing: 0

                                        RowLayout {

                                            spacing: 0

                                            CellText {

                                                text: "! "
                                                color: Colors.danger
                                                font: Cell.fontB
                                            }

                                            CellText {

                                                text: broken_deps.target
                                                color: Colors.fgBase
                                            }

                                            CellText {

                                                text: " is required by: "
                                                color: Colors.fgSubtle
                                            }
                                        }

                                        ColumnLayout {
                                            id: req

                                            spacing: 0

                                            property var dep_pkgs: broken_deps.dependents

                                            Repeater {

                                                model: req.dep_pkgs.slice(0, req_footer.maxShown)

                                                delegate: RowLayout {

                                                    Layout.leftMargin: Cell.w(3)

                                                    required property string modelData

                                                    spacing: 0

                                                    CellText {

                                                        text: "~ "
                                                        color: Colors.danger
                                                    }

                                                    CellText {

                                                        text: parent.modelData
                                                        color: Colors.danger
                                                    }
                                                }
                                            }

                                            CollapseFooter {
                                                id: req_footer
                                                Layout.leftMargin: Cell.w(3)
                                                maxItems: req.dep_pkgs.length
                                                collapseThreshold: 3
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    CellSeparator {
                        w: box.contentW
                        color: Colors.accentDim
                    }

                    CellText {
                        visible: PacmanInfo.forceRemove
                        text: "<i><b>Force removing</b> will remove this package along with any package that require it.\nPlease proceed with caution!</i>"
                        centered: true
                        color: Colors.danger
                        preferedW: box.contentW
                    }

                    CellSeparator {
                        visible: PacmanInfo.forceRemove
                        w: box.contentW
                        color: Colors.accentDim
                    }

                    RowLayout {

                        visible: PacmanInfo.pacmanMode == "remove"

                        Layout.leftMargin: Cell.w(1)

                        spacing: 0

                        CellText {
                            text: "Total freed size : "
                            color: Colors.fgSubtle
                        }

                        CellText {
                            text: PacmanInfo.removalPlan.freedTotal
                            color: Colors.success
                            font: Cell.fontB
                            alignRight: true
                        }
                    }

                    RowLayout {

                        visible: PacmanInfo.pacmanMode == "install"

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

                        visible: PacmanInfo.pacmanMode == "install"

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

                // Installation/Removing screen
                ColumnLayout {

                    visible: (root.pacmanState == "running" || root.pacmanState == "success" || root.pacmanState == "failed")

                    spacing: 0

                    // Log
                    CellScrollView {
                        id: log

                        Layout.leftMargin: Cell.w(1)

                        w: box.contentW - 1
                        h: box.contentH - 4 - (install_footer.h)

                        snapToMax: true

                        source: ColumnLayout {

                            spacing: 0

                            property var lines: PacmanInfo.log.replace(/^\n/g, "").replace(/\n$/g, "").split("\n")

                            CellText {
                                id: log_text

                                preferedW: log.contentW - 2

                                text: parent.lines.slice(0, parent.lines.length - 1).join("\n")
                                wrap: true
                                color: Colors.fgSubtle
                            }

                            CellText {
                                id: log_text_focus

                                preferedW: log.contentW - 2

                                text: parent.lines[parent.lines.length - 1]
                                wrap: true
                            }
                        }
                    }

                    // Installation/removal footer
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

                            ColumnLayout {

                                visible: root.pacmanState == "running"

                                spacing: 0

                                RowLayout {

                                    Layout.leftMargin: Cell.centerWCell(implicitWidth, install_footer.implicitWidth)

                                    spacing: 0

                                    CellText {

                                        text: {
                                            let header;
                                            if (PacmanInfo.pacmanMode == "install") {
                                                switch (PacmanInfo.installState?.currentPhase) {
                                                case "START":
                                                    header = "Initializing installation for";
                                                    break;
                                                case "DOWNLOAD":
                                                    header = "Retrieving packages for";
                                                    break;
                                                case "INSTALL":
                                                    header = "Processing package changes for";
                                                    break;
                                                case "HOOKS":
                                                    header = "Running post-transaction hooks for";
                                                    break;
                                                }
                                            } else {
                                                switch (PacmanInfo.removeState?.currentPhase) {
                                                case "START":
                                                    header = "Initializing removal for";
                                                    break;
                                                case "UNHOOKS":
                                                    header = "Running pre-transaction hooks for";
                                                    break;
                                                case "UNINSTALLING":
                                                    header = "Processing package changes for";
                                                    break;
                                                case "HOOKS":
                                                    header = "Running post-transaction hooks for";
                                                    break;
                                                }
                                            }
                                            return " " + header + " <b>" + (PacmanInfo.pacmanMode == "install" ? PacmanInfo.installTarget.join(", ") : PacmanInfo.removeTarget.join(", ")) + "</b>";
                                        }
                                        color: Colors.info
                                        preferedW: Math.min(purify(text).length, box.contentW - 4)
                                    }

                                    CellLoading {
                                        style: 2
                                    }
                                }

                                CellSeparator {
                                    visible: (PacmanInfo.installState.currentPhase != "HOOKS" && PacmanInfo.installState.currentPhase != "START" && PacmanInfo.pacmanMode == "install")
                                    w: box.contentW
                                    color: Colors.bgOverlay
                                }

                                ColumnLayout {

                                    Layout.leftMargin: Cell.w(1)

                                    visible: PacmanInfo.installState.currentPhase == "DOWNLOAD" && PacmanInfo.pacmanMode == "install"

                                    spacing: 0

                                    RowLayout {

                                        spacing: 0

                                        CellText {

                                            text: "Downloaded size : "
                                            color: Colors.fgSubtle
                                        }
                                        CellText {

                                            text: PacmanInfo.installState.progressData.downloadedSize ?? ""
                                        }
                                        CellText {

                                            text: "/" + PacmanInfo.installPlan.totalDownload
                                            color: Colors.fgDim
                                        }
                                    }

                                    RowLayout {

                                        spacing: 0

                                        CellText {

                                            text: "Download speed  : "
                                            color: Colors.fgSubtle
                                        }
                                        CellText {

                                            text: PacmanInfo.installState.progressData.downloadSpeed ?? ""
                                        }
                                    }

                                    RowLayout {

                                        spacing: 0

                                        CellText {

                                            text: "Time remaining  : "
                                            color: Colors.fgSubtle
                                        }
                                        CellText {

                                            text: PacmanInfo.installState.progressData.estimateTime ?? ""
                                        }
                                    }
                                }

                                ColumnLayout {

                                    Layout.leftMargin: Cell.w(1)

                                    visible: PacmanInfo.installState.currentPhase == "INSTALL" && PacmanInfo.pacmanMode == "install"

                                    spacing: 0

                                    RowLayout {

                                        spacing: 0

                                        CellText {

                                            text: "Processing package : "
                                            color: Colors.fgSubtle
                                        }
                                        CellText {

                                            text: PacmanInfo.installState.progressData.currentPkg ?? ""
                                        }
                                        CellText {

                                            text: "/" + PacmanInfo.installState.progressData.totalPkg
                                            color: Colors.fgDim
                                        }
                                    }
                                }

                                CellSeparator {
                                    w: box.contentW
                                    color: Colors.bgOverlay
                                }

                                RowLayout {

                                    Layout.leftMargin: Cell.w(1)

                                    spacing: 0

                                    CellText {
                                        text: "["
                                        color: Colors.fgDim
                                    }

                                    CellProgressSquare {
                                        w: box.contentW - 9
                                        h: 1
                                        percent: PacmanInfo.pacmanMode == "install" ? (PacmanInfo.installState?.overallProgress ?? 0) : (PacmanInfo.removeState?.overallProgress ?? 0)
                                        cellInterval: 5
                                        fg: Colors.accentStrong
                                    }

                                    CellText {
                                        text: "] "
                                        color: Colors.fgDim
                                    }

                                    CellText {
                                        property int percent: PacmanInfo.pacmanMode == "install" ? (PacmanInfo.installState?.overallProgress ?? 0) : (PacmanInfo.removeState?.overallProgress ?? 0)
                                        Behavior on percent {
                                            NumberAnimation {
                                                duration: 500
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                        text: percent.toString().padStart(3, " ") + "%"
                                    }
                                }
                            }

                            CellText {

                                visible: root.pacmanState == "success"

                                text: PacmanInfo.pacmanMode == "install" ? "Installation completed successfully!" : "Removal completed successfully!"
                                color: Colors.success
                                font: Cell.fontB

                                preferedW: box.contentW
                                centered: true
                            }

                            CellText {

                                visible: root.pacmanState == "failed"

                                text: PacmanInfo.pacmanMode == "install" ? "Installation has failed! (Exit code: " + PacmanInfo.logExitCode + ")" : "Removal has failed! (Exit code: " + PacmanInfo.logExitCode + ")"
                                color: Colors.danger
                                font: Cell.fontB

                                preferedW: box.contentW
                                centered: true
                            }
                        }
                    }
                }

                Cells {

                    visible: (root.pacmanState == "cancel")

                    w: box.contentW
                    h: box.contentH

                    color: "transparent"

                    RowLayout {

                        spacing: 0

                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                        y: Cell.centerHCell(implicitHeight, parent.implicitHeight)

                        CellText {

                            text: "Interrupting Pacman"
                        }

                        CellLoading {
                            style: 2
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

                        visible: (root.pacmanState == "idle" || root.pacmanState == "prepare" || root.pacmanState == "fetching" || root.pacmanState == "checking_updates")

                        x: Cell.w(1)

                        spacing: Cell.w(1)

                        CellButton {

                            text: "Check Updates"

                            clickable: !PacmanInfo.fetching && !PacmanInfo.checking_updates && root.pacmanState != "prepare"

                            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                            fg: clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                            onReleased: button => {
                                if (button == "L") {
                                    PacmanInfo.check_updates();
                                }
                            }
                        }

                        CellButton {

                            text: "Refresh"

                            clickable: !PacmanInfo.fetching && !PacmanInfo.checking_updates && root.pacmanState != "prepare"

                            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                            fg: clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                            onReleased: button => {
                                if (button == "L") {
                                    PacmanInfo.fetch();
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

                            visible: (root.pacmanState == "idle" || root.pacmanState == "prepare" || root.pacmanState == "fetching" || root.pacmanState == "checking_updates") && root.multi_selected_pkg.length > 0

                            text: "Clear queue"

                            clickable: root.pacmanState != "prepare"

                            color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                            fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                            onReleased: button => {
                                if (button == "L") {
                                    root.multi_selected_pkg = [];
                                }
                            }
                        }

                        CellButton {

                            visible: (root.pacmanState == "idle" || root.pacmanState == "prepare" || root.pacmanState == "fetching" || root.pacmanState == "checking_updates") && !PacmanInfo.isInstalled(root.selected_pkg) && root.selected_pkg != ""

                            property bool in_queue: root.multi_selected_pkg.some(item => item == root.selected_pkg)

                            text: in_queue ? "Remove from queue" : "Add to queue"

                            clickable: root.pacmanState != "prepare"

                            color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                            fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                            onReleased: button => {
                                if (button == "L") {
                                    if (in_queue) {
                                        root.multi_selected_pkg.splice(root.multi_selected_pkg.findIndex(item => item == root.selected_pkg), 1);
                                        root.multi_selected_pkgChanged();
                                    } else {
                                        root.multi_selected_pkg.push(root.selected_pkg);
                                        root.multi_selected_pkgChanged();
                                    }
                                }
                            }
                        }

                        CellButton {

                            visible: (root.pacmanState == "idle" || root.pacmanState == "prepare" || root.pacmanState == "fetching" || root.pacmanState == "checking_updates") && !PacmanInfo.isInstalled(root.selected_pkg)

                            text: (root.multi_selected_pkg.length > 0 ? "Install all" : "Install")

                            clickable: (root.selected_pkg != "" || root.multi_selected_pkg.length > 0) && root.pacmanState != "prepare"

                            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                            fg: clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                            onReleased: button => {
                                if (button == "L") {
                                    if (root.multi_selected_pkg.length > 0) {
                                        PacmanInfo.requestInstallation(root.multi_selected_pkg);
                                    } else {
                                        PacmanInfo.requestInstallation(info.deps.length > 0 ? [info.deps[info.deps.length - 1]] : [root.selected_pkg]);
                                    }
                                }
                            }
                        }

                        CellButton {

                            visible: (root.pacmanState == "idle" || root.pacmanState == "prepare" || root.pacmanState == "fetching" || root.pacmanState == "checking_updates") && PacmanInfo.isInstalled(root.selected_pkg)

                            text: "Uninstall"

                            clickable: root.selected_pkg != "" && root.multi_selected_pkg.length == 0 && root.pacmanState != "prepare"

                            color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                            fg: clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                            onReleased: button => {
                                if (button == "L") {
                                    PacmanInfo.requestRemoval([root.selected_pkg]);
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
                        fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                        onReleased: button => {
                            if (button == "L") {
                                PacmanInfo.cancel();
                            }
                        }
                    }

                    // Cancel mid installation
                    CellButton {

                        visible: root.pacmanState == "running"

                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                        text: "Cancel"

                        color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                        fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

                        onReleased: button => {
                            if (button == "L") {
                                PacmanInfo.cancel();
                            }
                        }
                    }

                    // Installation confirmation
                    CountdownConfirm {
                        id: confirm_install

                        visible: (root.pacmanState == "pre-flight" && PacmanInfo.pacmanMode == "install")

                        requiresCountdown: PacmanInfo.installPlan.conflictsWith.length > 0 || PacmanInfo.installPlan.willReplace.length > 0

                        countdownLabel: "Continue anyway (%1)"
                        standbyLabel: "Continue anyway"
                        confirmLabel: "Confirm"

                        onConfirmed: PacmanInfo.confirmInstallation()
                    }

                    // Removal confirmation
                    CountdownConfirm {
                        id: confirm_remove

                        visible: (root.pacmanState == "pre-flight" && PacmanInfo.pacmanMode == "remove")

                        requiresCountdown: PacmanInfo.removalPlan.brokenDependents.length > 0 || PacmanInfo.forceRemove

                        countdownLabel: PacmanInfo.forceRemove ? "Confirm cascade (%1)" : "Force remove (%1)"
                        standbyLabel: PacmanInfo.forceRemove ? "Confirm cascade" : "Force remove"
                        confirmLabel: "Confirm"

                        onConfirmed: PacmanInfo.confirmRemoval()
                    }
                }
            }
        }
    }

    component Info: RowLayout {

        visible: value.length > 0 && info.index != -1

        property string key: "Name"

        property string value: info.datas.name

        Layout.leftMargin: Cell.w(1)

        spacing: 0

        CellText {
            Layout.alignment: Qt.AlignTop
            text: (parent.key).padEnd(info.magic - 4, " ") + ": "
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

        Layout.leftMargin: Cell.w(1)

        spacing: 0

        CellText {
            Layout.alignment: Qt.AlignTop
            text: (parent.key).padEnd(info.magic - 4, " ") + ":"
            color: Colors.fgDim
        }

        ColumnLayout {

            Layout.alignment: Qt.AlignTop

            spacing: 0

            Repeater {

                model: deps.values?.slice(0, deps_footer.maxShown)

                delegate: Cells {
                    id: dep

                    required property string name
                    required property bool installed

                    // O(1) check via nameIndex instead of packages.some()
                    property bool isReal: PacmanInfo.getPackageIndex(dep.dep_name) !== -1

                    property var dep_data: {
                        if (name.includes("<="))
                            return name.split("<=");
                        else if (name.includes("<"))
                            return name.split("<");
                        else if (name.includes(">="))
                            return name.split(">=");
                        else if (name.includes(">"))
                            return name.split(">");
                        else if (name.includes("="))
                            return name.split("=");
                        return [name];
                    }
                    property string version_ops: {
                        if (name.includes("<="))
                            return "<=";
                        else if (name.includes("<"))
                            return "<";
                        else if (name.includes(">="))
                            return ">=";
                        else if (name.includes(">"))
                            return ">";
                        else if (name.includes("="))
                            return "";
                        return "";
                    }
                    property string dep_name: dep_data[0]
                    property string dep_version: dep_data[1] ?? ""

                    // No hover highlight for virtual packages — reinforces
                    // unclickability at the visual level.
                    color: (dep.isReal && dep_mouse.hovered) ? Colors.bgOverlay : "transparent"

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
                            text: dep.installed ? "*" : (dep.isReal ? "-" : "~")
                            color: dep.installed ? Colors.success : Colors.fgSubtle
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

                        onReleased: button => {
                            if (button == "L") {
                                info.deps.push(dep.dep_name);
                                info.depsChanged();
                            }
                        }
                    }
                }
            }

            CollapseFooter {
                id: deps_footer
                maxItems: deps.values?.length ?? 0
                collapseThreshold: deps.collapseThreshold
                expandStep: deps.expandStep
            }
        }
    }
}
