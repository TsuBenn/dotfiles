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

    property bool debug: false

    // <span style="font-size:${Cell.cellWidth*2}px;font-family:'Noto Sans Mono CJK JP';">${cjk}</span>

    function isFullWidth(char) {
        const code = char.codePointAt(0);

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

            (code >= 0x1F000 && code <= 0x1FFFF) || // Emojis
            (code >= 0x2600 && code <= 0x27FF) || // Emojis
            (code >= 0xFE00 && code <= 0xFEFF) || // Emojis

            (code >= 0x20000 && code <= 0x3FAFF)  // Rare/Extension CJK Ideographs
        );
    }

    function getWidth(str) {
        let count = 0
        for (const c of str) {
            isFullWidth(c) ? count += 2 : count += 1
        }
        return count
    }

    function onlyLatin(str) {
        for (const c of str) {
            if (isFullWidth(c)) return false
        }
        return true
    }

    Cells {

        w: root.w
        h: root.h

        color: root.bg

        Loader {
            active: (root.visible || !root.optimizeMemory) && !root.onlyLatin(root.text)

            sourceComponent: ColumnLayout {

            }
        }

        Loader {

            active: (root.visible || !root.optimizeMemory) && root.onlyLatin(root.text)

            sourceComponent: Text {
                text: root.text
                color: root.color
                font: root.font
            }
        }

    }


}

