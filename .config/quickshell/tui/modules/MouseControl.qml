import QtQuick

Rectangle {

    id: root

    signal pressed(button : string)
    signal released(button : string)
    signal entered()
    signal exited()
    signal wheel(delta : int)
    signal held(button: string)

    property bool hovered: false

    MouseArea {

        id: mouse

        acceptedButtons: Qt.AllButtons

        hoverEnabled: true

        onWheel: (mouse) => {mouse.angleDelta.y > 0 ? root.wheel(1) : root.wheel(-1)}

        onEntered: {
            root.hovered = true
        }

        onExited: {
            root.hovered = false
        }

        onPressed: (event) => {
            timer.running = true
            var result = ""
            if (event.modifiers == Qt.ShiftModifier) result = "S"
            if (event.modifiers == Qt.ControlModifier) result = "C"
            if (event.modifiers == Qt.AltModifier) result = "A"
            if (event.modifiers == Qt.MetaModifier) result = "W"
            if (event.button == Qt.LeftButton) result += "L"
            else if (event.button == Qt.RightButton) result += "R"
            else if (event.button == Qt.MiddleButton) result += "M"
            timer.button = result
            root.pressed(result)
        }
        onReleased: (event) => {
            timer.running = false
            timer.button = ""
            var result = ""
            if (event.modifiers == Qt.ShiftModifier) result = "S"
            if (event.modifiers == Qt.ControlModifier) result = "C"
            if (event.modifiers == Qt.AltModifier) result = "A"
            if (event.modifiers == Qt.MetaModifier) result = "W"
            if (event.button == Qt.LeftButton) result += "L"
            else if (event.button == Qt.RightButton) result += "R"
            else if (event.button == Qt.MiddleButton) result += "M"
            root.released(result)
        }

        Timer {
            id: timer

            property string button: ""

            interval: 1
            repeat: true

            onTriggered: {
                if (mouse.pressed) {
                    root.held(button)
                }
            }

        }

    }
}

