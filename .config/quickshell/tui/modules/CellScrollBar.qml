pragma ComponentBehavior: Bound 

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int h: 5
    property int thumbH: 1

    required property int contentH

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

    implicitWidth: Cell.w(1)
    implicitHeight: Cell.h(h)

    property real progress

    signal adjusted(n: real)

    property color bg: Colors.bgOverlay
    property color color: Colors.fgDim

    Cells {

        w: 1
        h: root.h

        color: "transparent"

        ColumnLayout {

            spacing: 0

            CellText {
                visible: root.type.arrow > 0
                text: {
                    switch (root.type.arrow) {
                        case 1: return "↑"; 
                        case 2: return "▲"; 
                    }
                }
                color: root.progress > 0 ? root.color : root.bg
            }

            Cells {

                id: scroll

                w: 1
                h: root.type.arrow > 0 ? root.h - 2 : root.h

                color: root.type.bg > 0 ? "transparent" : root.bg

                ColumnLayout {

                    visible: root.type.bg > 0

                    spacing: 0

                    Repeater {

                        model: scroll.h

                        delegate: CellText {

                            text: {
                                switch (root.type.bg) {
                                    case 1: return "│"; 
                                    case 2: return "┃"; 
                                    case 3: return "║"; 
                                }
                            }

                            color: root.bg

                        }

                    }

                }

                Cells {

                    id: thumb

                    visible: root.contentH > root.h

                    w: 1
                    h: root.toScale ? Math.min(Math.round((root.h/root.contentH)*scroll.h),root.h) : root.thumbH

                    y: Cell.h(Math.round(root.progress*(scroll.h-h)))

                    color: root.type.fg > 0 ? "transparent" : root.color

                    ColumnLayout {

                        visible: root.type.fg > 0

                        spacing: 0

                        Repeater {

                            model: thumb.h

                            delegate: CellText {

                                text: {
                                    switch (root.type.fg) {
                                        case 1: return "┃"; 
                                        case 2: return "●"; 
                                    }
                                }

                                color: root.color

                            }

                        }

                    }
                }

            }

            CellText {
                visible: root.type.arrow > 0
                text: {
                    switch (root.type.arrow) {
                        case 1: return "↓"; 
                        case 2: return "▼"; 
                    }
                }
                color: root.progress < 1 && root.contentH > root.h ? root.color : root.bg
            }

        }

        MouseControl {

            visible: root.interactive

            anchors.fill: parent

            onPressed: (button) => {
                if (button == "L") {
                    const progress = Math.min(Math.max(mouseY-thumb.implicitHeight/2,0),scroll.implicitHeight - thumb.implicitHeight)/(scroll.implicitHeight - thumb.implicitHeight)
                    root.adjusted(progress)
                    console.log(progress)
                }
            }
            onMoved: {
                if (buttonDown == "L") {
                    const progress = Math.min(Math.max(mouseY-thumb.implicitHeight/2,0),scroll.implicitHeight - thumb.implicitHeight)/(scroll.implicitHeight - thumb.implicitHeight)
                    console.log(progress)
                    root.adjusted(progress)
                }
            }

        }

    }

}
