pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import Quickshell.Io
import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    w: 80
    h: Cell.hCount(layout.implicitHeight)

    CellBox {

        id: box

        w: root.w
        h: root.h + 2

        ColumnLayout {


            id: layout

            spacing: 0

            Cells {

                w: box.contentW
                h: 10

                color: "transparent"

                Image {

                    width: Cell.w(box.contentW)
                    height: Cell.h(10)

                    source: SystemInfo.homedir + WallpaperInfo.path + WallpaperInfo.current

                    fillMode: Image.PreserveAspectCrop

                }

            }

            Cells {

                w: box.contentW
                h: 3

                color: "transparent"

                CellBox {

                    id: textbox

                    x: Cell.centerWCell(implicitWidth+Cell.w(2),parent.implicitWidth)

                    w: parent.w
                    h: parent.h

                    border.type: 4
                    border.color: textfield.text.trim().length > 0 ? Colors.secondary : Colors.fgBase

                    RowLayout {

                        spacing: 0

                        CellText {

                            visible: text.length > 0

                            onVisibleChanged: {
                                prefix = ""
                            }

                            id: mode

                            property string additional: ""

                            property string prefix: ""
                            property string value: {
                                switch (prefix) {
                                    case ">": tab.selected = 1; return "settings"
                                    case "=": tab.selected = 2; return "calc"
                                    case "?": tab.selected = 3; return "web"
                                    case "": tab.selected = 0; return "apps"
                                }
                                return "apps"
                            }

                            text: " " + prefix + (additional ? " " + additional : "")

                        }

                        CellTextField {

                            id: textfield

                            property int selected: 0

                            w: textbox.contentW - 2 - mode.text.length - 1
                            h: 1

                            Component.onCompleted: {
                                LauncherInfo.appsChanged.connect(() => {
                                    reset()
                                })
                            }

                            onEntered: (query) => {
                                if (mode.value == "apps") {
                                    LauncherInfo.select("apps", query, LauncherInfo.apps[selected].id)
                                    PopupManager.close("launcher")
                                } else if (mode.value == "settings") {
                                    const path = SettingsInfo.run(settings.selected)
                                    if (path != "null") {
                                        textfield.set(" ")
                                        settings.path = [...settings.path, path]
                                        SettingsInfo.search(settings.path, "")
                                    }
                                } else if (mode.value == "web") {
                                    LauncherInfo.select("web", "", text)
                                } else if (mode.value == "calc") {
                                    if (textfield.text.trim().length > 0) {
                                        if (textfield.selected == 0) {
                                            if (!LauncherInfo.calc[textfield.selected].description) {
                                                return
                                            }
                                            SystemInfo.copy_clipboard(LauncherInfo.calc[textfield.selected].description)
                                            NotificationsInfo.send("", "", "Calculator","Copied result: " + LauncherInfo.calc[textfield.selected].description)
                                            return
                                        }
                                    }
                                    text += LauncherInfo.calc[textfield.selected].label
                                    cursorPos += LauncherInfo.calc[textfield.selected].cursor
                                }
                            }

                            function reset() {
                                selected = 0
                            }

                            placeholder: {
                                switch (mode.value) {
                                    case "settings": return " Settings search"
                                    case "web": return " Web search"
                                    case "calc": return " Calculator"
                                    case "apps": return "Search"
                                }
                                return "Search"
                            }

                            editable: text.trim().length > 0

                            Keys.onPressed: (event) => {
                                let views = apps
                                let max = LauncherInfo.apps.length
                                if (mode.value == "settings") {
                                    views = settings
                                    max = SettingsInfo.result.length
                                } if (mode.value == "calc") {
                                    views = calc
                                    max = LauncherInfo.calc.length
                                }

                                if (!editable) {
                                    if (event.key == Qt.Key_Right) {
                                        tab.advance(1)
                                    } else if (event.key == Qt.Key_Left) {
                                        tab.advance(-1)
                                    }
                                }

                                if (event.key == Qt.Key_Escape) {
                                    if (settings.path.length > 0) {
                                        PopupManager.preventClosing = true
                                        let new_path = settings.path 
                                        new_path.pop()
                                        settings.path = []
                                        settings.path = new_path
                                        SettingsInfo.search(settings.path, "")
                                        return
                                    }
                                    PopupManager.close("launcher")
                                } else if (event.key == Qt.Key_Tab) {
                                    if (tab.selected < 3) {
                                        tab.selected += 1
                                        return
                                    }
                                    tab.selected = 0
                                } else if (event.key == Qt.Key_Up) {
                                    if (textfield.selected > 0) {
                                        textfield.selected -= 1
                                    }
                                    if (textfield.selected-Math.ceil(views.offset/3) < 0) {
                                        views.offset = Math.max((selected-4)*3,0)
                                    }
                                } else if (event.key == Qt.Key_Down) {
                                    if (textfield.selected < max - 1) {
                                        textfield.selected += 1
                                    }
                                    if (textfield.selected-Math.floor(views.offset/3) >= 5) {
                                        views.offset = selected*3
                                    }
                                }
                            }

                            onTextInput: (text) => {
                                let query = text.trim()

                                if (text == ">") {
                                    mode.prefix = ">"
                                    set(" ")
                                    query = ""
                                }
                                if (text == "?") {
                                    mode.prefix = "?"
                                }
                                if (text == "=") {
                                    mode.prefix = "="
                                    set(" ")
                                    query = ""
                                }
                                if (text == "" && mode.prefix != "") {
                                    mode.prefix = ""
                                    set("")
                                    query = ""
                                }

                                if (mode.value == "apps" && textfield.text.length != 1) {
                                    LauncherInfo.search_apps(query)
                                } else if (mode.value == "settings") {
                                    SettingsInfo.search(settings.path, query)
                                } else if (mode.value == "calc") {
                                    if (textfield.text.trim().length > 0) {
                                        LauncherInfo.calculate(query)
                                    } else {
                                        LauncherInfo.calculate("")
                                    }
                                }

                            }
                        }

                    }


                }

            }

            CellTabs {

                id: tab

                padding: 0
                onSelectedChanged: {
                    safe_mouse.safe = 1
                    safe_mouse.visible = true

                    switch (selected) {
                        case 0: mode.prefix = ""; textfield.set(""); break;
                        case 1: mode.prefix = ">"; textfield.set(" "); break;
                        case 2: mode.prefix = "="; textfield.set(" "); break;
                        case 3: mode.prefix = "?"; textfield.set(" "); break;
                    }
                }

                w: box.contentW
                items: [
                    "Apps",
                    "Settings",
                    "Calc",
                    "Web",
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

                CellScrollView {

                    id: apps

                    visible: tab.selected == 0

                    onVisibleChanged: {
                        LauncherInfo.reset()
                    }

                    w: box.contentW
                    h: 15

                    ColumnLayout {

                        spacing: 0

                        Repeater {

                            model: LauncherInfo.apps

                            onModelChanged: {
                                apps.reset()
                                textfield.selected = 0
                            }

                            delegate: Cells {

                                id: app_result

                                required property int index

                                required property string id
                                required property string label
                                required property string description
                                required property string icon
                                required property string type

                                property bool selected: textfield.selected == index

                                w: apps.contentW
                                h: 3

                                color: Colors.bgSurface

                                Cells {

                                    w: apps.contentW
                                    h: 2
                                    color: "transparent"

                                    MouseControl {

                                        anchors.fill: parent

                                        onEntered: {
                                            textfield.selected = app_result.index
                                        }

                                        onReleased: (button) => {
                                            if (button == "L") {
                                                textfield.entered(textfield.text)
                                            }
                                        }

                                    }

                                }

                                ColumnLayout {

                                    id: app_layout

                                    spacing: 0

                                    RowLayout {

                                        spacing: 0

                                        CellText {
                                            text: " "
                                        }

                                        CellIcon {
                                            id: apps_icon
                                            icon: [app_result.icon, app_result.label]
                                            w: 5
                                        }

                                        CellText {
                                            text: " "
                                        }

                                        ColumnLayout {
                                            spacing: 0

                                            CellText {
                                                text: app_result.label
                                                preferedW: apps.contentW - 4 - 5*apps_icon.success
                                            }

                                            CellText {
                                                text: app_result.description
                                                preferedW: apps.contentW - 4 - 5*apps_icon.success
                                                color: Colors.fgSubtle
                                            }
                                        }

                                        Cells {

                                            w: 1
                                            h: 2

                                            color: app_result.selected ? Colors.accentStrong : Colors.bgOverlay

                                        }

                                    }

                                    CellSeparator {

                                        type: 2
                                        color: Colors.bgOverlay
                                        padding: 1
                                        w: apps.contentW

                                    }

                                }


                            }

                        }

                    }

                }

                CellScrollView {

                    id: settings

                    visible: tab.selected == 1

                    property var path: []
                    property var selected: ({})

                    onPathChanged: {
                        if (path.length > 0) {
                            mode.additional = path.join(" > ") + ":"
                        } else {
                            mode.additional = ""
                        }
                    }

                    onVisibleChanged: {
                        path = []
                        selected = ({})
                        SettingsInfo.reset()
                        SettingsInfo.search([],"")
                    }

                    w: box.contentW
                    h: 15

                    ColumnLayout {

                        spacing: 0

                        Repeater {

                            model: SettingsInfo.result

                            onModelChanged: {
                                settings.reset()
                                textfield.selected = 0
                            }

                            delegate: Cells {

                                id: setting_result

                                required property int index

                                required property var modelData

                                property string id: modelData.id ?? ""
                                property string label: modelData.label
                                property string description: modelData.description ?? ""
                                property string icon: modelData.icon ?? ""

                                property bool selected: textfield.selected == index

                                onSelectedChanged: {
                                    if (selected) {
                                        settings.selected = modelData
                                    }
                                }

                                w: settings.contentW
                                h: 3

                                color: Colors.bgSurface

                                Cells {

                                    w: settings.contentW
                                    h: 2
                                    color: "transparent"

                                    MouseControl {

                                        anchors.fill: parent

                                        onEntered: {
                                            textfield.selected = setting_result.index
                                        }

                                        onReleased: (button) => {
                                            if (button == "L") {
                                                textfield.entered(textfield.text)
                                            }
                                        }

                                    }

                                }

                                ColumnLayout {

                                    id: setting_layout

                                    spacing: 0

                                    RowLayout {

                                        spacing: 0

                                        CellText {
                                            text: " "
                                        }

                                        CellIcon {
                                            id: setting_icon
                                            image: setting_result.icon
                                            w: 5
                                        }

                                        CellText {
                                            text: " "
                                        }

                                        ColumnLayout {
                                            spacing: 0

                                            CellText {
                                                text: setting_result.label
                                                preferedW: settings.contentW - 4 - 5*setting_icon.success
                                            }

                                            CellText {
                                                text: setting_result.description
                                                preferedW: settings.contentW - 4 - 5*setting_icon.success
                                                color: Colors.fgSubtle
                                            }
                                        }

                                        Cells {

                                            w: 1
                                            h: 2

                                            color: setting_result.selected ? Colors.accentStrong : Colors.bgOverlay

                                        }

                                    }

                                    CellSeparator {

                                        type: 2
                                        color: Colors.bgOverlay
                                        padding: 1
                                        w: settings.contentW

                                    }

                                }


                            }

                        }

                    }

                }

                CellScrollView {

                    id: calc

                    visible: tab.selected == 2

                    w: box.contentW
                    h: 15

                    ColumnLayout {

                        spacing: 0

                        Repeater {

                            model: LauncherInfo.calc

                            onModelChanged: {
                                calc.reset()
                                textfield.selected = 0
                            }

                            delegate: Cells {

                                id: calc_result

                                required property int index

                                required property var modelData

                                property string label: modelData.label
                                property string description: modelData.description ?? ""

                                property bool selected: textfield.selected == index

                                w: calc.contentW
                                h: 3

                                color: Colors.bgSurface

                                Cells {

                                    w: calc.contentW
                                    h: 2
                                    color: "transparent"

                                    MouseControl {

                                        anchors.fill: parent

                                        onEntered: {
                                            textfield.selected = calc_result.index
                                        }

                                        onReleased: (button) => {
                                            if (button == "L") {
                                                textfield.entered(textfield.text)
                                            }
                                        }

                                    }

                                }

                                ColumnLayout {

                                    id: calc_layout

                                    spacing: 0

                                    RowLayout {

                                        spacing: 0

                                        CellText {
                                            text: "  "
                                        }

                                        ColumnLayout {
                                            spacing: 0

                                            CellText {
                                                text: calc_result.label
                                                preferedW: settings.contentW - 4
                                            }

                                            CellText {
                                                text: calc_result.description
                                                preferedW: settings.contentW - 4
                                                color: Colors.fgSubtle
                                            }
                                        }

                                        Cells {

                                            w: 1
                                            h: 2

                                            color: calc_result.selected ? Colors.accentStrong : Colors.bgOverlay

                                        }

                                    }

                                    CellSeparator {

                                        type: 2
                                        color: Colors.bgOverlay
                                        padding: 1
                                        w: calc.contentW

                                    }

                                }


                            }

                        }

                    }

                }

                CellScrollView {

                    id: web

                    visible: tab.selected == 3

                    w: box.contentW
                    h: 15

                }

            }

            CellSeparator {
                w: box.contentW
                type: 2
                color: Colors.bgOverlay
            }

            GridLayout {

                rowSpacing: Cell.h(1)
                columnSpacing: Cell.w(2)
                columns: 5

                uniformCellHeights: false
                uniformCellWidths: false


                Layout.leftMargin: Cell.centerWCell(implicitWidth,parent.implicitWidth)

                RowLayout {

                    visible: settings.path.length == 0

                    spacing: 0

                    CellText {
                        text: " Esc "
                        bg: Colors.bgOverlay
                    }

                    CellText {
                        text: " Exit"
                    }
                }

                RowLayout {

                    visible: settings.path.length > 0

                    spacing: 0

                    CellText {
                        text: " Esc "
                        bg: Colors.bgOverlay
                    }

                    CellText {
                        text: " Return"
                    }

                }

                RowLayout {

                    visible: apps.visible && settings.visible

                    spacing: 0

                    CellText {
                        text: "[Type]"
                        bg: Colors.bgOverlay
                    }

                    CellText {
                        text: " Search"
                    }
                }

                RowLayout {

                    visible: calc.visible

                    spacing: 0

                    CellText {
                        text: "[Type]"
                        bg: Colors.bgOverlay
                    }

                    CellText {
                        text: " Calculate"
                    }
                }

                RowLayout {

                    visible: (textfield.text.length > 1 && apps.visible && LauncherInfo.apps.length > 0) || (settings.visible && SettingsInfo.result.length > 0)

                    spacing: 0

                    CellText {
                        text: " Enter "
                        bg: Colors.bgOverlay
                    }

                    CellText {
                        text: " Select"
                    }

                }

                RowLayout {

                    visible: web.visible

                    spacing: 0

                    CellText {
                        text: " Enter "
                        bg: Colors.bgOverlay
                    }

                    CellText {
                        text: " Search"
                    }

                }

                RowLayout {

                    visible: calc.visible

                    spacing: 0

                    CellText {
                        text: " Enter "
                        bg: Colors.bgOverlay
                    }

                    CellText {
                        text: textfield.text.trim().length > 0 ? " Copy" : " Add"
                    }

                }

                RowLayout {

                    spacing: 0

                    CellText {
                        text: " ← "
                        bg: Colors.bgOverlay
                        color: textfield.text.trim().length > 0 ? Colors.fgSubtle : Colors.fgBase
                    }

                    CellText {
                        text: " Prev Tab"
                        color: textfield.text.trim().length > 0 ? Colors.fgSubtle : Colors.fgBase
                    }
                }

                RowLayout {

                    spacing: 0

                    CellText {
                        text: " → "
                        bg: Colors.bgOverlay
                        color: textfield.text.trim().length > 0 ? Colors.fgSubtle : Colors.fgBase
                    }

                    CellText {
                        text: " Next Tab"
                        color: textfield.text.trim().length > 0 ? Colors.fgSubtle : Colors.fgBase
                    }
                }

            }

        }

        MouseControl {

            anchors.fill: parent

            id: safe_mouse

            property int safe: 0

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
