import QtQuick

MouseArea {

    id: root

    signal held(button: var)
    signal wheelDelta(delta: int)

    acceptedButtons: Qt.AllButtons

    onWheel: (mouse) => {mouse.angleDelta.y > 0 ? wheelDelta(1) : wheelDelta(-1)}

    onPressed: timer.running = true
    onReleased: timer.running = false

    Timer {
        id: timer

        interval: 1
        running: true
        repeat: true

        onTriggered: {
            if (root.pressed) {
                root.held(parent.pressedButtons)
            }
        }

    }

}

