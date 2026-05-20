import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property int w: 50
    property int h: 3

    property int spacing: 0 
    property int barW: 1

    property var color: Colors.fgBase

    property bool flipped: true

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)

    property int barCount: (root.w+spacing)/(barW+spacing)

    property var pointsFlipped: downSample(Cava.pointsFlipped, barCount)
    property var points: downSample(Cava.points, barCount)

    function downSample(list, targetSize) {
        if (targetSize >= list.length) return list;
        if (targetSize <= 1) return [list[0]]; // Edge case

        return Array.from({ length: targetSize }, (_, i) => {
            // Calculate the exact fractional position
            const position = i * (list.length - 1) / (targetSize - 1);

            const indexLow = Math.floor(position);
            const indexHigh = Math.ceil(position);
            const weight = position - indexLow; // How far are we toward indexHigh?

            // The "Lerp" formula: (1 - weight) * A + weight * B
            return (1 - weight) * list[indexLow] + weight * list[indexHigh];
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

        function getMultiBlend(colors, percentage) {
            // 1. Handle boundaries
            if (percentage <= 0) return colors[0];
            if (percentage >= 1) return colors[colors.length - 1];

            // 2. Determine which segment we are in
            // With 3 colors, there are 2 segments (0-0.5 and 0.5-1.0)
            let segment = percentage * (colors.length - 1);
            let index = Math.floor(segment);

            // 3. Calculate the percentage within THAT specific segment
            let innerPercent = segment - index;

            // 4. Use your existing blend function
            return Colors.blend(colors[index] ?? Colors.fgBase, colors[index + 1] ?? Colors.fgBase, innerPercent);
        }

        Loader {

            active: root.visible || !root.optimizeMemory

            sourceComponent: RowLayout {

                id: layout

                x: Cell.w(Math.round(root.w/2 - (root.points.length*root.barW + (root.points.length-1)*root.spacing)/2))

                spacing: Cell.w(root.spacing)

                Repeater {

                    model: root.w

                    delegate: Cells {

                        required property int index

                        w: root.barW
                        h: container.h
                        color: "transparent"

                        Cells {

                            anchors.bottom: parent.bottom

                            property real percent: (root.flipped ? root.pointsFlipped[index] ?? 0 : root.points[index] ?? 0)/100

                            w: root.barW
                            h: container.h*(Math.round(percent*(8*container.h))/(8*container.h))
                            whole: false

                            color: {
                                if (Array.isArray(root.color)) {
                                    return container.getMultiBlend(root.color,Math.round(percent*(8*container.h))/(8*container.h))
                                }
                                return root.color
                            }

                        }


                    }

                }

            }
        }


    }

}
