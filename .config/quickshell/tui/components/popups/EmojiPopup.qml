import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    id: root

    w: 40
    h: 10

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

                property int offset: 0

            }

            CellScrollView {
                w: box.contentW
                h: 8

                ColumnLayout {

                    spacing: 0

                    Repeater {

                        model: EmojisInfo.emojis.slice(emojis.offset, 4)

                        delegate: Loader {

                            id: emoji_loader

                            required property var modelData
                            required property int index

                            active: true

                            sourceComponent: ColumnLayout {

                                id: emoji

                                property var modelData: emoji_loader.modelData
                                property int index: emoji_loader.index

                                spacing: 0

                                CellText {
                                    text: modelData.label
                                }

                            }

                        }

                    }

                }

            }

        }


    }

}
