pragma ComponentBehavior: Bound

import qs.config
import qs.services

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property string text: "cell text"
    property string raw_text: text
    property font font: Cell.font
    property color color: Colors.fgBase
    property color bg: "transparent"

    property bool centered: false
    property bool wrap: false

    property bool overflowed: false

    component Type: Item {
        override property bool enabled: true
        property color color: Colors.secondary
        property font font: Cell.font
    }

    property Type scroll: Type {}

    property int offset: 0

    property int preferedW: 0
    property int preferedH: 0

    property int w: 0
    property int h: 0
    property int realH: 0

    property bool debug: false

    Component.onCompleted: {
        updateText()
    }

    // Trigger this whenever the text changes
    onTextChanged: {
        updateText()
    }

    onOffsetChanged: {
        updateText()
    }

    function updateText() {
        raw_text = text
        if (wrap && preferedW > 0) {
            // We use a temporary variable to prevent infinite loops
            let wrapped = wrapText(text, preferedW);
            if (text !== wrapped) raw_text = wrapped; 
        }

        let buff_h = raw_text.split("\n").length
        root.realH = buff_h

        if (wrap && preferedH > 0 && preferedW > 0 && buff_h > preferedH) {
            overflowed = true
            let wrapped = wrapText(text, preferedW-2);
            if (text !== wrapped) raw_text = wrapped; 

            let lines = raw_text.split("\n")
            lines = lines.slice(offset,offset + preferedH)
            lines = lines.map(item => item == "" ? " " : item)
            raw_text = lines.join("\n")
        } else {
            overflowed = false
        }

        // Now update the actual dimensions
        w = calculateRequiredWidth();
        h = preferedH > 0 ? preferedH : raw_text.split("\n").length;
    }

    function getCharWidth(char) {
        // Basic wide-char detection (CJK, fullwidth, etc.)
        return /[\u4e00-\u9fff\u3040-\u30ff\u31f0-\u31ff\uff00-\uffef]/.test(char)
        ? 2
        : 1;
    }

    function calculateRequiredWidth() {
        if (preferedW > 0) return preferedW;

        let maxW = 0;
        const lines = text.split("\n");
        for (const line of lines) {
            let lineWidth = 0;
            const segments = splitCJK(line);
            for (const segment of segments) {
                lineWidth += segment.cells;
            }
            if (lineWidth > maxW) maxW = lineWidth;
        }
        return maxW;
    }


    function getStringWidth(str) {
        let width = 0;
        for (const ch of str) {
            width += getCharWidth(ch);
        }
        return width;
    }

    function wrapText(text, maxWidth) {
        const lines = text.split('\n');
        const wrapped = [];

        // Basic unicode width check
        function charWidth(char) {
            const code = char.codePointAt(0);

            // Tabs = 4 spaces
            if (char === '\t') return 4;

            // Control chars
            if (code <= 31 || (code >= 0x7f && code <= 0x9f)) {
                return 0;
            }

            // Wide chars (CJK, emoji, etc.)
            if (
                code >= 0x1100 &&
                (
                    code <= 0x115f ||
                    code === 0x2329 ||
                    code === 0x232a ||
                    (code >= 0x2e80 && code <= 0xa4cf) ||
                    (code >= 0xac00 && code <= 0xd7a3) ||
                    (code >= 0xf900 && code <= 0xfaff) ||
                    (code >= 0xfe10 && code <= 0xfe19) ||
                    (code >= 0xfe30 && code <= 0xfe6f) ||
                    (code >= 0xff00 && code <= 0xff60) ||
                    (code >= 0xffe0 && code <= 0xffe6) ||
                    (code >= 0x1f300 && code <= 0x1faff)
                )
            ) {
                return 2;
            }

            return 1;
        }

        function stringWidth(str) {
            let width = 0;
            for (const char of str) {
                width += charWidth(char);
            }
            return width;
        }

        // Split while preserving spaces
        function tokenize(line) {
            return line.match(/\s+|\S+/g) || [];
        }

        // Break very long tokens (paths, URLs, etc.)
        function breakLongToken(token, maxWidth) {
            const parts = [];
            let current = '';
            let width = 0;

            for (const char of token) {
                const w = charWidth(char);

                if (width + w > maxWidth) {
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

        for (const originalLine of lines) {
            // Preserve fully empty lines
            if (originalLine.length === 0) {
                wrapped.push('');
                continue;
            }

            const tokens = tokenize(originalLine);

            let current = '';
            let currentWidth = 0;

            for (const token of tokens) {
                const tokenWidth = stringWidth(token);

                // Handle huge token
                if (tokenWidth > maxWidth) {
                    // Flush current line first
                    if (current) {
                        wrapped.push(current);
                        current = '';
                        currentWidth = 0;
                    }

                    const broken = breakLongToken(token, maxWidth);

                    for (let i = 0; i < broken.length; i++) {
                        const part = broken[i];

                        if (i === broken.length - 1) {
                            current = part;
                            currentWidth = stringWidth(part);
                        } else {
                            wrapped.push(part);
                        }
                    }

                    continue;
                }

                // Normal wrapping
                if (currentWidth + tokenWidth > maxWidth) {
                    wrapped.push(current);

                    // Remove ONLY leading spaces caused by wrapping
                    current = token.replace(/^\s+/, '');
                    currentWidth = stringWidth(current);
                } else {
                    current += token;
                    currentWidth += tokenWidth;
                }
            }

            wrapped.push(current);
        }

        return wrapped.join('\n');
    }

    implicitHeight: Cell.h(h)
    implicitWidth: Cell.w(w)

    function encodeRichText(str) {
        const map = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': "&quot;",
            "'": "&#39;"
        };

        return str
        .split(/(<[^>]+>)/g) // split into [text, tag, text, tag...]
        .map(part => {
            if (part.startsWith("<") && part.endsWith(">")) {
                return part; // keep tags untouched
            }
            return part.replace(/[&<>"']/g, char => map[char]);
        })
        .join("");
    }

    function decodeRichText(str) {
        return str
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&amp;/g, "&")
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'");
    }

    function truncate(str, maxCells) {
        if (maxCells <= 0) return str

        let placeholder = decodeRichText(str.replace(/<[^>]*>/g, (match) => "\uffff".repeat(match.length)))

        let overflowed = str.length > maxCells
        let result = ""
        let cells = []
        let count = 0
        let excess = 0
        let ellipses = ""

        for (const c of placeholder) {
            const isNone = /[\uffff]/.test(c)
            const costs = (isNone ? 0 : getCharWidth(c))
            cells.push(costs)
        }
        for (const i in cells) {
            count += cells[i]
            if (count > maxCells) {
                if (count - maxCells < cells[i]) {
                    result = str.slice(0, i) + "…"
                    break
                }
                if (overflowed) {
                    for (let k = 1; k < cells[i-1]; k++) {
                        ellipses += " "
                    }
                    result = str.slice(0, i-1) + ellipses + "…"
                    break
                }
                result = str.slice(0, i)
                break
            }
            result = str
        }

        return result
    }

    function splitCJK(str) {
        str = encodeRichText(str)
        let result = []
        let i = 0
        while (i < str.length) {
            const ch = str[i]
            if (/[\u4e00-\u9fff\u3040-\u30ff\u31f0-\u31ff\uff00-\uffef]/.test(ch)) {
                let cjk = ""
                while (i < str.length && /[\u4e00-\u9fff\u3040-\u30ff\u31f0-\u31ff\uff00-\uffef]/.test(str[i])) {
                    cjk += str[i]
                    i++
                }
                result.push({
                    text: `<span style="font-size:${Cell.cellWidth*2}px;font-family:'Noto Sans Mono CJK JP';">${cjk}</span>`,
                    raw: cjk,
                    count: cjk.length,
                    cells: cjk.length * 2,
                    isCJK: true
                })
            } else if ((/[\u2800-\u28ff]/.test(ch))) {
                let braille = ""
                while (i < str.length && /[\u2800-\u28ff]/.test(str[i])) {
                    braille += str[i]
                    i++
                }
                result.push({
                    text: `<span style="font-family:'Noto Sans Symbols 2';">${braille}</span>`,
                    raw: braille,
                    count: braille.length,
                    cells: braille.length,
                    isCJK: true
                })
            } else {
                let latin = ""
                while (i < str.length && !/[\u4e00-\u9fff\u3040-\u30ff\u31f0-\u31ff\uff00-\uffef]/.test(str[i])) {
                    latin += str[i]
                    i++
                }
                result.push({
                    text: latin.replace(/ /g, "&nbsp;"),
                    raw: latin,
                    count: decodeRichText(latin.replace(/<[^>]*>/g,"")).length,
                    cells: decodeRichText(latin.replace(/<[^>]*>/g,"")).length,
                    isCJK: false
                })
            }
        }
        return result
    }

    Loader {

        active: root.visible || !SettingsInfo.optimizeMemory

        sourceComponent: Cells {

            w: root.w
            h: root.h

            color: "transparent"

            ColumnLayout {

                id: cell_text

                spacing: 0

                Repeater {

                    model: root.raw_text.split("\n")

                    delegate: RowLayout {

                        Layout.leftMargin: root.centered ? Cell.centerWCell(implicitWidth, Cell.w(root.w)) : 0

                        id: cell_row

                        required property int index
                        required property string modelData

                        spacing: 0

                        Repeater {

                            model: root.preferedW > 0 
                            ? root.splitCJK(root.truncate(parent.modelData, root.preferedW)) 
                            : root.splitCJK(parent.modelData)

                            delegate: Cells {

                                id: text_cell

                                required property string text
                                required property int cells
                                required property bool isCJK

                                clip: root.clip

                                h: 1
                                w: cells

                                whole: true

                                color: root.bg

                                Text {

                                    anchors.centerIn: !text_cell.isCJK ? undefined : parent

                                    anchors.left: !text_cell.isCJK ? text_cell.left : undefined
                                    anchors.top: !text_cell.isCJK ? text_cell.top : undefined

                                    anchors.topMargin: !text_cell.isCJK ? -(Cell.cellHeight/0.9)*0.05 : undefined

                                    id: texts
                                    textFormat: Text.RichText
                                    text: text_cell.text
                                    font: root.font
                                    color: root.color

                                }
                            }

                        }

                    }
                }
            }

            Text {

                visible: root.overflowed && root.scroll.enabled

                x: Cell.w(root.preferedW-1)

                text: {
                    if (root.preferedH > 1) {
                        return (root.offset > 0 ? "↑" : "-") + "\n".repeat(preferedH-1) + (root.offset < preferedH-1 ? "↓" : "-")
                    } else {
                        if (root.offset == 0) {
                            return "↓"
                        } else if (root.offset == preferedH-1) {
                            return "↑"
                        } else {
                            return "↕"
                        }
                    }
                }

                font: root.font
                color: root.scroll.color
                renderType: Text.CurveRendering

            }

            MouseControl {

                anchors.fill: parent

                onWheel: (delta) => {
                    offset = Math.min(Math.max(root.offset - delta,0),root.realH-root.preferedH-1)
                }

            }

        }
    }

}
