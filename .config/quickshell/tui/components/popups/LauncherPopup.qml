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

                Image {

                    width: Cell.w(box.contentW)
                    height: Cell.h(10)

                    source: "/home/tsubenn/Wallpapers/detective_hutao.jpeg"

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
                                    process.exec(["python", ".config/quickshell/tui/scripts/launcher.py", "--mode", "apps", query])
                                }

                            }
                        }

                    }


                }

            }

            CellTabs {

                id: tab

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

                property var result: []

                w: box.contentW
                h: 15

                ColumnLayout {

                    spacing: 0

                    Repeater {

                        model: apps.result

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
                            h:3

                            color: "transparent"

                            ColumnLayout {

                                id: app_layout

                                spacing: 0

                                RowLayout {
                                    spacing: 0
                                    Cells {

                                        w: 5
                                        h: 2

                                        color: "transparent"

                                        Image {

                                            width: Cell.h(2)
                                            height: Cell.h(2)

                                            source: "image://icon/" + app_result.icon

                                            fillMode: Image.PreserveAspectCrop

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

    Process {

        id: process

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    const data = JSON.parse(text)
                    if (mode.value == "apps") {
                        apps.result = data
                        console.log(text)
                    } else if (mode.value == "settings") {
                        console.log(text)
                    } else if (mode.value == "web") {
                        console.log(text)
                    } else if (mode.value == "calc") {
                        console.log(text)
                    }
                }
            }
        }

    }

}
