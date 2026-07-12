pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string text: "Sample"

    implicitHeight: 0
    implicitWidth: Cell.w(w)

    property int w: 40

    Loader {

        active: root.visible

        sourceComponent: ColumnLayout {
            id: layout

            onImplicitHeightChanged: {
                root.implicitHeight = implicitHeight;
            }

            x: Cell.w(1)

            spacing: 0

            Repeater {

                model: parseMarkdown(root.text, root.w - 2)

                delegate: Loader {
                    id: l

                    active: root.visible

                    required property var modelData

                    property Component p: P {}

                    property Component code_block: Cells {
                        w: root.w - 2
                        h: cb_text.h
                        color: Colors.bgOverlay
                        CellText {
                            id: cb_text
                            text: l.modelData.value
                            preferedW: root.w - 2
                            color: Colors.secondary
                        }
                    }

                    property Component img: Cells {
                        w: root.w - 2
                        h: image.status == Image.Ready ? Cell.hCount(image.height, "ceil") : 1
                        color: "transparent"

                        CellText {
                            text: "[image] " + l.modelData.value
                            color: Colors.info
                        }

                        Image {
                            id: image
                            width: Cell.w(root.w - 2)
                            source: l.modelData.data
                            height: width * (sourceSize.height / sourceSize.width)
                            fillMode: Image.PreserveAspectCrop
                        }
                    }

                    property Component quote: RowLayout {

                        property int level: modelData.level

                        spacing: 0

                        CellText {
                            Layout.alignment: Qt.AlignTop
                            text: " " + "  ".repeat(parent.level) + "┃ "
                            color: Colors.fgSubtle
                            pure: false
                            lockPure: true
                        }

                        P {
                            Layout.alignment: Qt.AlignTop
                            lines: l.modelData.value
                            color: Colors.fgSubtle
                        }
                    }

                    property Component unordered_list: RowLayout {

                        property int level: modelData.level
                        property string marker: modelData.marker

                        spacing: 0

                        CellText {
                            Layout.alignment: Qt.AlignTop
                            text: " " + "  ".repeat(parent.level)
                        }

                        CellText {
                            Layout.alignment: Qt.AlignTop
                            text: parent.marker + " "
                            font: Cell.fontB
                            color: Colors.fgSubtle
                        }

                        P {
                            Layout.alignment: Qt.AlignTop
                            lines: l.modelData.value
                        }
                    }

                    property Component ordered_list: RowLayout {

                        property int level: modelData.level
                        property string marker: modelData.marker

                        spacing: 0

                        CellText {
                            Layout.alignment: Qt.AlignTop
                            text: " " + "  ".repeat(parent.level)
                        }

                        CellText {
                            Layout.alignment: Qt.AlignTop
                            text: parent.marker + ". "
                            font: Cell.fontB
                        }

                        P {
                            Layout.alignment: Qt.AlignTop
                            lines: l.modelData.value
                        }
                    }

                    property Component h: ColumnLayout {

                        spacing: 0

                        x: Cell.centerWCell(implicitWidth, Cell.w(root.w - 2))

                        P {
                            Layout.leftMargin: l.modelData.type.endsWith("2") ? Cell.centerWCell(implicitWidth, Cell.w(root.w - 2)) : 0
                            color: l.modelData.type.endsWith("2") ? Colors.onAccent : Colors.secondary
                            font: Cell.fontB
                            bg: l.modelData.type.endsWith("2") ? Colors.accentStrong : "transparent"
                            padding: 1
                        }

                        CellSeparator {
                            w: l.modelData.type.endsWith("2") ? root.w - 2 : Cell.wCount(parent.implicitWidth)
                            color: l.modelData.type.endsWith("2") ? Colors.accentStrong : Colors.secondary
                            type: l.modelData.type.endsWith("2") ? 2 : 0
                        }
                    }

                    property Component separator: CellSeparator {
                        x: Cell.centerWCell(implicitWidth, Cell.w(root.w - 2))
                        w: root.w - 2
                        color: Colors.bgOverlay
                    }

                    property Component blank: CellText {
                        text: ""
                    }

                    sourceComponent: {
                        if (modelData.type == "p")
                            return p;
                        else if (modelData.type == "code_block")
                            return code_block;
                        else if (modelData.type == "quote")
                            return quote;
                        else if (modelData.type == "img")
                            return img;
                        else if (modelData.type == "separator")
                            return separator;
                        else if (modelData.type == "ordered_list")
                            return ordered_list;
                        else if (modelData.type == "unordered_list")
                            return unordered_list;
                        else if (modelData.type.startsWith("h"))
                            return h;
                        else
                            return blank;
                    }
                }
            }
        }
    }

    component P: ColumnLayout {
        id: p

        property var lines: modelData.value

        property color color: Colors.fgBase
        property color overlay: Colors.bgOverlay
        property font font: Cell.font
        property color bg: "transparent"
        property int padding: 0

        spacing: 0

        Repeater {

            model: parent.lines

            delegate: RowLayout {
                id: line

                required property var modelData

                spacing: 0

                Repeater {

                    model: parent.modelData

                    delegate: CellText {

                        required property var modelData
                        required property int index

                        property int maxIndex: line.modelData.length - 1

                        text: {
                            if (modelData.type == "link") {
                                return `<u>${index == 0 ? " ".repeat(p.padding) : ""}${modelData.value}${index == maxIndex ? " ".repeat(p.padding) : ""}</u>`;
                            }
                            return (index == 0 ? " ".repeat(p.padding) : "") + modelData.value + (index == maxIndex ? " ".repeat(p.padding) : "");
                        }
                        color: {
                            if (modelData.type == "code") {
                                return Colors.secondary;
                            } else if (modelData.type == "link") {
                                return Colors.info;
                            }
                            return p.color;
                        }
                        bg: {
                            if (modelData.type == "code") {
                                return p.overlay;
                            }
                            return p.bg;
                        }
                        font: p.font

                        MouseControl {
                            id: p_mouse
                            visible: parent.modelData.type == "link"
                            anchors.fill: parent
                            onReleased: button => {
                                if (button == "L") {
                                    SystemInfo.runDetached(["xdg-open", parent.modelData.data]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    onTextChanged: {
        // console.log(JSON.stringify(parseFormattedText(root.text), null, 2));
    }

    // Inline code will always be in the odd index
    // Example: This is an `inline` code
    //             [0]       [1]    [2]

    function parseMarkdown(md, width = 80) {
        const lines = md.split('\n');
        const blocks = [];
        let inCodeBlock = false;
        let codeContent = [];

        // Helper 1: Escapes raw HTML entities to keep things safe
        const escapeHtml = str => {
            return str; // str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        };

        // Helper 2: Converts markdown emphasis symbols to HTML inline tags
        const processTextStyles = str => {
            let escaped = escapeHtml(str);
            escaped = escaped.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>');
            escaped = escaped.replace(/\*(.*?)\*/g, '<i>$1</i>');
            escaped = escaped.replace(/~~(.*?)~~/g, '<s>$1</s>');
            return escaped;
        };

        // Helper 3: Tokenizes a string into discrete structural text/code/link/img entities
        const parseInline = text => {
            const regex = /(!?\[[^\]]*\]\([^)]+\)|`[^`]+`)/g;
            const parts = text.split(regex);
            const tokens = [];

            for (const part of parts) {
                if (!part)
                    continue;

                if (part.startsWith('`') && part.endsWith('`')) {
                    tokens.push({
                        type: 'code',
                        value: escapeHtml(part.slice(1, -1))
                    });
                } else if (part.startsWith('![')) {
                    const imgMatch = part.match(/!\[([^\]]*)\]\(([^)]+)\)/);
                    if (imgMatch) {
                        tokens.push({
                            type: 'img',
                            value: imgMatch[1],
                            data: imgMatch[2]
                        });
                    }
                } else if (part.startsWith('[')) {
                    const linkMatch = part.match(/\[([^\]]+)\]\(([^)]+)\)/);
                    if (linkMatch) {
                        tokens.push({
                            type: 'link',
                            value: processTextStyles(linkMatch[1]),
                            data: linkMatch[2]
                        });
                    }
                } else {
                    tokens.push({
                        type: 'text',
                        value: processTextStyles(part)
                    });
                }
            }
            return tokens;
        };

        // Helper 4: Breaks structured tokens into line chunks without chopping open HTML tags
        const wrapTokens = (tokens, maxWidth) => {
            const wrappedLines = [];
            let currentLine = [];
            let currentLen = 0;
            let activeTags = [];

            for (const token of tokens) {
                if (token.type === 'text') {
                    const parts = token.value.split(/(<\/?(?:b|i|s)>|\s+)/).filter(Boolean);

                    for (const part of parts) {
                        if (part.match(/^<\/?(?:b|i|s)>$/)) {
                            if (part.startsWith('</')) {
                                activeTags.pop();
                            } else {
                                activeTags.push(part);
                            }

                            if (currentLine.length > 0 && currentLine[currentLine.length - 1].type === 'text') {
                                currentLine[currentLine.length - 1].value += part;
                            } else {
                                currentLine.push({
                                    type: 'text',
                                    value: part
                                });
                            }
                            continue;
                        }

                        const visibleLen = part.replace(/<[^>]*>/g, '').length;

                        if (currentLen + visibleLen > maxWidth && currentLen > 0 && part.trim() !== "") {
                            if (currentLine.length > 0 && currentLine[currentLine.length - 1].type === 'text') {
                                for (let i = activeTags.length - 1; i >= 0; i--) {
                                    currentLine[currentLine.length - 1].value += activeTags[i].replace('<', '</');
                                }
                            }

                            wrappedLines.push(currentLine);
                            currentLine = [];
                            currentLen = 0;

                            const reopenedTags = activeTags.join('');
                            currentLine.push({
                                type: 'text',
                                value: reopenedTags + part
                            });
                        } else {
                            if (currentLine.length > 0 && currentLine[currentLine.length - 1].type === 'text') {
                                currentLine[currentLine.length - 1].value += part;
                            } else {
                                currentLine.push({
                                    type: 'text',
                                    value: part
                                });
                            }
                        }
                        currentLen += visibleLen;
                    }
                } else {
                    const visibleLen = token.value.length;
                    if (currentLen + visibleLen > maxWidth && currentLen > 0) {
                        wrappedLines.push(currentLine);
                        currentLine = [];
                        currentLen = 0;
                    }
                    currentLine.push(token);
                    currentLen += visibleLen;
                }
            }
            if (currentLine.length > 0)
                wrappedLines.push(currentLine);
            return wrappedLines.length > 0 ? wrappedLines : [[]];
        };

        // Main Engine Loop: Block Level Line Tokenizer
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            if (line.trim().startsWith('```')) {
                if (inCodeBlock) {
                    blocks.push({
                        type: 'code_block',
                        value: codeContent.join('\n')
                    });
                    inCodeBlock = false;
                    codeContent = [];
                } else {
                    inCodeBlock = true;
                }
                continue;
            }
            if (inCodeBlock) {
                codeContent.push(line);
                continue;
            }

            if (line.trim() === '') {
                blocks.push({
                    type: 'blank'
                });
                continue;
            }
            if (/^(---|\*\*\*|___)$/.test(line.trim())) {
                blocks.push({
                    type: 'separator'
                });
                continue;
            }

            const headingMatch = line.match(/^(#{1,6})\s+(.*)/);
            if (headingMatch) {
                blocks.push({
                    type: `h${headingMatch[1].length}`,
                    value: wrapTokens(parseInline(headingMatch[2]), width)
                });
                continue;
            }

            const quoteMatch = line.match(/^(\s*)(>+)\s+(.*)/);
            if (quoteMatch) {
                blocks.push({
                    type: 'quote',
                    level: quoteMatch[1].length / 2 | 0,
                    value: wrapTokens(parseInline(quoteMatch[3]), width - 2 - 2 * (quoteMatch[1].length / 2 | 0))
                });
                continue;
            }

            const ulMatch = line.match(/^(\s*)([-*+])\s+(.*)/);
            if (ulMatch) {
                blocks.push({
                    type: 'unordered_list',
                    marker: ulMatch[2],
                    level: ulMatch[1].length / 2 | 0,
                    value: wrapTokens(parseInline(ulMatch[3]), width - 2 - ulMatch[2].length - 2 * (ulMatch[1].length / 2 | 0))
                });
                continue;
            }

            const olMatch = line.match(/^(\s*)(\d+)\.\s+(.*)/);
            if (olMatch) {
                blocks.push({
                    type: `ordered_list`,
                    marker: olMatch[2],
                    level: olMatch[1].length / 2 | 0,
                    value: wrapTokens(parseInline(olMatch[3]), width - 3 - olMatch[2].length - 2 * (olMatch[1].length / 2 | 0))
                });
                continue;
            }

            const blockImgMatch = line.match(/^\s*!\[([^\]]*)\]\(([^)]+)\)\s*$/);
            if (blockImgMatch) {
                blocks.push({
                    type: 'img',
                    value: blockImgMatch[1] // alt text
                    ,
                    data: blockImgMatch[2]   // path or link
                });
                continue;
            }

            // Paragraph Fallback
            blocks.push({
                type: 'p',
                value: wrapTokens(parseInline(line), width)
            });
        }

        return blocks;
    }
}
