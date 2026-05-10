import qs.config
import qs.modules

import Quickshell.Widgets
import QtQuick

Cells {

    id: root

    property int cellw: 1
    property string text: "Sample of super long text"
    property font font: Cell.font
    property color fg: Colors.fgBase
    property int interval: 300
    property int pause: 2000

    property int offset: 0
    property int excess: 0
    property bool paused: true

    readonly property string displayed: {
        const padded = text + "    "
        const doubled = padded + padded
        return sliceRichText(doubled, offset, offset + cellw)
    }

    function strip(str: string): string {
        return str.trim().replace(/<[^>]*>/g,"")
    }

    function sliceRichText(html, start, end) {
        let result = "";
        let plainTextCount = 0;
        let i = 0;
        let openTags = []; // Stack to track active tags

        while (i < html.length && plainTextCount < end) {
            if (html[i] === '<') {
                let tag = "";
                while (i < html.length && html[i] !== '>') {
                    tag += html[i];
                    i++;
                }
                tag += '>';
                i++;

                // Logic: Is it an opening or closing tag?
                let isClosing = tag.startsWith("</");
                let tagName = tag.replace(/[<>\/]/g, "").split(" ")[0];

                if (isClosing) {
                    if (openTags.length > 0 && openTags[openTags.length - 1] === tagName) {
                        openTags.pop();
                    }
                    // Only add closing tag if we are currently within the slice range
                    if (plainTextCount > start) result += tag;
                } else {
                    openTags.push(tagName);
                    // Only add opening tag if we are currently within the slice range
                    if (plainTextCount >= start) result += tag;
                }
            } else {
                // If we just reached the start index, open all currently "active" tags
                if (plainTextCount === start && result === "") {
                    for (let j = 0; j < openTags.length; j++) {
                        result += "<" + openTags[j] + ">";
                    }
                }

                if (plainTextCount >= start && plainTextCount < end) {
                    result += html[i];
                }
                plainTextCount++;
                i++;
            }
        }

        // Critical: Close any tags that are still open at the end of the slice
        for (let j = openTags.length - 1; j >= 0; j--) {
            result += "</" + openTags[j] + ">";
        }

        return result;
    }

    color: "transparent"

    w: cellw
    h: 1

    CellText {
        visible: false
        id: buffer
        text: root.strip(root.text)
        font: parent.font
        color: parent.fg
    }

    CellText {
        text: buffer.w > root.cellw ? root.displayed : root.text
        preferedW: root.cellw
        font: root.font
        color: root.fg
    }

    onTextChanged: {
        offset = 0
        pauseTimer.restart()
    }

    Timer {
        interval: parent.interval
        running: buffer.w > root.cellw && !parent.paused && root.visible
        repeat: true
        onTriggered: {
            parent.offset = (parent.offset + 1) % (root.strip(parent.text).length + 4)
            if (parent.offset === 0) {
                parent.paused = true
                pauseTimer.restart()
            }
        }
    }
    Timer {
        id: pauseTimer
        interval: root.pause
        repeat: false
        onTriggered: parent.paused = false
    }
}
