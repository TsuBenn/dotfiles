import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Cells {

    id: root

    w: Cell.wCount(volume.implicitWidth)
    h: 1

    color: "transparent"

    function getDynamicVolumeText(percentage) {
        const text = "VOLUME";
        const len = text.length;

        const p = Math.min(100, Math.max(0, percentage));

        if (p <= 50) {
            const count = Math.round((p / 50) * len);
            return text.slice(0, count).toLowerCase() + "-".repeat(len - count);
        } else {
            const count = Math.round(((p - 50) / 50) * len);
            return text.slice(0, count).toUpperCase() + text.slice(count).toLowerCase();
        }
    }

    Cells {
        id: volume

        w: children[1].w
        h: 1

        color: Colors.bgOverlay

        CellText {

            text: ` ${root.getDynamicVolumeText(AudioInfo.volume)} `
            font: Cell.fontB

            CellProgress {

                w: parent.w
                h: 1

                vertical: false

                percent: AudioInfo.volume

                syncDelay: 200
                adjustOnHold: true
                drag: false

                color: "transparent"
                fg: "transparent"

                onAdjusted: (percent) => {
                    AudioInfo.setVolume(AudioInfo.sinkDefault, percent)
                }

            }

        }

    }

}
