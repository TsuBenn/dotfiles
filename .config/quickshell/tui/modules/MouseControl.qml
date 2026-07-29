import QtQuick

Item {
    id: root

    signal pressed(button: string, event: MouseEvent)
    signal released(button: string, event: MouseEvent)
    signal entered
    signal exited
    signal wheel(delta: int, event: WheelEvent)
    signal wheelWithButton(button: string, delta: int, event: WheelEvent)
    signal held(button: string)
    signal moved(x: real, y: real, event: MouseEvent)

    property string buttonDown: ""
    property bool hovered: mouse.containsMouse

    property bool hoverEnabled: true

    property bool holdEnabled: false
    property int holdInterval: 100
    property int holdOffset: 0

    property int mouseX: mouse.mouseX
    property int mouseY: mouse.mouseY

    property var acceptedButtons: Qt.AllButtons

    property var propagateComposedEvents: false

    // Control how modifier keys (Shift, Ctrl, Alt) are handled:
    // - acceptModifiers: if false, suppresses modifier prefixes in the button string
    // - ignoreModifiers: if true, ignores input entirely when a modifier key is pressed
    property bool acceptModifiers: true
    property bool ignoreModifiers: false

    // Pass-through control:
    // If true, fires signals as normal but declines event ownership so underlying items receive it
    property bool passThrough: false

    // Helper function to resolve modifier prefix and input key code
    function getButtonString(event) {
        var result = "";

        if (root.acceptModifiers && !root.ignoreModifiers) {
            if (event.modifiers & Qt.ShiftModifier)
                result += "S";
            if (event.modifiers & Qt.ControlModifier)
                result += "C";
            if (event.modifiers & Qt.AltModifier)
                result += "A";
        }

        // Handle MouseEvent buttons
        if (event.button === Qt.LeftButton)
            result += "L";
        else if (event.button === Qt.RightButton)
            result += "R";
        else if (event.button === Qt.MiddleButton)
            result += "M";

        // Handle WheelEvent direction fallback if no explicit button
        if (event.angleDelta !== undefined && event.button === undefined) {
            result += "W";
        }

        return result;
    }

    onVisibleChanged: {
        buttonDown = "";
    }

    MouseArea {
        id: mouse

        anchors.fill: parent

        acceptedButtons: root.acceptedButtons

        // Automatically enable composed event propagation if passThrough is active
        propagateComposedEvents: root.propagateComposedEvents || root.passThrough

        hoverEnabled: root.hoverEnabled

        onWheel: mouseEvent => {
            var hasModifier = (mouseEvent.modifiers & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier)) !== 0;
            if (root.ignoreModifiers && hasModifier) {
                if (root.passThrough)
                    mouseEvent.accepted = false;
                return;
            }

            var delta = mouseEvent.angleDelta.y > 0 ? 1 : -1;
            var buttonStr = root.getButtonString(mouseEvent);

            root.wheel(delta, mouseEvent);
            root.wheelWithButton(buttonStr, delta, mouseEvent);

            if (root.passThrough) {
                mouseEvent.accepted = false;
            }
        }

        onPositionChanged: mouseEvent => {
            root.moved(mouseX, mouseY, mouseEvent);

            if (root.passThrough) {
                mouseEvent.accepted = false;
            }
        }

        onEntered: {
            root.hovered = true;
            root.entered();
        }

        onExited: {
            root.hovered = false;
            root.exited();
        }

        onPressed: event => {
            if (root.holdEnabled)
                timer_offset.start();

            var result = root.getButtonString(event);

            timer.button = result;
            root.buttonDown = result;
            root.pressed(result, event);

            if (root.passThrough) {
                event.accepted = false;
            }
        }

        onPressAndHold: event => {
            if (!root.holdEnabled)
                console.log("MouseControl: \"hold\" is turned off");
        }

        onReleased: event => {
            timer_offset.stop();
            timer.stop();
            timer.button = "";

            var result = root.getButtonString(event);

            root.buttonDown = "";
            root.released(result, event);

            if (root.passThrough) {
                event.accepted = false;
            }
        }

        Timer {
            id: timer_offset

            interval: root.holdOffset

            onTriggered: {
                timer.start();
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
                    root.held(button);
                }
            }
        }
    }
}
