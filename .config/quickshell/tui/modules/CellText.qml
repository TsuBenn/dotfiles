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
    property color color: Colors.fgBase
    property color bg: "transparent"

    property bool centered: false
    property bool alignRight: false

    property bool wrap: false

    property bool lockPure: false
    property bool pure: onlyLatin(text)

    property int offset: 0

    property int preferedW: 0
    property int preferedH: 0

    property int w: 0
    property int h: 0
    property int realH: 0

    property bool debug: false

    implicitHeight: Cell.h(h)
    implicitWidth: Cell.w(w)

    Component.onCompleted: {
        updateText()
    }

    onTextChanged: {
        updateText()
    }

    function sliceWithTags(str, start, end) {
        let result = '';
        let visibleCount = 0;
        let i = 0;
        const openTags = [];

        while (i < str.length && visibleCount < end) {
            if (str[i] === '<') {
                const closeIdx = str.indexOf('>', i);
                const fullTag = str.slice(i, closeIdx + 1);
                const isClosing = str[i + 1] === '/';
                const tagName = fullTag.replace(/<\/?([a-zA-Z0-9]+)[^>]*>/, '$1');

                if (visibleCount >= start) {
                    result += fullTag;
                }

                if (isClosing) openTags.pop();
                else openTags.push(tagName);

                i = closeIdx + 1;
            } else {
                if (visibleCount >= start) result += str[i];
                visibleCount++;
                i++;
            }
        }

        // Close any unclosed tags in reverse order
        while (openTags.length) result += `</${openTags.pop()}>`;
        return result;
    }

    // Hoist leading whitespace inside tags to outside
    function hoistWhitespace(str) {
        return str.replace(/(<[^>]+>)(\s+)/g, '$2$1');
    }

    function richify(str) {
        const entityMap = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            '"': "&quot;",
            "'": "&#39;",
        };

        // Split the string into an array of [raw_text, tag, raw_text, tag...]
        // The parenthesis inside the regex ensures the matched tags are kept in the split array
        return str
        .split(/(<\/?[a-zA-Z][^>]*>)/g) 
        .map(part => {
            // If this part is a valid HTML tag, pass it through untouched
            if (part.startsWith("<") && part.endsWith(">")) {
                return part;
            }
            // Otherwise, it's raw text—safely convert the problematic characters
            return part.replace(/[&<>"']/g, char => entityMap[char]);
        })
        .join("").replace(/ /g, "&nbsp;").replace(/\n/g, "<br>");
    }

    function updateText() {

        raw_text = text

        if (!lockPure) { pure = onlyLatin(raw_text) }

        // if (debug) console.log(text)
        // if (debug) console.log(pure)

        if (preferedW > 0) {
            if (wrap) {
                raw_text = wrapText(raw_text, preferedW)
            } else {
                raw_text = truncate(raw_text, preferedW)
            }
        }

        w = getMaxWidth(raw_text)
        h = preferedH > 0 ? preferedH : raw_text.split("\n").length

        if (!pure) {
            processed = splitUnpure(raw_text)
        }

        raw_text = hoistWhitespace(richify(raw_text))

    }

    function isFullWidth(char) {
        const code = char.codePointAt(0);

        //if (debug) console.log(char + "->" + code.toString(16))
        if (!code) return false;

        // Code point ranges for Full-width and Wide characters:
        return (
            (code >= 0x1100 && code <= 0x115F) || // Hangul Jamo
            (code >= 0x2E80 && code <= 0xA4CF && code !== 0x303F) || // CJK Radicals, Symbols, Ideographs
            (code >= 0xAC00 && code <= 0xD7A3) || // Hangul Syllables
            (code >= 0xF900 && code <= 0xFAFF) || // CJK Compatibility Ideographs
            (code >= 0xFE10 && code <= 0xFE19) || // Vertical Presentation Forms
            (code >= 0xFE30 && code <= 0xFE6F) || // CJK Compatibility Forms
            (code >= 0xFF00 && code <= 0xFF60) || // Fullwidth Forms (Letters, Numbers, Punctuation)
            (code >= 0xFFE0 && code <= 0xFFE6) ||

            (code >= 0x1F600 && code <= 0x1F64F) || // Smileys & Emoticons
            (code >= 0x1F300 && code <= 0x1F5FF) || // Misc Symbols & Pictographs
            (code >= 0x1F680 && code <= 0x1F6FF) || // Transport & Map
            (code >= 0x1F900 && code <= 0x1F9FF) || // Supplemental Symbols
            (code >= 0x1FA70 && code <= 0x1FAFF) || // Symbols Extended-A
            (code >= 0x2600  && code <= 0x26FF)  || // Misc Symbols (e.g., ☀, ☁, ⛑)
            //(code >= 0x2700  && code <= 0x27BF)  || // Dingbats (e.g., ✂, ✅)

            (code >= 0x20000 && code <= 0x3FAFF)  // Rare/Extension CJK Ideographs
        );
    }

    function onlyLatin(str) {
        for (const c of str) {
            if (isFullWidth(c)) {
                return false
            }
        }
        return true
    }

    function purify(str) {
        return str.replace(/<[^>]*>/g, "")
    }

    function getWidth(str) {
        let count = 0
        str = purify(str)
        for (const c of str) {
            isFullWidth(c) ? count += 2 : count += 1
        }
        return count
    }

    function getMaxWidth(str) {
        if (preferedW > 0) return preferedW;

        let maxW = 0;
        const lines = purify(str).split("\n");
        for (const line of lines) {
            let lineWidth = getWidth(line)
            if (lineWidth > maxW) maxW = lineWidth;
        }
        return maxW;
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
            if (isFullWidth(char))
            {
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

    function truncate(str, maxCells) {
        if (maxCells <= 0) return str

        let placeholder = str.replace(/<[^>]*>/g, (match) => "\uffff".repeat(match.length))

        let overflowed = str.length > maxCells
        let result = ""
        let cells = []
        let count = 0
        let excess = 0
        let ellipses = ""

        for (const c of placeholder) {
            const isNone = /[\uffff]/.test(c)
            const costs = (isNone ? 0 : (isFullWidth(c) ? 2 : 1))
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

    function wrapFullWidth(str) {
        return `<span style="font-size:${Cell.cellHeight}px;font-family:'Noto Sans Mono CJK JP';">${str}</span>`
    }

    function splitUnpure(str) {

        let result = []
        for (const line of str.split("\n")) {
            let processed = []  
            // <span style="font-size:${Cell.cellHeight}px;font-family:'Noto Sans Mono CJK JP';">${cjk}</span> 

            let inFullWidth = false
            let inEmoji = false
            let buffer = ""

            for (const c of line) {

                if (c.length == 2) {
                    if (inFullWidth) {
                        if (buffer) {
                            processed.push({
                                text: wrapFullWidth(buffer),
                                len: buffer.length,
                                type: "cjk",
                            })
                        }
                        buffer = ""
                        inFullWidth = false
                    } else if (!inEmoji) {
                        if (buffer) {
                            processed.push({
                                text: hoistWhitespace(richify(buffer)),
                                len: buffer.length,
                                type: "pure",
                            })
                        }
                        buffer = ""
                        inEmoji = true
                    }
                    buffer += c

                } else if (isFullWidth(c)) {
                    if (inEmoji) {
                        if (buffer) {
                            processed.push({
                                text: wrapFullWidth(buffer),
                                len: buffer.length/2,
                                type: "emoji",
                            })
                        }
                        buffer = ""
                        inEmoji = false
                    } else if (!inFullWidth) {
                        if (buffer) {
                            processed.push({
                                text: hoistWhitespace(richify(buffer)),
                                len: buffer.length,
                                type: "pure",
                            })
                        }
                        buffer = ""
                        inFullWidth = true
                    }
                    buffer += c

                } else {
                    if (inEmoji) {
                        if (buffer) {
                            processed.push({
                                text: wrapFullWidth(buffer),
                                len: buffer.length/2,
                                type: "emoji",
                            })
                        }
                        buffer = ""
                        inEmoji = false
                    } else if (inFullWidth) {
                        if (buffer) {
                            processed.push({
                                text: wrapFullWidth(buffer),
                                len: buffer.length,
                                type: "cjk",
                            })
                        }
                        buffer = ""
                        inFullWidth = false
                    }

                    buffer += c
                }

            }

            if (buffer) {
                if (inFullWidth) {
                    processed.push({
                        text: wrapFullWidth(buffer),
                        len: buffer.length,
                        type: "cjk",
                    })
                } else if (inEmoji) {
                    processed.push({
                        text: wrapFullWidth(buffer),
                        len: buffer.length/2,
                        type: "emoji",
                    })
                } else {
                    processed.push({
                        text: hoistWhitespace(richify(buffer)),
                        len: buffer.length,
                        type: "pure",
                    })
                }
            }

            result.push(processed)
        }

        if (debug) console.log(JSON.stringify(result, null, 2))

        return result

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

                    x: if (root.centered) {
                        return Cell.centerWCell(implicitWidth, cell_text.implicitWidth)
                    } else if (root.alignRight) {
                        return cell_text.implicitWidth - implicitWidth
                    } else {
                        return 0
                    }

                    spacing: 0

                    Repeater {

                        model: processed

                        delegate: RowLayout {

                            required property int index

                            spacing: 0

                            Repeater {

                                model: processed[parent.index]

                                delegate: Cells {

                                    required property string text 
                                    required property int len
                                    required property string type 

                                    w: len*( type == "emoji" || type == "cjk" ? 2 : 1)
                                    h: 1

                                    color: root.bg

                                    clip: true

                                    Text {

                                        anchors.centerIn: parent.type == "emoji" || parent.type == "cjk" ? parent : undefined

                                        anchors.verticalCenterOffset: parent.type == "emoji" ? Cell.cellHeight*0.05 : 0
                                        anchors.horizontalCenterOffset: parent.type == "emoji" ? Cell.cellWidth*0.05 : 0

                                        textFormat: Text.RichText
                                        text: parent.text
                                        font: root.font
                                        color: root.color
                                        lineHeight: 0.9

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

                    x: if (root.centered) {
                        return Cell.centerWCell(implicitWidth, cell_text.implicitWidth)
                    } else if (root.alignRight) {
                        return cell_text.implicitWidth - implicitWidth
                    } else {
                        return 0
                    }
                    text: root.raw_text
                    textFormat: Text.RichText
                    font: root.font
                    color: root.color
                    lineHeight: 0.9
                }

            }

        }
    }

}
