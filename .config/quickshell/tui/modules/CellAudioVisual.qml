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
            return Colors.blend(colors[index], colors[index + 1], innerPercent);
        }

        RowLayout {

            spacing: Cell.w(root.spacing)

            Repeater {

                model: root.w

                delegate: Loader {

                    active: root.visible || !SettingsInfo.optimizeMemory

                    id: loader

                    required property int index

                    sourceComponent: Cells {

                        property int index: loader.index

                        w: 1
                        h: container.h
                        color: "transparent"

                        Cells {

                            anchors.bottom: parent.bottom

                            property real percent: (root.flipped ? root.pointsFlipped[index] ?? 0 : root.points[index] ?? 0)/100

                            w: 1
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
