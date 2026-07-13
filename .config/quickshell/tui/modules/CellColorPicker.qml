pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

// =============================================================================
// CellColorPicker
// =============================================================================
// A self-contained TUI-styled HSV color picker rendered as a grid of cells.
//
// Public API
// ---------
//   key         : string   – palette entry currently being edited ("bgSurface",
//                             "fgBase", …). Empty when the picker is closed.
//   sourceColor : color    – original color from the source palette, shown in
//                             the left swatch so the user can compare.
//   buffer      : color    – currently-edited color. Mutated by user
//                             interaction (SV square, sliders, HEX/RGB fields).
//                             The picker owns this value; parents should read
//                             it back via the `applied` signal.
//   h           : int      – height in cells (default 28, matches ColorPopup).
//
//   signal applied(string key, string value)
//                            – emitted whenever `buffer` changes. Parents
//                             should forward this to their own `setBuffer`
//                             so the edit buffer / preview stay in sync.
//
// Notes
// -----
//   * The SV canvas only depends on hue, so it only repaints when hue
//     actually changes – not on every buffer mutation.
//   * Tab navigation between fields uses `Keys.onTabPressed` instead of
//     overriding `Keys.onPressed`, so typing in the HEX/RGB fields keeps
//     working (this was a bug in the previous inline version).
//   * Saturation/value slider gradients track the current hue so they stay
//     contextually accurate.
// =============================================================================

Cells {
    id: root

    // ---- Public API --------------------------------------------------------
    property string key: ""
    property color sourceColor: "black"
    property color buffer: "black"

    signal applied(string key, string value)

    // ---- Sizing ------------------------------------------------------------
    w: 36
    h: 28
    color: "transparent"

    // ---- Internal: buffer normalization + upstream propagation ------------
    // Qt returns hsvHue = -1 for achromatic colors; pin it to 0 so the SV
    // canvas and hue slider render a real gradient instead of garbage.
    onBufferChanged: {
        if (buffer.hsvHue < 0)
            buffer.hsvHue = 0;
        applied(key, buffer.toString());
    }

    // The SV square's appearance only depends on hue. Tracking hue on its
    // own lets us request a repaint *only* when hue actually changes,
    // instead of on every saturation/value tweak during SV-square drag.
    property real _trackedHue: buffer.hsvHue
    on_TrackedHueChanged: sv_square.requestPaint()

    // ---- Internal: clamp a 0–100 percent to a 0–1 real --------------------
    function _clamp01(percent: real): real {
        return Math.max(Math.min(percent, 100), 0).toFixed(1) / 100;
    }

    // =========================================================================
    // Layout
    // =========================================================================

    ColumnLayout {
        y: Cell.h(0)
        spacing: Cell.h(0)

        // --- Source vs. buffer comparison swatches --------------------------
        RowLayout {
            Layout.leftMargin: Cell.w(3)
            spacing: 0

            Cells {
                w: 15
                h: 1.5
                color: root.sourceColor
            }
            Cells {
                w: 15
                h: 1.5
                color: root.buffer
            }
        }

        CellText {
            text: " "
        }

        // --- Saturation / Value picker canvas -------------------------------
        Canvas {
            id: sv_square

            Layout.leftMargin: Cell.w(3)
            implicitWidth: Cell.w(30)
            implicitHeight: Cell.h(15)

            onPaint: {
                var ctx = getContext("2d");
                const cw = Cell.w(1);
                const ch = Cell.h(1);
                const w = implicitWidth;
                const h = implicitHeight;
                const hue = root.buffer.hsvHue;

                // Cache the saturation divisor so we don't re-evaluate it
                // 450 times per paint (30 cols × 15 rows).
                const wDenom = w - cw;
                const hDenom = h - ch;

                for (let i = 0; i < w; i += cw) {
                    const sat = i / wDenom;
                    for (let j = 0; j < h; j += ch) {
                        const val = 1 - j / hDenom;
                        ctx.fillStyle = Qt.hsva(hue, sat, val, 1);
                        ctx.fillRect(i, j, cw, ch);
                    }
                }
            }

            // Current-position marker (X). Color is inverted from the
            // underlying cell so it stays visible on both bright and dark
            // regions of the SV square.
            CellText {
                x: Cell.w(Math.round(root.buffer.hsvSaturation * 29))
                y: Cell.h(Math.round((1 - root.buffer.hsvValue) * 14))

                text: "✕"
                color: Qt.hsva(root.buffer.hsvHue, (1 - root.buffer.hsvSaturation) * 0.8, root.buffer.hsvValue > 0.5 ? 0 : 1, 1)
                font: Cell.fontBB
            }

            Timer {
                id: delay_set_color
                onRunningChanged: {
                    mouse.setColor();
                }
                interval: SettingsInfo.frameTime
            }

            MouseControl {
                id: mouse

                anchors.fill: parent

                function setColor() {
                    if (buttonDown != "L" || delay_set_color.running)
                        return;
                    delay_set_color.restart();
                    const w = parent.implicitWidth - Cell.w(0.5);
                    const h = parent.implicitHeight - Cell.h(0.5);
                    root.buffer.hsvSaturation = Math.max(Math.min(mouseX / w, 1), 0);
                    root.buffer.hsvValue = Math.max(Math.min(1 - mouseY / h, 1), 0);
                }
                onPressed: setColor()
                onMoved: setColor()
                onReleased: setColor()
            }
        }

        CellText {
            text: " "
        }

        CellSeparator {
            w: root.w
            color: Colors.accentDim
        }

        // --- HSV sliders ----------------------------------------------------
        ChannelSlider {
            id: slider_hue
            Layout.leftMargin: Cell.centerWCell(implicitWidth, root.implicitWidth)

            channel: "hue"
            value: root.buffer.hsvHue * 100
            knobColor: Qt.hsva(root.buffer.hsvHue, 1, 1, 1)
            placeholder: "Hue"

            onAdjusted: percent => root.buffer.hsvHue = root._clamp01(percent)
            onEntered: percent => root.buffer.hsvHue = root._clamp01(parseFloat(percent))
            onTabbed: {
                slider_hue.unFocus();
                slider_saturation.grabFocus();
            }
        }

        CellSeparator {
            w: root.w
            padding: 1
            color: Colors.bgOverlay
        }

        ChannelSlider {
            id: slider_saturation
            Layout.leftMargin: Cell.centerWCell(implicitWidth, root.implicitWidth)

            channel: "saturation"
            value: root.buffer.hsvSaturation * 100
            knobColor: Qt.hsva(root.buffer.hsvHue, root.buffer.hsvSaturation, 1, 1)
            placeholder: "Sat"

            onAdjusted: percent => root.buffer.hsvSaturation = root._clamp01(percent)
            onEntered: percent => root.buffer.hsvSaturation = root._clamp01(parseFloat(percent))
            onTabbed: {
                slider_saturation.unFocus();
                slider_value.grabFocus();
            }
        }

        CellSeparator {
            w: root.w
            padding: 1
            color: Colors.bgOverlay
        }

        ChannelSlider {
            id: slider_value
            Layout.leftMargin: Cell.centerWCell(implicitWidth, root.implicitWidth)

            channel: "value"
            value: root.buffer.hsvValue * 100
            knobColor: Qt.hsva(0, 0, root.buffer.hsvValue, 1)
            placeholder: "Val"

            onAdjusted: percent => root.buffer.hsvValue = root._clamp01(percent)
            onEntered: percent => root.buffer.hsvValue = root._clamp01(parseFloat(percent))
            onTabbed: {
                slider_value.unFocus();
                slider_hue.grabFocus();
            }
        }

        CellSeparator {
            w: root.w
            padding: 1
            color: Colors.bgOverlay
        }

        // --- HEX / R / G / B text fields ------------------------------------
        RowLayout {
            Layout.leftMargin: Cell.centerWCell(implicitWidth, root.implicitWidth)
            spacing: Cell.w(1)

            CellText {
                text: "HEX"
            }

            DetailField {
                id: hex_field
                w: 8
                placeholder: "#RRGGBB"
                bindText: root.buffer.toString()

                onEntered: input => {
                    if (/^#?([a-fA-F0-9]{3}|[a-fA-F0-9]{6})$/.test(input)) {
                        root.buffer = Qt.color(input.startsWith("#") ? input : "#" + input);
                    }
                }
                onTabbed: {
                    hex_field.unFocus();
                    r_field.grabFocus();
                }
            }

            CellText {
                text: "R"
            }

            DetailField {
                id: r_field
                w: 4
                placeholder: "RRR"
                bindText: Math.round(root.buffer.r * 255)

                onEntered: input => {
                    input = parseInt(input);
                    if (input >= 0 && input <= 255)
                        root.buffer.r = input / 255;
                }
                onTabbed: {
                    r_field.unFocus();
                    g_field.grabFocus();
                }
            }

            CellText {
                text: "G"
            }

            DetailField {
                id: g_field
                w: 4
                placeholder: "GGG"
                bindText: Math.round(root.buffer.g * 255)

                onEntered: input => {
                    input = parseInt(input);
                    if (input >= 0 && input <= 255)
                        root.buffer.g = input / 255;
                }
                onTabbed: {
                    g_field.unFocus();
                    b_field.grabFocus();
                }
            }

            CellText {
                text: "B"
            }

            DetailField {
                id: b_field
                w: 4
                placeholder: "BBB"
                bindText: Math.round(root.buffer.b * 255)

                onEntered: input => {
                    input = parseInt(input);
                    if (input >= 0 && input <= 255)
                        root.buffer.b = input / 255;
                }
                onTabbed: {
                    b_field.unFocus();
                    hex_field.grabFocus();
                }
            }
        }
    }

    // =========================================================================
    // Inline components
    // =========================================================================

    // ---- ChannelSlider -------------------------------------------------------
    //   A single HSV-channel slider. The `channel` property ("hue" |
    //   "saturation" | "value") drives both the gradient that's drawn on the
    //   underlying canvas and (semantically) the type of the field. All three
    //   slider instances share this component.
    // -------------------------------------------------------------------------
    component ChannelSlider: RowLayout {
        id: slider_root

        property string channel: "hue"
        property real value: 0
        property color knobColor: "white"
        property string placeholder: ""

        signal adjusted(percent: real)
        signal entered(percent: real)
        signal tabbed

        function grabFocus() {
            slider_field.grabFocus();
        }
        function unFocus() {
            slider_field.unFocus();
        }

        spacing: Cell.w(2)

        CellProgressSquare {
            id: progress

            w: 25
            h: 1

            percent: slider_root.value

            color: "transparent"
            fg: "transparent"

            percentSmoother: 0
            wheelInterval: 0.1
            interactive: true
            syncDelay: 0

            onAdjusted: percent => {
                slider_root.adjusted(percent);
            }

            property color temp: "#000000"

            Component.onCompleted: {
                root.bufferChanged.connect(() => {
                    if (root.buffer.hsvHue != temp.hsvHue && slider_root.channel == "saturation") {
                        slider_canvas.requestPaint();
                        temp = root.buffer;
                    }
                });
            }

            Canvas {
                id: slider_canvas

                implicitWidth: Cell.w(progress.w)
                implicitHeight: Cell.h(progress.h)

                onPaint: {
                    var ctx = getContext("2d");
                    const cw = Cell.w(1);
                    const w = implicitWidth;
                    const yOff = (Cell.h(1) - cw) / 2;
                    const hue = root.buffer.hsvHue;
                    const sat = root.buffer.hsvSaturation;
                    const wDenom = w - cw;

                    for (let i = 0; i < w; i += cw) {
                        const t = i / wDenom;
                        let c;
                        switch (slider_root.channel) {
                        case "hue":
                            c = Qt.hsva(t, 1, 1, 1);
                            break;
                        case "saturation":
                            c = Qt.hsva(Math.max(hue, 0), t, 1, 1);
                            break;
                        case "value":
                            c = Qt.hsva(0, 0, t, 1);
                            break;
                        default:
                            c = Qt.hsva(t, 1, 1, 1);
                        }
                        ctx.fillStyle = c;
                        ctx.fillRect(i, yOff, cw, cw);
                    }
                }
            }

            // Knob – position binds to `progress.percent` (which is smoothed
            // by the Behavior on CellProgressSquare) so it tracks the slider
            // drag with the same easing as the underlying fill.
            Cells {
                x: Cell.w(Math.round((progress.percent / 100) * (progress.w - 1)))
                w: 1
                h: 1
                color: slider_root.knobColor
            }
        }

        Cells {
            w: 5
            h: 1
            color: Colors.bgOverlay

            CellTextField {
                id: slider_field

                w: parent.w
                h: parent.h

                focusOnVisible: false
                unfocusOnEntered: true
                autoApply: true

                bindText: slider_root.value.toFixed(1)
                placeholder: slider_root.placeholder

                onEntered: input => slider_root.entered(input)

                // Use `onTabPressed` (not `onPressed`) so we don't clobber
                // CellTextField's internal key handling – typing into the
                // field keeps working.
                Keys.onTabPressed: event => {
                    slider_root.tabbed();
                    event.accepted = true;
                }
            }
        }
    }

    // ---- DetailField ---------------------------------------------------------
    //   A small Cells wrapper around a CellTextField, used for the HEX / R /
    //   G / B inputs. Exposes a clean `entered` / `tabbed` signal API so the
    //   parent layout can wire up focus cycling without reaching into the
    //   field's internals.
    // -------------------------------------------------------------------------
    component DetailField: Cells {
        id: detail_root

        w: 8
        h: 1
        color: Colors.bgOverlay

        property string placeholder: ""
        property string bindText: ""

        signal entered(input: string)
        signal tabbed

        function unFocus() {
            detail_field.unFocus();
        }
        function grabFocus() {
            detail_field.grabFocus();
        }

        CellTextField {
            id: detail_field

            w: parent.w
            h: parent.h

            scroll: false
            unfocusOnEntered: true
            focusOnVisible: false
            autoApply: true

            placeholder: detail_root.placeholder
            bindText: detail_root.bindText

            onEntered: input => detail_root.entered(input)

            // See ChannelSlider: `onTabPressed` avoids breaking typing.
            Keys.onTabPressed: event => {
                detail_root.tabbed();
                event.accepted = true;
            }
        }
    }
}
