import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int w: 50
    property int h: 3

    property int spacing: 0 

    property var color: Colors.fgBase

    property bool flipped: true

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)

    property var pointsFlipped: downSample(Cava.pointsFlipped, root.w/(1+spacing))
    property var points: downSample(Cava.points, root.w/(1+spacing))

    function downSample(list, targetSize) {
        if (targetSize >= list.length) return list; // No need to shrink

        return Array.from({ length: targetSize }, (_, i) => {
            // Determine the "sampling point" in the original array
            const sampleIndex = Math.round(i * (list.length - 1) / (targetSize - 1));
            return list[sampleIndex];
        });  
    }

    onVisibleChanged: {
        if (visible) {
            Cava.requestStart()
        } else {
            Cava.release()
        }
    }

    Cells {

        id: container

        w: root.w
        h: root.h

        color: "transparent"

        RowLayout {

            spacing: Cell.w(root.spacing)

                Repeater {

                    model: root.w

                    delegate: CellProgressSquare {

                        required property int index

                        w: 1
                        h: container.h

                        percent: root.flipped ? root.pointsFlipped[index] ?? 0 : root.points[index] ?? 0
                        percentSmoother: 0

                        vertical: true
                        type: 0
                    }

                }

        }

    }

}
