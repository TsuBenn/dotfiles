pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property int h: 5
    property int w: 5
    property int thumbH: 1
    property int thumbW: 1

    required property int contentH
    property int contentW: contentH // Fallback to contentH if contentW isn't specified

    property bool horizontal: false
    property bool toScale: true
    property bool interactive: true

    component Type: Item {
        property int bg: 0
        property int fg: 0
        property int arrow: 0
    }

    property Type type: Type {
        bg: 0
        fg: 0
        arrow: 0
    }

    implicitWidth: horizontal ? Cell.w(w) : Cell.w(1)
    implicitHeight: horizontal ? Cell.h(1) : Cell.h(h)

    property real progress

    signal adjusted(n: real)

    property color bg: Colors.bgOverlay
    property color color: Colors.fgDim

    // Target dimensions depending on orientation
    readonly property int trackLength: horizontal ? root.w : root.h
    readonly property int totalContentLength: horizontal ? root.contentW : root.contentH

    Cells {
        w: root.horizontal ? root.w : 1
        h: root.horizontal ? 1 : root.h

        color: "transparent"
        clip: true

        GridLayout {
            anchors.fill: parent
            rows: root.horizontal ? 1 : -1
            columns: root.horizontal ? -1 : 1
            rowSpacing: 0
            columnSpacing: 0

            // Decrement Arrow (Up or Left)
            CellText {
                visible: root.type.arrow > 0
                text: {
                    if (root.type.arrow === 1)
                        return root.horizontal ? "←" : "↑";
                    if (root.type.arrow === 2)
                        return root.horizontal ? "◀" : "▲";
                    return "";
                }
                color: root.progress > 0 ? root.color : root.bg
            }

            // Track Container
            Cells {
                id: scroll

                w: root.horizontal ? (root.type.arrow > 0 ? root.w - 2 : root.w) : 1
                h: root.horizontal ? 1 : (root.type.arrow > 0 ? root.h - 2 : root.h)

                color: root.type.bg > -1 ? "transparent" : root.bg

                CellSeparator {
                    vertical: !root.horizontal
                    w: root.horizontal ? scroll.w : 1
                    h: root.horizontal ? 1 : scroll.h
                    type: root.type.bg
                    color: root.bg
                }

                // Scroll Thumb
                Cells {
                    id: thumb

                    visible: root.totalContentLength > root.trackLength

                    // Calculate scaled thumb dimensions
                    readonly property int calculatedThumbLength: Math.min(Math.max(Math.round((root.trackLength / root.totalContentLength) * (root.horizontal ? scroll.w : scroll.h)), 1), root.trackLength)

                    w: root.horizontal ? (root.toScale ? calculatedThumbLength : root.thumbW) : 1
                    h: root.horizontal ? 1 : (root.toScale ? calculatedThumbLength : root.thumbH)

                    Behavior on w {
                        enabled: root.horizontal
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on h {
                        enabled: !root.horizontal
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    property real progress: root.progress * (root.horizontal ? (scroll.w - w) : (scroll.h - h))

                    Behavior on progress {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    x: root.horizontal ? Cell.w(Math.round(progress)) : 0
                    y: root.horizontal ? 0 : Cell.h(Math.round(progress))

                    color: root.type.fg > -1 ? "transparent" : root.color

                    CellSeparator {
                        vertical: !root.horizontal
                        w: parent.w
                        h: parent.h
                        type: root.type.fg
                        color: root.color
                    }
                }
            }

            // Increment Arrow (Down or Right)
            CellText {
                visible: root.type.arrow > 0
                text: {
                    if (root.type.arrow === 1)
                        return root.horizontal ? "→" : "↓";
                    if (root.type.arrow === 2)
                        return root.horizontal ? "▶" : "▼";
                    return "";
                }
                color: root.progress < 1 && root.totalContentLength > root.trackLength ? root.color : root.bg
            }
        }

        MouseControl {
            id: mouse_ctrl

            visible: root.interactive
            anchors.fill: parent

            // Keeps track of where inside the thumb the user clicked
            property real dragOffset: 0
            property bool isDraggingThumb: false

            function updateProgress(mousePos) {
                const thumbSize = root.horizontal ? thumb.width : thumb.height;
                const scrollSize = root.horizontal ? scroll.width : scroll.height;

                // Account for arrow offset if arrows are shown
                const arrowOffset = root.type.arrow > 0 ? Cell.w(1) : 0;
                const posInScroll = mousePos - arrowOffset;

                const maxTravel = scrollSize - thumbSize;
                if (maxTravel <= 0)
                    return;

                let targetThumbPos;

                if (isDraggingThumb) {
                    // Maintain relative grab position on the thumb
                    targetThumbPos = posInScroll - dragOffset;
                } else {
                    // Jump center of thumb to click position on track
                    targetThumbPos = posInScroll - (thumbSize / 2);
                }

                const clampedPos = Math.min(Math.max(targetThumbPos, 0), maxTravel);
                const newProgress = clampedPos / maxTravel;

                root.adjusted(newProgress);
            }

            onPressed: button => {
                if (button === "L") {
                    const mousePos = root.horizontal ? mouseX : mouseY;
                    const arrowOffset = root.type.arrow > 0 ? Cell.w(1) : 0;
                    const posInScroll = mousePos - arrowOffset;

                    const thumbPos = root.horizontal ? thumb.x : thumb.y;
                    const thumbSize = root.horizontal ? thumb.width : thumb.height;

                    // Check if click was inside the thumb bounds
                    if (posInScroll >= thumbPos && posInScroll <= (thumbPos + thumbSize)) {
                        isDraggingThumb = true;
                        dragOffset = posInScroll - thumbPos; // Save where inside the thumb we grabbed
                    } else {
                        isDraggingThumb = false;
                        dragOffset = 0;
                        updateProgress(mousePos); // Track jump
                    }
                }
            }

            onMoved: {
                if (buttonDown === "L") {
                    updateProgress(root.horizontal ? mouseX : mouseY);
                }
            }

            onReleased: {
                isDraggingThumb = false;
            }
        }
    }
}
