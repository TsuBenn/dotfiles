import QtQuick

Item {

    id: root

    signal pressed(button : string)
    signal released(button : string)
    signal entered()
    signal exited()
    signal wheel(delta : int)
    signal held(button: string)
    signal moved(x: real, y: real)

    property string buttonDown: ""
    property bool hovered: mouse.containsMouse

    property bool hoverEnabled: true

    property bool holdEnabled: false
    property int holdInterval: 100
    property int holdOffset: 0

    property int mouseX: mouse.mouseX
    property int mouseY: mouse.mouseY

    property var acceptedButtons: Qt.AllButtons

    onVisibleChanged: {
        buttonDown = ""
    }

    MouseArea {

        id: mouse

        anchors.fill: parent

        acceptedButtons: root.acceptedButtons

        hoverEnabled: root.hoverEnabled

        onWheel: (mouse) => {mouse.angleDelta.y > 0 ? root.wheel(1) : root.wheel(-1)}

        onPositionChanged: (mouse) => {
            root.moved(mouseX, mouseY)
        }

        onEntered: {
            root.hovered = true
            root.entered()
        }

        onExited: {
            root.hovered = false
            root.exited()
        }

        onPressed: (event) => {
            if (root.holdEnabled) timer_offset.start()
            var result = ""
            if (event.modifiers == Qt.ShiftModifier) result = "S"
            else if (event.modifiers == Qt.ControlModifier) result = "C"
            else if (event.modifiers == Qt.AltModifier) result = "A"
            if (event.button == Qt.LeftButton) result += "L"
            else if (event.button == Qt.RightButton) result += "R"
            else if (event.button == Qt.MiddleButton) result += "M"
            timer.button = result
            root.buttonDown = result
            root.pressed(result)
        }
        onPressAndHold: {
            if (!root.holdEnabled) console.log("MouseControl: \"hold\" is turned off")
        }
        onReleased: (event) => {
            timer_offset.stop()
            timer.stop()
            timer.button = ""
            var result = ""
            if (event.modifiers == Qt.ShiftModifier) result = "S"
            else if (event.modifiers == Qt.ControlModifier) result = "C"
            else if (event.modifiers == Qt.AltModifier) result = "A"
            if (event.button == Qt.LeftButton) result += "L"
            else if (event.button == Qt.RightButton) result += "R"
            else if (event.button == Qt.MiddleButton) result += "M"
            root.buttonDown = ""
            root.released(result)
        }

        Timer {
            id: timer_offset

            interval: root.holdOffset

            onTriggered: {
                timer.start()
            }
        }

        Timer {
            id: timer

            property string button: ""

            running: root.buttonDown != "" && root.holdEnabled
            interval: root.holdInterval
            repeat: true

            onTriggered: {
                if (mouse.pressed) {
                    root.held(button)
                }
            }

        }

    }
}

