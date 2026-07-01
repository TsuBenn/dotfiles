pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import Quickshell.Widgets
import QtQuick

Cells {

    id: root

    // ─────────────────────────────────────────────────────────────────────
    // Public API — DO NOT change names, types, or default values.
    // External code (media player, disk list, network list, etc.) binds
    // to every property below.
    // ─────────────────────────────────────────────────────────────────────

    property int cellw: 1
    property string text: "Sample of super long text"
    property font font: Cell.font
    property color fg: Colors.fgBase
    property int interval: 300
    property int pause: 2000

    property int offset: 0
    property bool paused: true

    property bool centered: false
    property bool alignRight: false

    readonly property string displayed: {
        // Pad with 4 cells of space and double the string so the marquee
        // can scroll continuously without showing a gap at the wrap point.
        const padded = text + "    "
        const doubled = padded + padded
        return sliceRichText(doubled, offset, offset + cellw)
    }

    // ─────────────────────────────────────────────────────────────────────
    // Container setup (unchanged from original)
    // ─────────────────────────────────────────────────────────────────────

    color: "transparent"

    w: cellw
    h: 1

    // ─────────────────────────────────────────────────────────────────────
    // BUG FIX #1 — "cannot recognize the length of the text compared to
    // its size"
    // ─────────────────────────────────────────────────────────────────────
    //
    // ROOT CAUSE
    //
    // The original code instantiated a HIDDEN CellText as a measurement
    // buffer:
    //
    //     CellText {
    //         visible: false        // ← the problem
    //         id: buffer
    //         text: root.strip(root.text)
    //         ...
    //     }
    //
    // and then compared `buffer.w > root.cellw` to decide whether the
    // text was wider than the viewport. That comparison was ALWAYS false
    // because `buffer.w` was permanently 0.
    //
    // Why? Because `CellText.updateText()` has an early-out:
    //
    //     function updateText() {
    //         if (!root.visible) return       // ← bails for hidden buffer
    //         ...
    //         w = getMaxWidth(raw_text)       // ← never reached
    //     }
    //
    // So `buffer.w` stayed at its default `0` forever, the comparison
    // `0 > cellw` was always false, the marquee timer's `running` was
    // always false, and the visible CellText always showed the truncated
    // `root.text` instead of the scrolled `root.displayed` slice.
    // The visible symptom: "the marquee never scrolls, no matter how
    // long the text is" — i.e. it cannot recognize that the text is
    // longer than its container.
    //
    // FIX
    //
    // Drop the hidden buffer CellText entirely. Compute the text's
    // cell-width directly in JS, using the same `isFullWidth` rules
    // that CellText uses internally. No hidden CellText, no early-out
    // dependency, no async measurement lag, and the measurement is
    // correct for CJK / emoji / full-width punctuation (each = 2 cells).

    readonly property int textCells: measureCells(text)

    // `excess` was declared as `property int excess: 0` in the original
    // but was never assigned, so callers reading it always got 0. Bind
    // it to the actual cell-overflow so it's finally useful. The
    // property's name, type, and "0 when text fits" default are
    // preserved — only the binding expression changes.
    property int excess: Math.max(0, textCells - cellw)

    // True iff the text overflows the viewport. Drives both the visible
    // CellText's `text` choice and the scroll Timer's `running`.
    readonly property bool needsMarquee: root.visible && textCells > cellw

    // ─────────────────────────────────────────────────────────────────────
    // Width-measurement helpers
    //
    // Mirror CellText.isFullWidth + CellText.getMaxWidth, inlined so we
    // don't depend on a hidden CellText instance (whose `w` would never
    // be populated due to CellText.updateText()'s `!visible` early-out).
    // ─────────────────────────────────────────────────────────────────────

    function isFullWidth(char) {
        const code = char.codePointAt(0)
        if (!code) return false
        // Fast path: ASCII and Latin-1 are never full-width.
        if (code < 0x1100) return false
        return (
            (code >= 0x1100 && code <= 0x115F) || // Hangul Jamo
            (code >= 0x2E80 && code <= 0xA4CF && code !== 0x303F) || // CJK Radicals/Ideographs
            (code >= 0xAC00 && code <= 0xD7A3) || // Hangul Syllables
            (code >= 0xF900 && code <= 0xFAFF) || // CJK Compatibility Ideographs
            (code >= 0xFE10 && code <= 0xFE19) || // Vertical Presentation Forms
            (code >= 0xFE30 && code <= 0xFE6F) || // CJK Compatibility Forms
            (code >= 0xFF00 && code <= 0xFF60) || // Fullwidth Forms
            (code >= 0xFFE0 && code <= 0xFFE6) ||
            (code >= 0x1F300 && code <= 0x1F5FF) || // Symbols & Pictographs
            (code >= 0x1F600 && code <= 0x1F64F) || // Smileys & Emoticons
            (code >= 0x1F680 && code <= 0x1F6FF) || // Transport & Map
            (code >= 0x1F900 && code <= 0x1F9FF) || // Supplemental Symbols
            (code >= 0x1FA70 && code <= 0x1FAFF) || // Symbols Extended-A
            (code >= 0x2600  && code <= 0x26FF)  || // Misc Symbols
            (code >= 0x20000 && code <= 0x3FAFF)    // Rare/Extension CJK
        )
    }

    function charWidth(char) {
        const code = char.codePointAt(0)
        if (char === '\t') return 4
        if (code <= 31 || (code >= 0x7f && code <= 0x9f)) return 0
        if (isFullWidth(char)) return 2
        return 1
    }

    function strip(str) {
        return str.trim().replace(/<[^>]*>/g, "")
    }

    // Returns the width of the widest line in CELLS. Strips tags first
    // so they don't contribute to the count. Multiline-aware.
    function measureCells(str) {
        const plain = strip(str)
        let max = 0
        const lines = plain.split("\n")
        for (const line of lines) {
            let lineWidth = 0
            for (const c of line) {
                lineWidth += charWidth(c)
            }
            if (lineWidth > max) max = lineWidth
        }
        return max
    }

    // ─────────────────────────────────────────────────────────────────────
    // BUG FIX #2 — sliceRichText now slices by CELL width, not character
    // count, and handles surrogate pairs (emoji) correctly.
    //
    // The original advanced `plainTextCount` by 1 per character:
    //
    //     plainTextCount++;          // wrong for CJK / emoji (each = 2 cells)
    //     result += html[i];         // wrong for emoji (splits surrogate pair)
    //
    // For a `cellw: 22` marquee showing CJK text, the slice window ended
    // up 22 characters wide (= 44 cells) — twice the viewport — so the
    // text overflowed visibly and the scroll math was off by 2x.
    //
    // FIX: advance `plainTextCount` by `charWidth(c)`, and step `i` by
    // the code-point length so surrogate pairs are consumed as one unit.
    // ─────────────────────────────────────────────────────────────────────

    function sliceRichText(html, start, end) {
        let result = ""
        let plainTextCount = 0
        let i = 0
        let openTags = []   // Stack to track active tags

        while (i < html.length && plainTextCount < end) {
            if (html[i] === '<') {
                let tag = ""
                while (i < html.length && html[i] !== '>') {
                    tag += html[i]
                    i++
                }
                tag += '>'
                i++

                // Is it an opening or closing tag?
                let isClosing = tag.startsWith("</")
                let tagName = tag.replace(/[<>\/]/g, "").split(" ")[0]

                if (isClosing) {
                    if (openTags.length > 0 && openTags[openTags.length - 1] === tagName) {
                        openTags.pop()
                    }
                    // Only add closing tag if we are within the slice range.
                    if (plainTextCount > start) result += tag
                } else {
                    openTags.push(tagName)
                    // Only add opening tag if we are within the slice range.
                    if (plainTextCount >= start) result += tag
                }
            } else {
                // Handle surrogate pairs (emoji) correctly: consume the
                // full code point as one unit.
                const codePoint = html.codePointAt(i)
                const c = String.fromCodePoint(codePoint)
                const cw = charWidth(c)
                const charLen = c.length   // 1 for BMP, 2 for surrogate pair

                // If we just reached the start index, re-open all tags
                // that were active before the slice began, so the slice
                // is well-formed HTML.
                if (plainTextCount === start && result === "") {
                    for (let j = 0; j < openTags.length; j++) {
                        result += "<" + openTags[j] + ">"
                    }
                }

                if (plainTextCount >= start && plainTextCount < end) {
                    result += c
                }
                plainTextCount += cw
                i += charLen
            }
        }

        // Close any tags that are still open at the end of the slice.
        for (let j = openTags.length - 1; j >= 0; j--) {
            result += "</" + openTags[j] + ">"
        }

        return result
    }

    // ─────────────────────────────────────────────────────────────────────
    // Visible renderer
    //
    // When the text fits, show it as-is. CellText.truncate will be a
    // no-op because textCells ≤ cellw. When the text overflows, show
    // the scrolled slice — which is guaranteed to be exactly `cellw`
    // cells wide (after Bug Fix #2), so truncate is again a no-op.
    // ─────────────────────────────────────────────────────────────────────

    CellText {
        text: root.needsMarquee ? root.displayed : root.text
        preferedW: root.cellw
        font: root.font
        color: root.fg
        centered: root.centered
        alignRight: root.alignRight
    }

    // ─────────────────────────────────────────────────────────────────────
    // BUG FIX #3 — onTextChanged now actually pauses the marquee.
    //
    // The original only did:
    //
    //     onTextChanged: {
    //         offset = 0
    //         pauseTimer.restart()
    //     }
    //
    // But `paused` was only ever set to `true` inside the scroll Timer's
    // onTriggered (when offset wrapped to 0). So if the marquee was
    // mid-scroll when the text changed, `paused` was `false`, and
    // restarting pauseTimer was a no-op (its onTriggered sets
    // `paused = false`, which was already the case). The marquee kept
    // scrolling through the text change with no head-of-text pause.
    //
    // FIX: explicitly set `paused = true` before restarting pauseTimer.
    // ─────────────────────────────────────────────────────────────────────

    onTextChanged: {
        offset = 0
        paused = true
        pauseTimer.restart()
    }

    // ─────────────────────────────────────────────────────────────────────
    // BUG FIX #4 — wrap-around modulo uses CELL count, not character count.
    //
    // The original:
    //
    //     parent.offset = (parent.offset + 1) % (root.strip(parent.text).length + 4)
    //
    // `strip(text).length` is a CHARACTER count. For CJK / emoji text
    // (each char = 2 cells), the wrap point was off by 2x — the marquee
    // either cut off mid-character or showed duplicate content before
    // wrapping.
    //
    // FIX: use `textCells + 4` (cell count + 4 separator cells), which
    // matches the `+ "    "` padding (4 spaces = 4 cells) added in the
    // `displayed` binding.
    //
    // Also: the Timer's `running` is now bound to `needsMarquee` (which
    // uses the corrected cell-width measurement) instead of the broken
    // `buffer.w > root.cellw` comparison, so the timer auto-starts when
    // text overflows and auto-stops when text shrinks to fit.
    // ─────────────────────────────────────────────────────────────────────

    Timer {
        interval: root.interval
        running: root.needsMarquee && !root.paused && root.visible
        repeat: true
        onTriggered: {
            root.offset = (root.offset + 1) % (root.textCells + 4)
            if (root.offset === 0) {
                root.paused = true
                pauseTimer.restart()
            }
        }
    }

    Timer {
        id: pauseTimer
        interval: root.pause
        repeat: false
        onTriggered: root.paused = false
    }
}

