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

    function toASCII(num: string): string {
        num = num.toLowerCase()
        if (num == "0") {
            return "█▀▀█\n█▄▀█\n█▄▄█"
        }
        else if (num == "1") {
            return "▄█ \n █ \n▄█▄"
        }
        else if (num == "2") {
            return "█▀█\n ▄▀\n█▄▄"
        }
        else if (num == "3") {
            return "█▀▀█\n  ▀▄\n█▄▄█"
        }
        else if (num == "4") {
            return " ▄▀█ \n█▄▄█▄\n   █ "
        }
        else if (num == "5") {
            return "█▀▀▀\n▀▀▀▄\n▄▄▄▀"
        }
        else if (num == "6") {
            return "▄▀▀▄\n█▄▄ \n▀▄▄▀"
        }
        else if (num == "7") {
            return "▀▀▀█\n  █ \n ▐▌ "
        }
        else if (num == "8") {
            return "▄▀▀▄\n▄▀▀▄\n▀▄▄▀"
        }
        else if (num == "9") {
            return "▄▀▀▄\n▀▄▄█\n ▄▄▀"
        }
        else if (num == ":") {
            return "▄\n \n▀"
        }
        else if (num == "a") {
            return "▄▀█\n█▀█"
        }
        else if (num == "p") {
            return "█▀█\n█▀▀"
        }
        else if (num == "m") {
            return "█▀▄▀█\n█ ▀ █"
        }
    }

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

                Image {

                    width: Cell.w(box.contentW)
                    height: Cell.h(10)

                    source: "/home/tsubenn/Wallpapers/detective_hutao.jpeg"

                    fillMode: Image.PreserveAspectCrop

                }

                RowLayout {

                    visible: false

                    x: Cell.w(2)
                    y: Cell.h(6)

                    spacing: Cell.w(1)

                    Repeater {

                        model: [...(DateTime.hour12 + ":" + DateTime.minute + DateTime.ampm)]

                        delegate: CellText {

                            Layout.alignment: Qt.AlignBottom

                            required property string modelData

                            text: root.toASCII(modelData)
                            color: Colors.fgBase
                        }

                    }
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


                    RowLayout {

                        spacing: 0

                        CellText {

                            visible: text.length > 0

                            id: mode

                            property string prefix: ""
                            property string value: {
                                switch (prefix) {
                                    case ">": tab.selected = 1; return "settings"
                                    case "?": tab.selected = 2; return "web"
                                    case "=": tab.selected = 3; return "calc"
                                    case "": tab.selected = 0; return "apps"
                                }
                                return "apps"
                            }

                            text: " " + prefix

                        }

                        CellTextField {

                            id: textfield

                            w: textbox.contentW - 2 - mode.text.length - 1
                            h: 1

                            placeholder: {
                                switch (mode.value) {
                                    case "settings": return " Settings search"
                                    case "web": return " Web search"
                                    case "calc": return " Calculator"
                                    case "apps": return "Search"
                                }
                                return "Search"
                            }

                            Keys.onPressed: (event) => {
                                if (event.key == Qt.Key_Escape) {
                                    PopupManager.close("launcher")
                                }
                            }

                            onTextChanged: {
                                if (text == ">") {
                                    mode.prefix = ">"
                                    text = " "
                                }
                                if (text == "?") {
                                    mode.prefix = "?"
                                    text = " "
                                }
                                if (text == "=") {
                                    mode.prefix = "="
                                    text = " "
                                }
                                if (text == "" && mode.prefix != "") {
                                    mode.prefix = ""
                                }

                                const query = text.trim()

                                if (mode.value == "apps") {
                                    LauncherInfo.search("apps", query)
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
                    switch (selected) {
                        case 0: mode.prefix = ""; textfield.text = ""; break;
                        case 1: mode.prefix = ">"; textfield.text = " "; break;
                        case 2: mode.prefix = "?"; textfield.text = " "; break;
                        case 3: mode.prefix = "="; textfield.text = " "; break;
                    }
                }

                w: box.contentW
                items: [
                    "Apps",
                    "Settings",
                    "Web",
                    "Calc",
                ]

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
                        }

                        delegate: Cells {

                            id: app_result

                            required property string id
                            required property string label
                            required property string description
                            required property string icon
                            required property string type

                            w: apps.contentW
                            h: 3

                            color: "transparent"

                            ColumnLayout {

                                id: app_layout

                                spacing: 0

                                RowLayout {

                                    spacing: 0

                                    CellText {
                                        text: " "
                                    }

                                    CellIcon {
                                        icon: [app_result.icon, app_result.label]
                                        w: 6
                                    }

                                    ColumnLayout {
                                        spacing: 0

                                        CellText {
                                            text: app_result.label
                                        }

                                        CellText {
                                            text: app_result.description
                                            color: Colors.fgSubtle
                                        }
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

        }

    }

}
