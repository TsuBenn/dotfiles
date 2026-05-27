pragma Singleton

import Quickshell

Singleton {

    id: root

    property bool active: false

    property int active_fields: 0

    onActive_fieldsChanged: {
        if (active_fields > 0) {
            active = true
        } else {
            active = false
        }

        //console.log(`active fields: ${active_fields}`)
    }

    signal unFocusAll()

    function activated() {
        active_fields += 1
    }

    function deactivated() {
        active_fields -= 1
        if (active_fields < 0) {
            active_fields = 0
        }
    }

}
