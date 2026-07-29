pragma ComponentBehavior: Bound

import qs.components.popups.System

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {
    id: root

    property bool optimizeMemory: /* SettingsInfo.optimizeMemory */ false

    property bool minimal: SettingsInfo.minimal

    // Can be
    //   - general
    //   - process

    property string mode: tab.selected == 0 ? "general" : "process"

    w: box.eW * 3 + 3 + 1
    h: minimal ? 25 : 31

    CellBox {
        id: box

        property int eW: 42
        property int p: 1
        property color head: Colors.secondary
        property color key: Colors.fgSubtle
        property color bar: Colors.accentStrong
        property color stc: Colors.fgDim
        property color dyn: Colors.fgBase

        property int warning_thres: 70
        property int danger_thres: 80

        w: root.w
        h: root.h

        ColumnLayout {

            spacing: 0

            CellTabs {
                id: tab
                w: box.contentW
                items: ["General", "Process"]
                centered: false
                padding: 0
                spacing: 1
                offset: 1
                color.active: Colors.fgBase
                color.inactive: Colors.fgSubtle
                color.fg: Colors.accentStrong
                connect: true

                CellText {
                    text: "SYSTEM INFO"
                    font: Cell.fontBB
                    color: Colors.secondary
                    preferedW: box.contentW
                    centered: true
                }
            }

            Loader {

                active: (root.visible || !root.optimizeMemory)

                asynchronous: true

                property Component general_comp: General {
                    box: box
                    minimal: root.minimal
                }

                property Component process_comp: Process {
                    box: box
                    minimal: root.minimal
                }

                sourceComponent: root.mode == "general" ? general_comp : process_comp
            }
        }
    }
}
