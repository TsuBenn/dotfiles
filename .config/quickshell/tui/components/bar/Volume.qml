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

        w: state ? text_based.w : Cell.wCount(slider_based.implicitWidth)
        h: 1

        property bool state: true

        color: Colors.bgOverlay

        CellText {

            id: text_based

            visible: volume.state

            text: ` ${AudioInfo.mute ? "MUTED" : root.getDynamicVolumeText(AudioInfo.volume)} `
            font: Cell.fontB

            CellProgress {

                w: parent.w
                h: 1

                vertical: false

                percent: AudioInfo.volume

                syncDelay: 200
                adjustOnHold: true
                drag: false
                wheel: !AudioInfo.mute
                interactive: true

                color: "transparent"
                fg: "transparent"

                onAdjusted: (percent) => {
                    AudioInfo.setVolume(AudioInfo.sinkDefault, percent)
                }

                onReleased: (button) => {
                    if (button == "L") {
                        AudioInfo.muteVolume(AudioInfo.sinkDefault)
                    } else if (button == "R") {
                        volume.state = !volume.state
                    }
                }

            }

        }

        RowLayout {

            id: slider_based

            visible: !volume.state

            spacing: 0

            CellButton {

                text: AudioInfo.mute ? "MUTED" : "VOL"

                font: Cell.fontB

                fg: Colors.fgBase
                color: Colors.bgOverlay

                onReleased: (button) => {
                    if (button == "R") {
                        volume.state = !volume.state
                    }
                    else if (button == "L") {
                        AudioInfo.muteVolume(AudioInfo.sinkDefault)
                    }
                }

            }

            CellProgress {

                w: 10
                h: 1

                vertical: false

                percent: AudioInfo.volume

                syncDelay: 200
                adjustOnHold: true
                wheel: !AudioInfo.mute
                interactive: true

                onAdjusted: (percent) => {
                    AudioInfo.setVolume(AudioInfo.sinkDefault, percent)
                }

                onReleased: (button) => {
                    if (button != "L") return
                    AudioInfo.muteVolume(AudioInfo.sinkDefault)
                }

            }
        }

    }

}
