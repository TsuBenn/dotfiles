import QtQuick

Item {

    id: root

    signal pressed(button : string)
    signal released(button : string)
    signal entered()
    signal exited()
    signal wheel(delta : int)
    signal held(button: string)

    property bool hovered: false
    property bool holdEnabled: false
    property int holdInterval: 100

    MouseArea {

        id: mouse

        anchors.fill: parent

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
            if (root.holdEnabled) timer.running = true
            var result = ""
            if (event.button == Qt.LeftButton) result = "L"
            else if (event.button == Qt.RightButton) result = "R"
            else if (event.button == Qt.MiddleButton) result = "M"
            timer.button = result
            root.pressed(result)
        }
        onPressAndHold: {
            if (!root.holdEnabled) console.log("MouseControl: \"hold\" is turned off")
        }
        onReleased: (event) => {
            timer.running = false
            timer.button = ""
            var result = ""
            if (event.button == Qt.LeftButton) result = "L"
            else if (event.button == Qt.RightButton) result = "R"
            else if (event.button == Qt.MiddleButton) result = "M"
            root.released(result)
        }

        Timer {
            id: timer

            property string button: ""

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

