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

                CellText {
                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                    text: "PACMAN"
                    color: Colors.secondary
                    font: Cell.fontBB
                }

                CellSeparator {
                    w: box.contentW
                    color: Colors.accentStrong
                }

                CellScrollView {

                    id: list

                    w: box.contentW
                    h: 14

                    signal selectedIndex(index: int)

                    property string selected_pkg: ""

                    onSelected_pkgChanged: {
                        PacmanInfo.getInfo(selected_pkg)
                    }

                    property var data: PacmanInfo.installed ? PacmanInfo.search_results.filter(item => item.installed) : PacmanInfo.search_results

                    property var optimized_data: data.slice(list.offset,list.offset+14)

                    virtualH: true

                    contentH: Cell.h(1)*data.length

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

                                color: selected ? Colors.bgOverlay : "transparent"

                                onSelectedChanged: {
                                    if (selected) {
                                        list.selectedIndex(pkg.index)
                                    }
                                }

                                RowLayout {

                                    x: Cell.w(1)

                                    spacing: Cell.w(1)

                                    Cells {
                                        w: 1
                                        h: 1

                                        color: pkg.installed ? Colors.success : Colors.bgOverlay
                                    }

                                    CellText {
                                        text: pkg.name
                                        preferedW: list.contentW - 6 - pkg_version.text.length
                                    }

                                    CellText {
                                        id: pkg_version
                                        text: "(" + pkg.version + ")"
                                        color: Colors.fgDim
                                    }

                                }

                                MouseControl {

                                    anchors.fill: parent

                                    onReleased: (button) => {
                                        if (button == "L") {
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

                                w: box.contentW - 34 - 3*PacmanInfo.fetching
                                h: 1

                                placeholder: "Search package"

                                onTextInput: (input) => {
                                    PacmanInfo.search(input)
                                }

                            }

                            CellLoading {
                                visible: PacmanInfo.fetching
                                style: 2
                            }

                            CellButton {

                                text: {
                                    if (PacmanInfo.search_mode == 0) {
                                        return "Fuzzy"
                                    } else if (PacmanInfo.search_mode == 1) {
                                        return "Name "
                                    } else if (PacmanInfo.search_mode == 2) {
                                        return "Exact"
                                    }
                                }

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

                CellScrollView {

                    w: box.contentW
                    h: box.contentH - list.h - 5

                }

            }

        }

    }


}
