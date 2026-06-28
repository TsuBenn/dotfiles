pragma ComponentBehavior: Bound

import qs.config 
import qs.services 

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property real w
    property real h

    property bool grid: false
    property bool whole: true

    property bool alignTop: false

    property color color: "white"
    property color color2: "lightgray"

    implicitWidth: Cell.w(Math.ceil(w))
    implicitHeight: Cell.h(Math.ceil(h))

    onWChanged: {
        if (w < 0) {
            w = 0
        }
    }
    onHChanged: {
        if (h < 0) {
            h = 0
        }
    }

    Loader {

        active: (root.visible || !root.optimizeMemory) && (root.color != "transparent" || root.grid)

        sourceComponent: Rectangle {

            y: root.alignTop ? 0 : root.implicitHeight - implicitHeight

            implicitWidth: Cell.w(root.w)
            implicitHeight: Cell.h(root.h)

            color: root.color

            Loader {

                active: root.grid

                sourceComponent: Canvas {

                    implicitWidth: Cell.w(root.w)
                    implicitHeight: Cell.h(root.h)

                    onPaint: {
                        var ctx = getContext("2d")
                        let cw = Cell.w(1)
                        let ch = Cell.h(1)

                        // Cache the lengths to avoid calling functions every iteration
                        let wLimit = implicitWidth 
                        let hLimit = implicitHeight

                        for (let i = 0; i < wLimit; i += cw) {
                            for (let j = 0; j < hLimit; j += ch) { // Fixed: j < height and j += ch

                                // Logic: (col_index + row_index) % 2
                                let col = Math.floor(i / cw)
                                let row = Math.floor(j / ch)

                                ctx.fillStyle = (col + row) % 2 === 0 ? root.color : root.color2
                                ctx.fillRect(i, j, cw, ch)
                            }
                        }
                    }
                }

            }

        }

    }


}
