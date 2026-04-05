pragma ComponentBehavior: Bound

import qs.config

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property string text: "cell text"
    property font font: Cell.font
    property color color: Colors.fgBase

    readonly property int w: Cell.toW(cell_text.implicitWidth)
    readonly property int h: Cell.toW(cell_text.implicitHeight)

    implicitHeight: h
    implicitWidth: w

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

                required property int index
                required property string modelData

                spacing: 0

                Repeater {

                    model: root.splitCJK(parent.modelData)

                    delegate: Item {

                        required property string text
                        required property int cells

                        implicitHeight: Cell.h(1)
                        implicitWidth: Cell.w(cells)

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
