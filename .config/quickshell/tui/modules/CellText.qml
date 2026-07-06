pragma ComponentBehavior: Bound

import qs.config
import qs.services

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property string text: "cell text"
    property string raw_text: text
    property font font: Cell.font
    property font fontE: Cell.fontE
    property color color: Colors.fgBase
    property color bg: "transparent"

    property bool centered: false
    property bool alignRight: false

    property bool wrap: false

    property bool lockPure: false
    // Set exclusively by updateText() — no binding, so it doesn't get
    // re-evaluated on every text change and then immediately overwritten.
    property bool pure: true

    property int offset: 0

    property int preferedW: 0
    property int preferedH: 0

    property int w: 0
    property int h: 0
    property int realH: 0

    property bool debug: false

    implicitHeight: Cell.h(h)
    implicitWidth: Cell.w(w)

    onVisibleChanged: {
        if (visible) {
            updateText();
        }
    }

    Component.onCompleted: {
        updateText();
    }

    onPreferedWChanged: {
        updateText();
    }

    onTextChanged: {
        updateText();
    }

    // ── Text processing helpers ─────────────────────────────────────────────
    //
    // Hoist leading whitespace inside tags to outside:
    //   "<b>  hello</b>"  →  "  <b>hello</b>"
    //
    // MUST run before richify(), because richify() converts spaces to &nbsp;
    // (the literal text "&nbsp;", not U+00A0) and \s doesn't match that.
    function hoistWhitespace(str) {
        return str.replace(/(<[^>]+>)(\s+)/g, '$2$1');
    }

    function richify(str) {
        const entityMap = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': "&quot;",
            "'": "&#39;"
        };

        // Split the string into an array of [raw_text, tag, raw_text, tag...]
        // The parenthesis inside the regex ensures the matched tags are kept in the split array
        return str.split(/(<\/?[a-zA-Z][^>]*>)/g).map(part => {
            // If this part is a valid HTML tag, pass it through untouched
            if (part.startsWith("<") && part.endsWith(">")) {
                return part;
            }
            // Otherwise, it's raw text—safely convert the problematic characters
            return part.replace(/[&<>"']/g, char => entityMap[char]);
        }).join("").replace(/ /g, "&nbsp;").replace(/\n/g, "<br>");
    }

    function updateText() {
        if (!root.visible)
            return;
        raw_text = text;

        if (!lockPure) {
            pure = onlyLatin(raw_text);
        }

        if (preferedW > 0) {
            if (wrap) {
                raw_text = wrapText(raw_text, preferedW);
            } else {
                const lines = raw_text.split("\n");
                let new_lines = [];
                for (const line of lines) {
                    new_lines.push(truncate(line, preferedW));
                }
                raw_text = new_lines.join("\n");
            }
        }

        w = getMaxWidth(raw_text);

        if (centered) {
            const lines = raw_text.split("\n");
            let new_lines = [];
            for (const line of lines) {
                new_lines.push(" ".repeat(Math.max(Math.floor((w - purify(line.trim()).length) / 2), 0)) + line.trim());
            }
            raw_text = new_lines.join("\n");
        }

        h = preferedH > 0 ? preferedH : raw_text.split("\n").length;

        if (!pure) {
            processed = splitUnpure(raw_text);
        }

        // Order matters: hoist first (on raw spaces), then richify (which
        // converts spaces to &nbsp; and escapes entities).
        raw_text = richify(hoistWhitespace(raw_text));
    }

    // ── Width classification ────────────────────────────────────────────────
    //
    // Fast ASCII reject first — most TUI text is Latin, so this skips all
    // range checks for ~99% of characters.

    function isFullWidth(char) {
        const code = char.codePointAt(0);

        if (!code)
            return false;

        // Fast path: ASCII and Latin-1 are never full-width.
        if (code < 0x1100)
            return false;

        // Code point ranges for Full-width and Wide characters:
        return ((code >= 0x1100 && code <= 0x115F) || // Hangul Jamo
            (code >= 0x2E80 && code <= 0xA4CF && code !== 0x303F) || // CJK Radicals, Symbols, Ideographs
            (code >= 0xAC00 && code <= 0xD7A3) || // Hangul Syllables
            (code >= 0xF900 && code <= 0xFAFF) || // CJK Compatibility Ideographs
            (code >= 0xFE10 && code <= 0xFE19) || // Vertical Presentation Forms
            (code >= 0xFE30 && code <= 0xFE6F) || // CJK Compatibility Forms
            (code >= 0xFF00 && code <= 0xFF60) || // Fullwidth Forms (Letters, Numbers, Punctuation)
            (code >= 0xFFE0 && code <= 0xFFE6) || (code >= 0x1F600 && code <= 0x1F64F) || // Smileys & Emoticons
            (code >= 0x1F300 && code <= 0x1F5FF) || // Misc Symbols & Pictographs
            (code >= 0x1F680 && code <= 0x1F6FF) || // Transport & Map
            (code >= 0x1F900 && code <= 0x1F9FF) || // Supplemental Symbols
            (code >= 0x1FA70 && code <= 0x1FAFF) || // Symbols Extended-A
            (code >= 0x2600 && code <= 0x26FF) || // Misc Symbols (e.g., ☀, ☁, ⛑)
            //(code >= 0x2700  && code <= 0x27BF)  || // Dingbats (e.g., ✂, ✅)

            (code >= 0x20000 && code <= 0x3FAFF)  // Rare/Extension CJK Ideographs
        );
    }

    // Single regex test instead of a per-character loop.
    // Also includes Braille (U+2800–U+28FF) so Braille text routes through
    // the unpure path and gets its 'Noto Sans Symbols 2' font wrap.
    //
    // NOTE: uses \u{XXXXX} (ES6 code point escape) with the /u flag for all
    // supplementary plane code points. \u1F300 would be parsed as \u1F30 + "0",
    // creating a bogus range "0"-\u1F5F that matches all ASCII letters.
    // Qt 6's V8 supports \u{} syntax.
    function onlyLatin(str) {
        const plain = purify(str);
        return !/[\u1100-\u115F\u2E80-\uA4CF\uAC00-\uD7A3\uF900-\uFAFF\uFE10-\uFE19\uFE30-\uFE6F\uFF00-\uFF60\uFFE0-\uFFE6\u{1F300}-\u{1F5FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u2600-\u26FF\u{20000}-\u{3FAFF}\u2800-\u28FF]/u.test(plain);
    }

    function purify(str) {
        return str.replace(/<[^>]*>/g, "");
    }

    // Strips tags once, then measures each line. Avoids the old path
    // where purify ran on the whole string AND on every line via getWidth.
    function getMaxWidth(str) {
        if (preferedW > 0)
            return preferedW;

        let maxW = 0;
        const lines = purify(str).split("\n");
        for (const line of lines) {
            let lineWidth = 0;
            for (const c of line) {
                lineWidth += isFullWidth(c) ? 2 : 1;
            }
            if (lineWidth > maxW)
                maxW = lineWidth;
        }
        return maxW;
    }

    // ── Wrapping ────────────────────────────────────────────────────────────
    //
    // Helpers hoisted to top-level so they're not re-created on every call.

    function _charWidth(char) {
        const code = char.codePointAt(0);

        if (char === '\t')
            return 4;
        if (code <= 31 || (code >= 0x7f && code <= 0x9f))
            return 0;
        if (isFullWidth(char))
            return 2;
        return 1;
    }

    function _stringWidth(str) {
        let width = 0;
        for (const char of str) {
            width += _charWidth(char);
        }
        return width;
    }

    function _tokenize(line) {
        return line.match(/\s+|\S+/g) || [];
    }

    function _breakLongToken(token, maxW) {
        const parts = [];
        let current = '';
        let width = 0;

        for (const char of token) {
            const w = _charWidth(char);

            if (width + w > maxW) {
                parts.push(current);
                current = char;
                width = w;
            } else {
                current += char;
                width += w;
            }
        }

        if (current) {
            parts.push(current);
        }

        return parts;
    }

    function wrapText(text, maxW) {
        // Helper to calculate width without HTML tags
        const getVisualWidth = str => {
            const stripped = str.replace(/<\/?[^>]+(>|$)/g, '');
            return _stringWidth(stripped);
        };

        const lines = text.split('\n');
        const wrapped = [];

        for (const originalLine of lines) {
            if (originalLine.length === 0) {
                wrapped.push('');
                continue;
            }

            const tokens = _tokenize(originalLine);

            let current = '';
            let currentWidth = 0;

            for (const token of tokens) {
                const tokenWidth = getVisualWidth(token);

                // Handle huge token
                if (tokenWidth > maxW) {
                    if (current) {
                        wrapped.push(current);
                        current = '';
                        currentWidth = 0;
                    }

                    const broken = _breakLongToken(token, maxW);

                    for (let i = 0; i < broken.length; i++) {
                        const part = broken[i];

                        if (i === broken.length - 1) {
                            current = part;
                            currentWidth = getVisualWidth(part);
                        } else {
                            wrapped.push(part);
                        }
                    }

                    continue;
                }

                // Normal wrapping
                if (currentWidth + tokenWidth > maxW) {
                    wrapped.push(current);
                    // Remove ONLY leading spaces caused by wrapping, keeping tags intact
                    current = token.replace(/^\s+/, '');
                    currentWidth = getVisualWidth(current);
                } else {
                    current += token;
                    currentWidth += tokenWidth;
                }
            }

            wrapped.push(current);
        }

        return wrapped.join('\n');
    }

    function truncate(str, maxCells) {
        if (maxCells <= 0)
            return str;

        let placeholder = str.replace(/<[^>]*>/g, match => "\uffff".repeat(match.length));

        let overflowed = str.length > maxCells;
        let result = "";
        let cells = [];
        let count = 0;
        let excess = 0;
        let ellipses = "";

        for (const c of placeholder) {
            const isNone = /[\uffff]/.test(c);
            const costs = (isNone ? 0 : (isFullWidth(c) ? 2 : 1));
            cells.push(costs);
        }
        // Use numeric index — for-in iterates string keys, which is slow
        // and fragile (cells[i-1] only works by accident due to coercion).
        for (let i = 0; i < cells.length; i++) {
            count += cells[i];
            if (count > maxCells) {
                if (count - maxCells < cells[i]) {
                    result = str.slice(0, i) + "…";
                    break;
                }
                if (overflowed) {
                    for (let k = 1; k < cells[i - 1]; k++) {
                        ellipses += " ";
                    }
                    result = str.slice(0, i - 1) + ellipses + "…";
                    break;
                }
                result = str.slice(0, i);
                break;
            }
            result = str;
        }

        return result;
    }

    // ── Unpure text segmentation ────────────────────────────────────────────

    function wrapFullWidth(str) {
        return `<span style="font-size:${Cell.cellHeight}px;font-family:'Noto Sans Mono CJK JP';">${str}</span>`;
    }
    function wrapBraille(str) {
        return `<span style="font-size:${Cell.cellHeight}px;font-family:'Noto Sans Symbols 2';">${str}</span>`;
    }

    function splitUnpure(str) {
        let result = [];

        for (const line of str.split("\n")) {
            let processed = [];
            let inFullWidth = false, inEmoji = false, inBraille = false, buffer = "";

            const flush = () => {
                if (!buffer)
                    return;
                if (inFullWidth) {
                    processed.push({
                        text: wrapFullWidth(buffer),
                        len: buffer.length,
                        type: "cjk"
                    });
                } else if (inEmoji) {
                    // BUG FIX: was `${str}` (entire input) — now `${buffer}` (just the emoji run).
                    processed.push({
                        text: `<span style="font-size:${Cell.cellHeight * 1.4}px;font-family:'Apple Color Emoji';">${buffer}</span>`,
                        len: buffer.length / 2,
                        type: "emoji"
                    });
                } else if (inBraille) {
                    processed.push({
                        text: wrapBraille(buffer),
                        len: buffer.length,
                        type: "braille"
                    });
                } else {
                    // Order fix: hoist first (raw spaces), then richify.
                    processed.push({
                        text: richify(hoistWhitespace(buffer)),
                        len: buffer.length,
                        type: "pure"
                    });
                }
                buffer = "";
            };

            for (const c of line) {
                const isBraille = /[\u2800-\u28FF]/.test(c);

                if (c.length === 2) {
                    if (inFullWidth || !inEmoji || inBraille)
                        flush();
                    inFullWidth = false;
                    inEmoji = true;
                    inBraille = false;
                } else if (isBraille) {
                    if (inFullWidth || inEmoji || !inBraille)
                        flush();
                    inFullWidth = false;
                    inEmoji = false;
                    inBraille = true;
                } else if (isFullWidth(c)) {
                    if (inEmoji || !inFullWidth || inBraille)
                        flush();
                    inEmoji = false;
                    inFullWidth = true;
                    inBraille = false;
                } else {
                    if (inEmoji || inFullWidth || inBraille)
                        flush();
                    inEmoji = false;
                    inFullWidth = false;
                    inBraille = false;
                }
                buffer += c;
            }

            flush();
            result.push(processed);
        }

        return result;
    }

    property var processed: []

    Loader {

        active: root.visible || !root.optimizeMemory

        sourceComponent: Cells {
            id: cell_text

            w: root.w
            h: root.h

            color: root.pure ? root.bg : "transparent"

            Loader {

                active: (root.visible || !root.optimizeMemory) && !root.pure

                sourceComponent: ColumnLayout {

                    x: if (root.alignRight) {
                        return cell_text.implicitWidth - implicitWidth;
                    } else {
                        return 0;
                    }

                    spacing: 0

                    Repeater {

                        model: processed

                        delegate: RowLayout {

                            Layout.alignment: root.alignRight ? Qt.AlignRight : Qt.AlignLeft

                            required property int index

                            spacing: 0

                            Repeater {

                                model: processed[parent.index]

                                delegate: Loader {
                                    id: cell_loader

                                    required property string text
                                    required property int len
                                    required property string type

                                    active: root.visible

                                    sourceComponent: Cells {

                                        property string text: cell_loader.text
                                        property int len: cell_loader.len
                                        property string type: cell_loader.type

                                        w: len * (type == "emoji" || type == "cjk" ? 2 : 1)
                                        h: 1

                                        color: root.bg

                                        clip: true

                                        Text {

                                            anchors.centerIn: parent.type == "emoji" || parent.type == "cjk" || parent.type == "braille" ? parent : undefined

                                            anchors.verticalCenterOffset: parent.type == "emoji" ? Cell.cellHeight * 0.05 : 0
                                            anchors.horizontalCenterOffset: parent.type == "emoji" ? Cell.cellWidth * 0.05 : 0

                                            y: -(1 - Cell.cellHeight / Cell.realCellHeight) / 2

                                            textFormat: Text.RichText
                                            text: parent.text
                                            font: parent.type == "emoji" ? root.fontE : root.font
                                            color: root.color
                                            lineHeight: Cell.cellHeight
                                            lineHeightMode: Text.FixedHeight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Loader {

                active: (root.visible || !root.optimizeMemory) && root.pure

                sourceComponent: Text {

                    x: if (root.alignRight) {
                        return cell_text.implicitWidth - implicitWidth;
                    } else {
                        return 0;
                    }

                    y: -(1 - Cell.cellHeight / Cell.realCellHeight) / 2

                    text: root.raw_text
                    textFormat: Text.RichText
                    horizontalAlignment: root.alignRight ? Text.AlignRight : Text.AlignLeft
                    font: root.font
                    color: root.color
                    lineHeight: Cell.cellHeight
                    lineHeightMode: Text.FixedHeight
                }
            }
        }
    }
}
