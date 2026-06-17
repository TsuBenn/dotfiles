pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    id: root

    w: 80
    h: 40

    onVisibleChanged: {
        list.selected_index = 0
        list.selected_pkg = ""
        PacmanInfo.query = ""
        list.reset()
    }

    ShortcutHandler {
        shortcuts: [
            {
                binds: "Up",
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
                binds: "Down",
                action: () => {
                    if (list.selected_pkg == "") {
                        list.selected_pkg = list.datas[list.offset+list.h-1].name
                        return
                    }
                    if (list.selected_index+1 >= list.h) {
                        list.offset += list.h
                    }
                    list.selected_pkg = list.datas[list.offset + (list.selected_index+list.h+1)%list.h].name
                }
            }
        ]
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

                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                }

                CellScrollView {

                    id: list

                    w: box.contentW
                    h: 14

                    property int selected_index: 0
                    property string selected_pkg: ""

                    property var datas: PacmanInfo.installed ? PacmanInfo.search_results.filter(item => item.installed) : PacmanInfo.search_results

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
                                property bool installed: modelData.installed

                                property bool selected: list.selected_pkg == name

                                w: list.contentW
                                h: 1

                                color: selected ? Colors.accentStrong : (pkg_mouse.hovered ? Colors.bgOverlay : "transparent")

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
                                        color: pkg.selected ? Colors.onAccent : Colors.success
                                        font: Cell.fontB
                                    }

                                    CellText {
                                        text: pkg.name
                                        preferedW: list.contentW - 5 - pkg_version.text.length
                                        color: pkg.selected ? Colors.onAccent : Colors.fgBase
                                    }

                                    CellText {
                                        id: pkg_version
                                        text: "(" + pkg.version + ")"
                                        color: pkg.selected ? Colors.onAccent : Colors.fgDim
                                    }

                                }

                                MouseControl {

                                    id: pkg_mouse

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

                Cells {

                    w: box.contentW
                    h: 3

                    CellBox {

                        w: parent.w
                        h: 3

                        RowLayout {

                            x: Cell.w(1)

                            spacing: Cell.w(1)

                            CellTextField {

                                w: box.contentW - 29 - search_mode.text.length - 3*PacmanInfo.fetching
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
                                        PacmanInfo.search_mode = (PacmanInfo.search_mode + 1)%3
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

                                text: "Refresh"

                                clickable: !PacmanInfo.fetching

                                color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                                fg:    clickable ? [Colors.onAccent,     Colors.fgBase]    : Colors.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        PacmanInfo.fetch()
                                    }
                                }

                            }

                        }

                    }


                }

                RowLayout {

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

                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                }

                CellScrollView {

                    id: info

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

                    w: box.contentW
                    h: box.contentH - list.h - 7

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

                    source: ColumnLayout {

                        spacing: 0

                        CellText {

                            visible: info.index == -1

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, info.implicitWidth)

                            text: "\nNo package selected"
                            color: Colors.fgDim

                        }

                        Info {
                            key: "Name"
                            value: info.datas?.name ?? ""
                        }

                        Info {
                            key: "Version"
                            value: info.datas?.version ?? ""
                        }

                        Info {
                            key: "Description"
                            value: info.datas?.description ?? ""
                        }

                        Info {
                            key: "Url"
                            value: info.datas?.url ?? ""
                        }

                        Info {
                            key: "Licenses"
                            value: info.datas?.licenses ?? ""
                        }

                        Info {
                            key: "Repository"
                            value: info.datas?.repository ?? ""
                        }

                        Info {
                            key: "Groups"
                            value: info.datas?.groups ?? ""
                        }

                        Info {
                            key: "Download size"
                            value: info.datas?.download_size ?? ""
                        }

                        Info {
                            key: "Installed size"
                            value: info.datas?.installed_size ?? ""
                        }

                        Info {
                            key: "Packager"
                            value: info.datas?.packager ?? ""
                        }

                        Info {
                            key: "Installed"
                            value: info.datas?.installed ? "Yes" : "Nope"
                        }

                        Info {
                            key: "Installed date"
                            value: info.datas?.install_date ?? ""
                        }

                        Info {
                            key: "Installed reason"
                            value: info.datas?.install_reason ?? ""
                        }

                        Info {
                            key: "Installed script"
                            value: info.datas?.install_script ? "Yes" : "Nope"
                        }

                        Info {
                            key: "Validated by"
                            value: info.datas?.validated_by ?? ""
                        }

                        component Deps: RowLayout {

                            id: deps

                            property string key: "Dependencies"
                            property var values: info.datas?.depends

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

                                    model: deps.values

                                    delegate: Cells {

                                        visible: PacmanInfo.package.some(item => item.name = dep.dep_name)

                                        id: dep

                                        required property string name
                                        required property bool installed

                                        property var dep_data: {
                                            if (name.includes("<=")) {
                                                return name.split("<=")
                                            } else if (name.includes(">=")) {
                                                return name.split(">=")
                                            } else if (name.includes("=")) {
                                                return name.split("=")
                                            } 
                                            return [name]
                                        }
                                        property string version_ops: {
                                            if (name.includes("<=")) {
                                                return "<="
                                            } else if (name.includes(">=")) {
                                                return ">="
                                            } else if (name.includes("=")) {
                                                return ""
                                            } 
                                            return ""
                                        }
                                        property string dep_name: dep_data[0]
                                        property string dep_version: dep_data[1] ?? ""

                                        color: dep_mouse.hovered ? Colors.bgOverlay : "transparent"

                                        w: info.contentW - info.magic + 2
                                        h: 1

                                        RowLayout {

                                            x: Cell.w(1)

                                            spacing: Cell.w(1)

                                            CellText {

                                                text: (dep.installed ? "*" : " ")
                                                color: Colors.success
                                                font: Cell.fontB

                                            }

                                            CellText {

                                                text: dep.dep_name
                                                preferedW: Math.min(dep.w - 3, text.length)

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

                                            onReleased: (button) => {
                                                info.deps.push(dep.dep_name)
                                                info.depsChanged()
                                            }

                                        }

                                    }

                                }

                            }

                        }

                        Deps {
                            visible: info.datas?.depends.length > 0
                            key: "Dependencies"
                        }

                        Deps {
                            visible: info.datas?.optional_deps.length > 0
                            key: "Optional depends"
                            values: info.datas?.optional_deps
                        }

                    }

                }

            }

        }

    }

}
