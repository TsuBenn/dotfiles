pragma ComponentBehavior: Bound

import qs.config

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property string text: "cell text"
    property font font: Cell.font
    property color color: Colors.fgBase

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

        let result = ""
        let count = 0

        for (const c of str) {
            const isCJK = /[\u4e00-\u9fff\u3040-\u30ff\u31f0-\u31ff\uff00-\uffef]/.test(c)
            const costs = isCJK ? 2 : 1

            count += costs

            if (count > maxCells) {
                if (count - maxCells != costs) {
                    result += "…"
                    break
                } else {
                    if (result.length > 1) {
                        result = result.slice(0, -1) + "…"
                    } else {
                        result = "…"
                    }
                    break
                }
            }

            result += c
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
                    count: latin.length,
                    cells: latin.length,
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

                        color: root.parent.color ?? "transparent"

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
