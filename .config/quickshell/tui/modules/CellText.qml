pragma ComponentBehavior: Bound

import qs.config

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

    function wrapText(text, maxLength) {
        const lines = text.split('\n');
        const wrappedLines = [];

        for (const line of lines) {
            // Use filter(Boolean) to remove empty strings from multiple spaces
            const words = line.trim().split(/\s+/);
            let current = '';

            for (let word of words) {
                // Handle words longer than the terminal width
                if (word.length > maxLength) {
                    if (current) wrappedLines.push(current);
                    while (word.length > maxLength) {
                        wrappedLines.push(word.substring(0, maxLength));
                        word = word.substring(maxLength);
                    }
                    current = word;
                    continue;
                }

                // check: current length + space (1) + next word length
                const space = current.length > 0 ? 1 : 0;
                if (current.length + space + word.length > maxLength) {
                    wrappedLines.push(current);
                    current = word;
                } else {
                    current = (current.length === 0) ? word : `${current} ${word}`;
                }
            }

            if (current) {
                wrappedLines.push(current);
            }
        }

        return wrappedLines.join('\n');
    }

    onTextChanged: {
        w = 0
        h = 0
        if (wrap && preferedW > 0) {
            text = wrapText(text,preferedW)
        }
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

        str = decodeRichText(str.replace(/<[^>]*>/g, ""))

        let overflowed = str.length > maxCells
        let result = ""
        let cells = []
        let count = 0
        let excess = 0
        let ellipses = ""

        for (const c of str) {
            const isCJK = /[\u4e00-\u9fff\u3040-\u30ff\u31f0-\u31ff\uff00-\uffef]/.test(c)
            const costs = isCJK ? 2 : 1
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

    ColumnLayout {

        id: cell_text

        spacing: 0

        Repeater {

            model: root.text.split("\n")

            delegate: RowLayout {

                Layout.leftMargin: root.centered ? Cell.centerWCell(implicitWidth, Cell.w(root.w)) : 0

                id: cell_row

                required property int index
                required property string modelData

                Component.onCompleted: {
                    var count = 0
                    var excess = 0
                    root.h += 1
                    if (root.preferedW > 0) {
                        root.w = root.preferedW
                        return
                    }
                    for (const c of root.splitCJK(modelData)) {
                        count += c.cells
                    }
                    if (count > root.w) {
                        root.w = count
                    }
                }

                spacing: 0

                Repeater {

                    model: root.preferedW > 0 ? root.splitCJK(root.truncate(parent.modelData, root.preferedW)) : root.splitCJK(parent.modelData)


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
