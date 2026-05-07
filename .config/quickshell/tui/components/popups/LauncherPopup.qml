pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    w: 80
    h: Cell.hCount(layout.implicitHeight)

    onVisibleChanged: {

        /*
         if (visible) {
             if (!LauncherInfo.running) {
                 LauncherInfo.start()
             } else {
                 auto_close.stop()
             }
         }
         if (!visible && LauncherInfo.running) {
             auto_close.restart()
         }
         */
        if (!visible) {
            auto_close.restart()
            textfield.path = []
            textfield.set("")
            textfield.search("")
        } else {
            auto_close.stop()
        }
    }

    Timer {

        id: auto_close

        interval: 1000
        onTriggered: {
            LauncherInfo.write("-r")
        }

    }

    Timer {

        id: auto_refresh

        interval: 1800000

        running: true
        repeat: true
        onTriggered: {
            console.log("LauncherInfo: Occasional refresh...")
            LauncherInfo.reset()
        }

    }

    escapeToClose: false

    CellBox {

        id: box

        w: root.w
        h: root.h + 2

        ColumnLayout {

            id: layout

            spacing: 0

            Cells {

                visible: !SettingsInfo.minimal

                w: box.contentW
                h: 10

                color: "transparent"

                Image {

                    width: Cell.w(box.contentW)
                    height: Cell.h(10)

                    source: SystemInfo.homedir + WallpaperInfo.cache_path + WallpaperInfo.current + ".jpg"

                    fillMode: Image.PreserveAspectCrop

                }

            }

            Cells {

                id: text_wrapper

                w: box.contentW
                h: SettingsInfo.minimal ? 2 : 3

                color: "transparent"

                CellBox {

                    visible: !SettingsInfo.minimal

                    id: textbox

                    x: Cell.centerWCell(implicitWidth+Cell.w(2),parent.implicitWidth)
                    y: Cell.centerHCell(implicitHeight+Cell.w(2),parent.implicitHeight)

                    w: parent.w
                    h: parent.h

                    border.type: 4
                    border.color: textfield.text.trim().length > 0 ? Colors.secondary : Colors.fgBase

                    Item {

                        id: text_layout

                        RowLayout {

                            parent: SettingsInfo.minimal ? text_wrapper : text_layout

                            spacing: 0

                            CellText {

                                id: breadcrumbs

                                function updatePath() {
                                    if (textfield.path.length == 0) {
                                        text = ""
                                        return
                                    }
                                    let result = ""
                                    let paths = []
                                    for (const path of textfield.path) {
                                        paths.push(path.label)
                                    }
                                    result = paths.join(" > ")
                                    if (result) {
                                        text = " " + result + ":"
                                        return
                                    }
                                    text = ""
                                } 

                                text: ""
                            }

                            CellTextField {

                                id: textfield

                                property bool init: false

                                onVisibleChanged: {
                                    if (!init && visible) {
                                        textfield.search("")
                                        init = true
                                    }
                                }

                                property int selected: 0

                                property var path: []

                                Component.onCompleted: {
                                    LauncherInfo.pathFound.connect((id, label) => {
                                        textfield.path = [...path, {"id": id, "label": label}]
                                        textfield.search("")
                                        textfield.set("")
                                        breadcrumbs.updatePath()
                                    })
                                }

                                Layout.leftMargin: Cell.w(1)

                                w: textbox.contentW - 2 - breadcrumbs.text.length
                                h: 1

                                onEntered: (query) => {
                                    if (LauncherInfo.result.length > 0) {
                                        LauncherInfo.run(textfield.selected)
                                    } else {
                                        if (tab.selected != 3) {
                                            LauncherInfo.write(`-w ${query}`)
                                        }
                                    }
                                }


                                function search(input) {
                                    let tags = ""
                                    switch (tab.selected) {
                                        case 0: tags = "ashf"; break;
                                        case 1: tags = "af"; break;
                                        case 2: tags = "sf"; break;
                                        case 3: tags = "c"; break;
                                        case 4: tags = "h"; break;
                                    }
                                    safe_mouse.visible = true
                                    safe_mouse.safe = 1
                                    LauncherInfo.search(tags, textfield.path, input)
                                }

                                onTextRemoved: (removed) => {
                                    if (removed == "" && textfield.path.length > 0) {
                                        textfield.path.pop()
                                    }
                                    if (removed == "" && tab.selected != 0) {
                                        tab.selected = 0
                                        set("")
                                        search("")
                                    }
                                }

                                onTextInput: (input) => {
                                    if (input == ">") {
                                        tab.selected = 2
                                        set("")
                                        search("")
                                        return
                                    } else if (input == "=") {
                                        tab.selected = 3
                                        set("")
                                        search("")
                                        return
                                    } else if (input == "/") {
                                        tab.selected = 4
                                        set("")
                                        search("")
                                        return
                                    } else if (input == "@") {
                                        tab.selected = 1
                                        set("")
                                        search("")
                                        return
                                    }

                                    if ((tab.selected == 0 || tab.selected == 1 || tab.selected == 4) && input.trim().length == 1) return
                                    search(input)
                                }

                                function reset() {
                                    selected = 0
                                }

                                placeholder: {
                                    switch (tab.selected) {
                                        case 0: return "Search"
                                        case 1: return "Apps Search"
                                        case 2: return "Settings search"
                                        case 3: return "Calculator"
                                        case 4: return "File Search"
                                    }
                                    return "Search"
                                }

                                editable: text.trim().length > 0

                            }

                        }
                    }


                }

                CellSeparator {
                    y: Cell.h(1)
                    w: parent.w
                    visible: SettingsInfo.minimal
                }

            }

            CellTabs {

                id: tab

                padding: 0

                w: box.contentW

                onVisibleChanged: {
                    tab.selected = 0
                }

                onSelectedChanged: {
                    textfield.set("")
                    textfield.path = []
                    textfield.search("")
                    breadcrumbs.updatePath()
                }

                items: [
                    "All",
                    "@ Apps",
                    "> Settings",
                    "= Calc",
                    "/ File",
                ]

            }

            Cells {

                w: box.contentW
                h: 15

                color: "transparent"

                ColumnLayout {

                    x: Cell.centerWCell(implicitWidth, parent.implicitWidth) - Cell.w(1)

                    spacing: 0

                    CellText {
                        text: " "
                    }

                    CellText {
                        text: "No result"
                        color: Colors.fgSubtle
                    }

                }

                Timer {
                    id: debounce

                    property var data: LauncherInfo.result

                    Component.onCompleted: {
                        LauncherInfo.searched.connect(() => {
                            debounce.restart()
                        })
                        SettingsInfo.toggleMinimal.connect(() => {
                            //debounce.restart()
                        })
                    }

                    interval: 0
                    onTriggered: {
                        data = []
                        data = LauncherInfo.result
                    }

                }

                Loader {

                    active: root.visible || !SettingsInfo.optimizeMemory

                    sourceComponent: CellScrollView {

                        id: results

                        w: box.contentW
                        h: 15

                        onVisibleChanged: {
                            results.reset()
                        }

                        ColumnLayout {

                            spacing: 0

                            ShortcutHandler {

                                property int result_h: SettingsInfo.minimal ? 2 : 3

                                shortcuts: [
                                    {
                                        binds: "Up",
                                        action: () => {
                                            safe_mouse.safe = 1
                                            safe_mouse.visible = true
                                            if (textfield.selected == 0) return
                                            textfield.selected -= 1
                                            if (textfield.selected - Math.floor(results.offset/result_h) < 0) {
                                                results.offset = Math.max((textfield.selected-Math.ceil(15/result_h))*result_h,0)
                                            }
                                        }
                                    },
                                    {
                                        binds: "Down",
                                        action: () => {
                                            safe_mouse.safe = 1
                                            safe_mouse.visible = true
                                            if (textfield.selected >= LauncherInfo.result.length-1) {
                                                textfield.selected = 0
                                                return
                                            }
                                            textfield.selected += 1
                                            if (textfield.selected - Math.floor(results.offset/result_h) > Math.ceil(15/result_h)-1) {
                                                results.offset = textfield.selected*result_h
                                            }
                                        }
                                    },
                                    {
                                        binds: "Right",
                                        action: () => {
                                            if (textfield.text.length == 0) {
                                                tab.advance(1)
                                            } else {
                                                textfield.move_cursor_forward()
                                            }
                                        }
                                    },
                                    {
                                        binds: "Left",
                                        action: () => {
                                            if (textfield.text.length == 0) {
                                                tab.advance(-1)
                                            } else {
                                                textfield.move_cursor_back()
                                            }
                                        }
                                    },
                                    {
                                        binds: "Tab",
                                        action: () => {
                                            safe_mouse.safe = 1
                                            safe_mouse.visible = true
                                            if (textfield.selected >= LauncherInfo.result.length-1) {
                                                textfield.selected = 0
                                                return
                                            }
                                            textfield.selected += 1
                                            if (textfield.selected - Math.floor(results.offset/result_h) > Math.ceil(15/result_h)-1) {
                                                results.offset = textfield.selected*result_h
                                            }
                                        }
                                    },
                                    {
                                        binds: "Shift+Tab",
                                        action: () => {
                                            safe_mouse.safe = 1
                                            safe_mouse.visible = true
                                            if (textfield.selected == 0) return
                                            textfield.selected -= 1
                                            if (textfield.selected - Math.floor(results.offset/result_h) < 0) {
                                                results.offset = Math.max((textfield.selected-Math.ceil(15/result_h))*result_h,0)
                                            }
                                        }
                                    },
                                    {
                                        binds: "Escape",
                                        action: () => {
                                            if (textfield.path.length > 0) {
                                                const new_path = textfield.path
                                                new_path.pop()
                                                textfield.path = new_path
                                                textfield.search("")
                                                textfield.set("")
                                                breadcrumbs.updatePath()
                                            } else {
                                                PopupManager.close("launcher")
                                            }
                                        }
                                    },
                                ]
                            }

                            Repeater {

                                model: debounce.data

                                onModelChanged: {
                                    results.reset()
                                    textfield.selected = 0
                                }

                                delegate: Loader {

                                    id: result

                                    active: (index - Math.ceil(results.offset/(SettingsInfo.minimal ? 2 : 3)) < Math.ceil(15/(SettingsInfo.minimal ? 2 : 3)) * 2)
                                    && (root.visible || !SettingsInfo.optimizeMemory)

                                    required property int index

                                    required property var modelData

                                    property string id: modelData.id ?? ""
                                    property string label: modelData.label ?? ""
                                    property string description: modelData.description ?? ""
                                    property string icon: modelData.icon ?? ""
                                    property string type: modelData.type ?? ""
                                    property var value: modelData.value ?? []

                                    property bool selected: textfield.selected == index

                                    asynchronous: (index < Math.ceil(15/(SettingsInfo.minimal ? 2 : 3)) ? false : true) || type == "file" || type == "dir"

                                    sourceComponent: Cells {

                                        w: results.contentW
                                        h: SettingsInfo.minimal ? 2 : 3

                                        color: Colors.bgSurface

                                        ColumnLayout {

                                            id: result_layout

                                            spacing: 0

                                            RowLayout {

                                                spacing: 0

                                                CellText {
                                                    text: " "
                                                }

                                                CellIcon {
                                                    visible: !SettingsInfo.minimal
                                                    id: result_icon
                                                    icon: [result.icon, result.icon ? result.label : ""]
                                                    w: 5
                                                }

                                                CellText {
                                                    text: " "
                                                }

                                                ColumnLayout {
                                                    spacing: 0

                                                    CellText {
                                                        text: {
                                                            let macro = result.label.match(/\{(.*)\}/)?.[1] ?? ""
                                                            if (macro) {
                                                                return result.label.replace(/\{(.*)\}/,SettingsInfo.get_state(macro))
                                                            }
                                                            return result.label
                                                        }
                                                        preferedW: results.contentW - 5 - 5*result_icon.success
                                                    }

                                                    CellText {
                                                        visible: !SettingsInfo.minimal
                                                        text: result.description
                                                        preferedW: results.contentW - 5 - 5*result_icon.success
                                                        color: Colors.fgSubtle
                                                    }
                                                }

                                                CellText {
                                                    text: " "
                                                }

                                                Cells {

                                                    w: 1
                                                    h: SettingsInfo.minimal ? 1 : 2

                                                    color: result.selected ? Colors.accentStrong : Colors.bgOverlay

                                                }

                                            }

                                            CellSeparator {

                                                type: 2
                                                color: Colors.bgOverlay
                                                padding: 1
                                                w: results.contentW

                                            }

                                        }

                                        Cells {

                                            w: results.contentW
                                            h: SettingsInfo.minimal ? 1 : 2
                                            color: "transparent"

                                            MouseControl {

                                                anchors.fill: parent

                                                onEntered: {
                                                    textfield.selected = result.index
                                                }

                                                onReleased: (button) => {
                                                    if (button == "L") {
                                                        textfield.entered(textfield.text)
                                                    }
                                                }

                                            }

                                        }

                                    }
                                }

                            }

                        }

                    }
                }

            }

            CellSeparator {

                visible: SettingsInfo.hints

                w: box.contentW
                type: 2
                color: Colors.bgOverlay
            }

            GridLayout {

                visible: SettingsInfo.hints

                rowSpacing: Cell.h(1)
                columnSpacing: Cell.w(2)
                columns: 5

                uniformCellHeights: false
                uniformCellWidths: false


                Layout.leftMargin: Cell.centerWCell(implicitWidth,parent.implicitWidth)

                CellKeyHint {
                    visible: textfield.path.length == 0
                    key: "Esc"
                    hint: "Exit"
                }

                CellKeyHint {
                    visible: textfield.path.length > 0
                    key: "Esc"
                    hint: "Back"
                }

                CellKeyHint {
                    visible: (
                        tab.selected == 0 || 
                        tab.selected == 1 ||
                        tab.selected == 2 ||
                        tab.selected == 4
                    )
                    key: "[Type]"
                    hint: "Search"
                    padding: 0
                }

                CellKeyHint {
                    visible: tab.selected == 3
                    key: "[Type]"
                    hint: "Calculate"
                    padding: 0
                }

                CellKeyHint {
                    visible: ( tab.selected == 0 || tab.selected == 1 || tab.selected == 2) && LauncherInfo.result.length > 0 
                    key: "Enter"
                    hint: "Select"
                }

                CellKeyHint {
                    visible: ( tab.selected == 0 || tab.selected == 1 || tab.selected == 2) && LauncherInfo.result.length == 0 && textfield.text.trim().length > 0
                    key: "Enter"
                    hint: "Google"
                }

                CellKeyHint {
                    visible: tab.selected != 0 && textfield.text.trim().length == 0
                    key: "BS"
                    hint: "All"
                }

                CellKeyHint {
                    visible: tab.selected == 3
                    key: "Enter"
                    hint: textfield.text.trim().length > 0 && textfield.selected == 0 ? "Copy" : "Add"
                }

                CellKeyHint {
                    key: "← →"
                    hint: "Next/Prev tab"
                    visible: textfield.text.trim().length == 0
                }

            }

        }

        MouseControl {

            anchors.fill: parent

            id: safe_mouse

            property int safe: 0

            onPressed: {
                visible = false
            }
            onMoved: {
                if (safe > 0) {
                    safe -= 1
                    return
                }
                visible = false
            }

        }

    }

}
