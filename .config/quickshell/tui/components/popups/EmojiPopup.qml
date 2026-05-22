pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    id: root

    w: 41
    h: 20

    CellBox {

        id: box

        w: root.w+2
        h: root.h+2

        ColumnLayout {

            id: layout

            spacing: 0

            CellTextField {

                Layout.leftMargin: Cell.w(1)

                w: box.contentW-2

                id: textfield

                placeholder: "Search emojis"

            }

            CellSeparator {
                w: box.contentW
                color: Colors.accentStrong
            }

            Item {

                id: emojis

                property var result: EmojisInfo.emojis

                property int offset: 0

            }

            CellScrollView {

                id: list

                w: box.contentW
                h: root.h-2

                source: ColumnLayout {

                    spacing: 0

                    Repeater {

                        model: Object.keys(EmojisInfo.emojis)

                        delegate: Loader {

                            id: emoji_loader

                            required property var modelData
                            required property int index

                            active: (root.visible || !root.optimizeMemory)

                            sourceComponent: ColumnLayout {

                                id: emoji_group

                                spacing: 0

                                property var modelData: emoji_loader.modelData
                                property int index: emoji_loader.index

                                CellText {
                                    Layout.leftMargin: Cell.w(1)
                                    text: emoji_group.modelData
                                    color: Colors.fgDim
                                }

                                GridLayout {

                                    rowSpacing: 0
                                    columnSpacing: 0

                                    columns: 8

                                    Repeater {

                                        model: EmojisInfo.emojis[emoji_group.modelData].slice(emojis.offset, 8)

                                        delegate: Cells {

                                            id: emoji

                                            required property var modelData

                                            w: 5
                                            h: 3

                                            CellBox {

                                                w: 5
                                                h: 3

                                                border.color: Colors.fgSubtle

                                                CellText {
                                                    x: Cell.w(0.5)
                                                    text: emoji.modelData.label
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


    }

}
