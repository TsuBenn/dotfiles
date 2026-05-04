pragma ComponentBehavior: Bound

import qs.config
import qs.services

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property string text: "cell text"
    property font font: Cell.font
    property color color: Colors.fgBase
    property color bg: "transparent"

    property bool centered: false
    property bool wrap: false

    property int preferedW: 0

    property int w: 0
    property int h: 0

    Component.onCompleted: {
        if (wrap && preferedW > 0) {
            // We use a temporary variable to prevent infinite loops
            let wrapped = wrapText(text, preferedW);
            if (text !== wrapped) text = wrapped; 
        }

        // Now update the actual dimensions
        w = calculateRequiredWidth();
        h = text.split("\n").length;
    }

    function getCharWidth(char) {
        // Basic wide-char detection (CJK, fullwidth, etc.)
        return /[\u1100-\u115F\u2E80-\uA4CF\uAC00-\uD7A3\uF900-\uFAFF\uFE10-\uFE19\uFE30-\uFE6F\uFF00-\uFF60\uFFE0-\uFFE6]/.test(char)
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


        for (const line of lines) {
            // preserve empty lines
            if (line.length === 0) {
                wrapped.push('');
                continue;
            }

            let current = '';
            let currentWidth = 0;

            // split but KEEP spaces as tokens
            const tokens = line.match(/\S+|\s+/g) || [];

            for (let token of tokens) {
                let tokenWidth = getStringWidth(token);

                // If token itself is longer than maxWidth → hard split
                if (tokenWidth > maxWidth) {
                    for (const ch of token) {
                        const chWidth = getCharWidth(ch);

                        if (currentWidth + chWidth > maxWidth) {
                            wrapped.push(current);
                            current = '';
                            currentWidth = 0;
                        }

                        current += ch;
                        currentWidth += chWidth;
                    }
                    continue;
                }

                // Normal case
                if (currentWidth + tokenWidth > maxWidth) {
                    wrapped.push(current.trim());
                    current = token;
                    currentWidth = tokenWidth;
                } else {
                    current += token;
                    currentWidth += tokenWidth;
                }
            }

            if (current.length > 0) {
                wrapped.push(current.trim());
            }
        }

        return wrapped.join('\n');
    }

    // Trigger this whenever the text changes
    onTextChanged: {
        if (wrap && preferedW > 0) {
            // We use a temporary variable to prevent infinite loops
            let wrapped = wrapText(text, preferedW);
            if (text !== wrapped) text = wrapped; 
        }

        // Now update the actual dimensions
        w = calculateRequiredWidth();
        h = text.split("\n").length;
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
            const isCJK = /[\u4e00-\u9fff\u3040-\u30ff\u31f0-\u31ff\uff00-\uffef]/.test(c)
            const isNone = /[\uffff]/.test(c)
            const costs = isCJK ? 2 : (isNone ? 0 : 1)
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

        sourceComponent: ColumnLayout {

            id: cell_text

            spacing: 0

            Repeater {

                model: root.text.split("\n")

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

                            h: 1
                            w: cells

                            color: root.bg

                            Text {

                                anchors.centerIn: parent

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
    }

}
