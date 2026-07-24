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

    property string mode: "general"

    w: box.eW * 3 + 3 + 2
    h: minimal ? 23 : 29

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

            Loader {

                active: (root.visible || !root.optimizeMemory) && root.mode == "general"

                asynchronous: true

                sourceComponent: General {
                    box: box
                    minimal: root.minimal
                }
            }

            Loader {

                active: (root.visible || !root.optimizeMemory) && root.mode == "process"

                asynchronous: true

                sourceComponent: General {
                    box: box
                    minimal: root.minimal
                }
            }
        }
    }
}
