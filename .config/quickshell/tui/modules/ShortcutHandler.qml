pragma ComponentBehavior: Bound

import QtQuick

Item {

    id: root

    property bool active: true

    property var shortcuts: []

    /*

     shortcuts = [
         {
             binds = "Key",
             action = () => {function},
         },
         ...
     ]

     */

    Repeater {
        model: root.shortcuts

        delegate: Loader {

            id: le_shortcut

            required property var modelData

            active: (modelData.active ?? true) && root.active

            sourceComponent: Shortcut {
                property var modelData: le_shortcut.modelData
                enabled: root.visible
                sequences: {
                    if (typeof modelData.binds != "string") {
                        return modelData.binds
                    }
                    return [modelData.binds]
                }
                onActivated: modelData.action()

            }
        }
    }

}
