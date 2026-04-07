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

    property int preferedW: 0

    property int w: 0
    property int h: 0

    onTextChanged: {
        w = 0
        h = 0
    }

    implicitHeight: Cell.h(h)
    implicitWidth: Cell.w(w)

    function truncate(str, maxCells) {
        if (maxCells <= 0) return str

        str = str.replace(/<[^>]*>/g, "")

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
            } else {
                let latin = ""
                while (i < str.length && !/[\u4e00-\u9fff\u3040-\u30ff\u31f0-\u31ff\uff00-\uffef]/.test(str[i])) {
                    latin += str[i]
                    i++
                }
                result.push({
                    text: latin.replace(/ /g, "&nbsp;"),
                    raw: latin,
                    count: latin.replace(/<[^>]*>/g,"").length,
                    cells: latin.replace(/<[^>]*>/g,"").length,
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

                id: cell_row

                required property int index
                required property string modelData

                Component.onCompleted: {
                    var count = 0
                    var excess = 0
                    root.h += 1
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

                        required property string text
                        required property int cells

                        h: 1
                        w: cells

                        color: root.bg

                        Text {

                            anchors.centerIn: parent

                            id: texts
                            textFormat: Text.RichText
                            text: parent.text
                            font: root.font
                            color: root.color

                        }
                    }

                }

            }
        }
    }
}
