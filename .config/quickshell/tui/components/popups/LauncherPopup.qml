import qs.config
import qs.modules
import qs.services

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

                    id: textfield

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
                                    case ">": return "settings"
                                    case "?": return "web"
                                    case "=": return "calc"
                                    case "": return "apps"
                                }
                                return "apps"
                            }

                            text: " " + prefix

                        }

                        CellTextField {

                            w: textfield.contentW - 2 - mode.text.length - 1
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
                            }
                        }

                    }


                }

            }

            CellTabs {

                w: box.contentW
                items: [
                    "Apps",
                    "Settings",
                    "Web",
                    "Calc",
                ]

            }

            CellText {
                text: IconInfo.fetch("minecraft")
            }

        }

    }

}
