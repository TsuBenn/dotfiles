pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {
    id: root

    w: Cell.wCount(popup.implicitWidth)
    h: Cell.hCount(popup.implicitHeight)

    property bool minimal: SettingsInfo.minimal

    property var result: Object.keys(Colors.colors)

    property var colors: Object.keys(Colors.colors)

    Connections {
        target: Colors
        function onColorsChanged() {
            root.result = root.colors;
        }
    }

    escapeToClose: true

    function getNextCopyNumber(array, baseString) {
        let maxCounter = 0;

        array.forEach(item => {
            if (item === baseString) {
                maxCounter = Math.max(maxCounter, 0);
            } else if (item.startsWith(`${baseString}_`)) {
                const parts = item.split("_");
                const num = parseInt(parts[parts.length - 1], 10);
                if (!isNaN(num)) {
                    maxCounter = Math.max(maxCounter, num);
                }
            }
        });

        return maxCounter + 1;
    }

    shortcuts: [
        {
            binds: ["BackTab", "Up"],
            action: () => {
                if (color.edit) {
                    if (id_textfield.focus) {
                        des_textfield.grabFocus();
                    } else if (name_textfield.focus) {
                        id_textfield.grabFocus();
                    } else if (des_textfield.focus) {
                        name_textfield.grabFocus();
                    }
                    return;
                }
                color.selected = Math.max(color.selected - 1, 0);
                if (color.selected - list.offset / 2 < 0) {
                    list.offset = Math.floor(color.selected / 13) * 26;
                }
            }
        },
        {
            binds: ["Tab", "Down"],
            action: () => {
                if (color.edit) {
                    if (id_textfield.focus) {
                        name_textfield.grabFocus();
                    } else if (name_textfield.focus) {
                        des_textfield.grabFocus();
                    } else if (des_textfield.focus) {
                        id_textfield.grabFocus();
                    }
                    return;
                }
                color.selected = Math.min(color.selected + 1, root.result.length - 1);
                if (color.selected - list.offset / 2 >= 13) {
                    list.offset = Math.floor(color.selected / 13) * 26;
                }
            }
        },
        {
            binds: "Escape",
            action: () => {
                if (color.color_picker) {
                    color.color_picker = false;
                } else if (color.edit) {
                    if (TextFieldManager.active) {
                        TextFieldManager.unFocusAll();
                    } else {
                        color.toggleEdit();
                    }
                } else {
                    root.close();
                }
            }
        },
    ]

    onVisibleChanged: {
        if (color.edit && visible) {
            color.toggleEdit();
        }
        resetList();
    }

    function resetList() {
        color.selected = result.findIndex(item => item == Colors.current);
        if (color.selected == -1) {
            color.selected = 0;
        }
        list.offset = Math.floor(color.selected / 13) * 26;
    }

    ColumnLayout {

        spacing: 0

        RowLayout {
            id: popup

            spacing: Cell.w(2)

            Item {
                id: color

                property bool edit: false

                property bool color_picker: false

                property var buffer: Colors.dummy

                property var source: Colors.colors[root.result[selected]]?.[SettingsInfo.lightMode ? "light" : "dark"] ?? Colors.dummy

                property var color: source

                property int selected: 0

                property int push: 0

                property int h: 28

                signal unFocusPalette

                function setBuffer(key, value) {
                    buffer = Object.assign({}, buffer, {
                        [key]: value
                    });
                }

                function openPicker(key: string) {
                    des_textfield.unFocus();
                    name_textfield.unFocus();
                    unFocusPalette();
                    if (color_picker.key == "") {
                        color.color_picker = true;
                        color_picker.key = key;
                        color_picker.buffer = Qt.color(color.color[key]);
                    } else if (color_picker.key != key) {
                        color_picker.key = key;
                        color_picker.buffer = Qt.color(color.color[key]);
                    } else {
                        color.color_picker = false;
                    }
                }

                function resetColor() {
                    color.setBuffer(color_picker.key, source[color_picker.key]);
                    color_picker.buffer = Qt.color(color.color[color_picker.key]);
                }

                function resetEdit() {
                    color.buffer = JSON.parse(JSON.stringify(color.source));
                    colorChanged();
                    color_picker.buffer = Qt.color(color.color[color_picker.key]);
                }

                function toggleEdit() {
                    if (root.result[color.selected] == "auto")
                        return;
                    edit = !edit;
                    des_textfield.unFocus();
                    name_textfield.unFocus();
                    if (edit) {
                        push = preview_tab.selected;
                        id_textfield.set(root.result[color.selected]);
                        textfield.unFocus();
                        preview_tab.selected = 1;
                        color.buffer = JSON.parse(JSON.stringify(color.source));
                        color.color = Qt.binding(() => color.buffer);
                    } else {
                        id_textfield.set("");
                        preview_tab.selected = push;
                        textfield.grabFocus();
                        color.color = Qt.binding(() => color.source);
                        color.color_picker = false;
                    }
                }

                Component.onCompleted: {
                    root.resultChanged.connect(() => {
                        root.resetList();
                    });
                    Colors.currentChanged.connect(() => {
                    //root.resetList()
                    });
                }
            }

            CellBox {

                w: 38
                h: color.h + 2

                ColumnLayout {

                    visible: !color.color_picker

                    spacing: 0

                    CellScrollView {
                        id: list

                        w: 36
                        h: color.h - 2

                        onContentHChanged: {
                            root.resetList();
                        }

                        onMaxOffsetChanged: {
                            list.snapBack();
                            root.resetList();
                        }

                        source: ColumnLayout {

                            spacing: 0

                            Repeater {

                                model: root.result

                                delegate: Loader {
                                    id: list_loader

                                    active: list.visible

                                    required property int index
                                    required property string modelData

                                    sourceComponent: Cells {
                                        id: theme

                                        property int index: list_loader.index
                                        property string modelData: list_loader.modelData

                                        property var source: Colors.colors[modelData]?.[SettingsInfo.lightMode ? "light" : "dark"] ?? Colors.dummy

                                        property bool isCurrent: modelData == Colors.current
                                        property bool selected: color.selected == index

                                        w: list.contentW
                                        h: 2

                                        color: color.edit ? Colors.bgSurface : (isCurrent ? theme.source.accentStrong : (theme_mouse.hovered ? theme.source.bgOverlay : Colors.bgSurface))

                                        ColumnLayout {

                                            spacing: 0

                                            CellText {

                                                Layout.leftMargin: Cell.w(1)

                                                text: (theme.selected ? "> " : "  ") + theme.source.name
                                                color: color.edit ? Colors.fgSubtle : (theme.isCurrent ? theme.source.onAccent : (theme_mouse.hovered ? theme.source.fgBase : Colors.fgBase))
                                                font: theme.isCurrent ? Cell.fontB : Cell.font

                                                preferedW: theme.w - 4
                                            }

                                            CellSeparator {
                                                w: theme.w
                                                type: 0
                                                color: Colors.bgOverlay
                                            }
                                        }

                                        MouseControl {
                                            id: theme_mouse

                                            visible: !color.edit

                                            anchors.fill: parent

                                            onReleased: button => {
                                                if (button == "L") {
                                                    color.selected = theme.index;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    CellSeparator {

                        w: 36
                        color: Colors.accentStrong
                    }

                    Cells {
                        id: textwrapper

                        w: 36
                        h: 1

                        color: "transparent"

                        RowLayout {

                            x: Cell.w(1)

                            spacing: Cell.w(1)

                            CellTextField {
                                id: textfield

                                w: 31 - appearance.text.length
                                h: 1

                                placeholder: "Search themes"

                                focusOnVisible: !color.edit

                                onVisibleChanged: {
                                    if (visible) {
                                        root.result = root.colors;
                                    }
                                }

                                onFocusChanged: {
                                    if (color.edit && focus) {
                                        color.toggleEdit();
                                    }
                                }

                                onEntered: {
                                    if (Colors.current != root.result[color.selected]) {
                                        Colors.current = root.result[color.selected];
                                    }
                                }

                                onTextInput: input => {
                                    if (input == "") {
                                        root.result = root.colors;
                                    } else {
                                        root.result = root.colors.filter(item => {
                                            return Colors.colors[item][SettingsInfo.lightMode ? "light" : "dark"].name.toLowerCase().includes(input.toLowerCase()) || Colors.colors[item][SettingsInfo.lightMode ? "light" : "dark"].description.toLowerCase().includes(input.toLowerCase()) || item.includes(input.toLowerCase());
                                        });
                                    }
                                }
                            }

                            CellButton {
                                id: appearance

                                text: SettingsInfo.appearance

                                color: [Colors.bgOverlay, Colors.fgBase]
                                fg: [Colors.fgBase, Colors.bgSurface]

                                onReleased: button => {
                                    if (button == "L") {
                                        SettingsInfo.iterateAppearance();
                                    }
                                }
                            }
                        }
                    }
                }

                CellColorPicker {
                    id: color_picker

                    visible: color.color_picker

                    // When the picker closes, drop the key so the next openPicker()
                    // call is treated as a fresh open rather than a "switch key".
                    onVisibleChanged: {
                        if (!visible)
                            key = "";
                    }

                    // The picker is the source of truth for the editing color.
                    // Whenever its `buffer` changes (SV drag, slider, HEX/RGB
                    // entry), forward the new value to the parent edit buffer so
                    // the preview pane and palette list stay in sync.
                    key: ""
                    sourceColor: Qt.color(color.source[color_picker.key] || "#000000")
                    buffer: "black"

                    h: color.h

                    onApplied: (k, v) => color.setBuffer(k, v)
                }
            }

            CellBox {

                w: 58
                h: color.h + 2

                border {
                    type: 4
                    color: root.result.length > 0 ? color.color.accentStrong : Colors.accentStrong
                }

                color: root.result.length > 0 ? color.color.bgSurface : Colors.bgSurface

                Cells {
                    id: preview

                    visible: root.result.length > 0

                    w: 56
                    h: 28

                    color: "transparent"

                    ColumnLayout {

                        spacing: 0

                        RowLayout {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                            spacing: 0

                            CellText {

                                text: color.edit ? "Editing" : "Previews"

                                color: color.color.secondary
                                font: Cell.fontB
                            }

                            CellText {
                                visible: color.edit
                                text: "  ID: "
                            }

                            Cells {

                                visible: color.edit
                                w: preview.w - 15
                                h: 1
                                color: color.color.bgOverlay

                                CellTextField {
                                    id: id_textfield

                                    w: parent.w
                                    h: parent.h

                                    focusOnVisible: false
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    color: color.color.fgBase
                                    invert: color.color.bgSurface
                                    visual_color: color.color.secondary
                                    disabled_color: color.color.fgSubtle

                                    autoApply: true
                                }
                            }
                        }

                        CellSeparator {
                            w: preview.w
                            type: 2
                            color: color.color.accentStrong
                            bg: "transparent"
                        }

                        CellText {
                            Layout.leftMargin: Cell.w(1)
                            text: "Name: "
                            color: color.color.fgDim
                        }

                        CellText {
                            visible: !color.edit
                            Layout.leftMargin: Cell.w(1)
                            text: color.color.name
                            color: color.color.fgBase
                            preferedW: preview.w - 2
                            font: Cell.fontB
                        }

                        Cells {

                            visible: color.edit
                            Layout.leftMargin: Cell.w(1)

                            w: preview.w - 2
                            h: 1

                            color: color.color.bgOverlay

                            CellTextField {
                                id: name_textfield

                                w: parent.w
                                h: parent.h

                                focusOnVisible: false
                                unfocusOnEntered: true
                                escapeToUnFocus: true

                                color: color.color.fgBase
                                invert: color.color.bgSurface
                                visual_color: color.color.secondary
                                disabled_color: color.color.fgSubtle

                                autoApply: true
                                bindText: color.color.name
                                wrap: true

                                onEntered: input => {
                                    color.setBuffer("name", input);
                                }
                            }
                        }

                        CellText {
                            Layout.leftMargin: Cell.w(1)
                            text: "Description: "
                            color: color.color.fgDim
                        }

                        CellText {
                            visible: !color.edit
                            Layout.leftMargin: Cell.w(1)
                            text: color.color.description
                            color: color.color.fgBase
                            preferedW: preview.w - 2
                            preferedH: 4
                            wrap: true
                            font: Cell.fontB
                        }

                        Cells {

                            visible: color.edit
                            Layout.leftMargin: Cell.w(1)

                            w: preview.w - 2
                            h: 4

                            color: color.color.bgOverlay

                            CellTextField {
                                id: des_textfield

                                w: parent.w
                                h: parent.h

                                focusOnVisible: false
                                unfocusOnEntered: true
                                escapeToUnFocus: true

                                color: color.color.fgBase
                                invert: color.color.bgSurface
                                visual_color: color.color.secondary
                                disabled_color: color.color.fgSubtle

                                autoApply: true
                                bindText: color.color.description
                                wrap: true

                                onEntered: input => {
                                    color.setBuffer("description", input);
                                }
                            }
                        }

                        CellSeparator {
                            w: preview.w
                            type: 0
                            color: color.color.accentDim
                            bg: "transparent"
                        }

                        CellTabs {
                            id: preview_tab

                            onVisibleChanged: {
                                selected = 0;
                            }

                            w: preview.w

                            items: ["Widgets", "Color list",]

                            color {
                                bg: color.color.bgSurface
                                fg: color.color.bgOverlay
                                base: color.color.fgBase
                                inactive: color.color.fgSubtle
                                active: color.color.accentStrong
                            }
                        }

                        Cells {

                            Layout.leftMargin: Cell.w(1)

                            w: preview.w - 2
                            h: 14

                            color: "transparent"

                            ColumnLayout {
                                id: preview_widgets

                                visible: preview_tab.selected == 0

                                Layout.leftMargin: Cell.w(1)

                                property int label_width: 14
                                property int widgets_width: preview.w - 2 - label_width

                                spacing: 0

                                PreviewWidget {

                                    label: "Text"

                                    ColumnLayout {

                                        spacing: 0

                                        CellText {
                                            text: "Normal <b>Bold</b> <i>Italic</i> <i><b>Bold and Italic</b><i/>"
                                            color: color.color.fgBase
                                        }

                                        CellText {
                                            text: "Black  <i>Black and Italic</i>"
                                            color: color.color.fgBase
                                            font: Cell.fontBB
                                        }
                                    }
                                }

                                WidgetSep {}

                                PreviewWidget {

                                    label: "Buttons"

                                    RowLayout {

                                        spacing: Cell.w(1)

                                        CellButton {
                                            text: "Click me!"
                                            color: [color.color.accentStrong, color.color.bgOverlay]
                                            fg: [color.color.onAccent, color.color.fgBase]
                                        }

                                        CellButton {
                                            text: "Click me!"
                                            color: [color.color.bgOverlay, color.color.fgBase]
                                            fg: [color.color.fgBase, color.color.bgSurface]
                                        }

                                        CellButton {
                                            text: "Disabled!"
                                            clickable: false
                                            color: color.color.bgOverlay
                                            fg: color.color.fgSubtle
                                        }
                                    }
                                }

                                WidgetSep {}

                                PreviewWidget {

                                    label: "Text field"

                                    Cells {

                                        w: preview_widgets.widgets_width
                                        h: 2

                                        color: color.color.bgOverlay

                                        CellTextField {

                                            placeholder: "Write something here!"

                                            focusOnVisible: false
                                            unfocusOnEntered: true
                                            wrap: true

                                            w: parent.w
                                            h: parent.h

                                            color: color.color.fgBase
                                            invert: color.color.bgSurface
                                            visual_color: color.color.secondary
                                            disabled_color: color.color.fgSubtle

                                            onFocusChanged: {
                                                if (!focus) {
                                                    textfield.grabFocus();
                                                }
                                            }
                                        }
                                    }
                                }

                                WidgetSep {}

                                PreviewWidget {

                                    label: "Dropdown"

                                    CellDropdown {

                                        menu {
                                            color: color.color.bgOverlay
                                            fg: color.color.fgBase
                                            active: color.color.accentStrong
                                            active_invert: color.color.onAccent
                                        }

                                        button {
                                            color: color.color.bgOverlay
                                            fg: color.color.fgBase
                                            active: color.color.bgOverlay
                                            active_invert: color.color.fgBase
                                        }

                                        w: 12

                                        text: ""

                                        items: [
                                            {
                                                label: "Item 1",
                                                action: () => {
                                                    selected = 0;
                                                }
                                            },
                                            {
                                                label: "Item 2",
                                                action: () => {
                                                    selected = 1;
                                                }
                                            },
                                            {
                                                label: "Item 3",
                                                action: () => {
                                                    selected = 2;
                                                }
                                            },
                                        ]
                                    }
                                }

                                WidgetSep {}

                                PreviewWidget {

                                    label: "Progress bar"

                                    RowLayout {

                                        spacing: 0

                                        CellText {
                                            text: "["
                                            color: color.color.accentStrong
                                            font: Cell.fontB
                                        }

                                        CellProgressSquare {
                                            w: preview_widgets.widgets_width - 2
                                            interactive: true
                                            percent: 50
                                            onAdjusted: {
                                                this.percent = raw_percent;
                                            }
                                            color: color.color.bgOverlay
                                            fg: color.color.accentStrong
                                        }

                                        CellText {
                                            text: "]"
                                            color: parent.children[0].color
                                            font: parent.children[0].font
                                        }
                                    }
                                }

                                WidgetSep {}

                                GridLayout {

                                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                                    columnSpacing: Cell.w(1)
                                    rowSpacing: Cell.h(0)

                                    columns: 4

                                    CellText {
                                        text: "[*] LABEL"
                                        color: color.color.fgDim
                                        font: Cell.fontB
                                    }
                                    CellText {
                                        text: "[i] INFO"
                                        color: color.color.info
                                        font: parent.children[0].font
                                    }
                                    CellText {
                                        text: "[✓] SUCCESS"
                                        color: color.color.success
                                        font: parent.children[0].font
                                    }
                                    CellText {
                                        text: " 2╺━╸3╺━╸4 "
                                        color: color.color.success
                                        font: Cell.fontBB
                                    }
                                    CellText {
                                        text: "[*] VALUE"
                                        color: color.color.fgBase
                                        font: parent.children[0].font
                                    }
                                    CellText {
                                        text: "[!] WARNING"
                                        color: color.color.warning
                                        font: parent.children[0].font
                                    }
                                    CellText {
                                        text: "[✗] DANGER"
                                        color: color.color.danger
                                        font: parent.children[0].font
                                    }
                                    RowLayout {

                                        spacing: Cell.w(1)

                                        CellText {
                                            text: " 5 "
                                            color: color.color.fgBase
                                            font: Cell.fontBB
                                        }
                                        CellText {
                                            text: " 6 "
                                            color: color.color.warning
                                            font: Cell.fontBB
                                        }
                                        CellText {
                                            text: " 7 "
                                            color: color.color.danger
                                            font: Cell.fontBB
                                        }
                                    }
                                }
                            }

                            CellScrollView {

                                visible: preview_tab.selected == 1

                                w: parent.w + 1
                                h: parent.h

                                scrollbar {
                                    color: color.color.fgDim
                                    bg_color: color.color.bgOverlay
                                }

                                source: ColumnLayout {

                                    spacing: 0

                                    Repeater {

                                        model: ["bgBase", "bgSurface", "bgOverlay", "fgBase", "onAccent", "fgDim", "fgSubtle", "accentStrong", "accentDim", "secondary", "info", "success", "warning", "danger", "borderActive", "borderInactive",]

                                        delegate: ColumnLayout {
                                            id: palette

                                            required property string modelData

                                            property bool selected: color_picker.key == modelData

                                            Component.onCompleted: {
                                                color.unFocusPalette.connect(() => {
                                                    palette_hex?.unFocus();
                                                    palette_hue?.unFocus();
                                                    palette_saturation?.unFocus();
                                                    palette_value?.unFocus();
                                                });
                                            }

                                            spacing: 0

                                            RowLayout {
                                                id: palette_label

                                                spacing: Cell.w(1)

                                                CellText {
                                                    text: palette.modelData.toString().padEnd(14, " ")
                                                    color: palette.selected ? color.color.secondary : color.color.fgDim
                                                    font: palette.selected ? Cell.fontB : Cell.font
                                                }

                                                Cells {
                                                    w: 7
                                                    h: 1
                                                    color: color.color[palette.modelData] ?? "#000000"
                                                }

                                                Cells {

                                                    w: 8
                                                    h: 1
                                                    color: color.color.bgOverlay

                                                    CellTextField {
                                                        id: palette_hex

                                                        w: parent.w
                                                        h: parent.h
                                                        scroll: false

                                                        disabled: !color.edit

                                                        placeholder: "#RRGGBB"
                                                        focusOnVisible: false
                                                        unfocusOnEntered: true

                                                        autoApply: true
                                                        bindText: color.color[palette.modelData]?.toString().toUpperCase() ?? ""

                                                        color: color.color.fgBase
                                                        invert: color.color.bgSurface
                                                        visual_color: color.color.secondary
                                                        disabled_color: color.color.fgSubtle

                                                        onEntered: input => {
                                                            if (/^#?([a-fA-F0-9]{3}|[a-fA-F0-9]{6})$/.test(input)) {
                                                                color.setBuffer(palette.modelData, Qt.color(input.startsWith("#") ? input : "#" + input).toString());
                                                            }
                                                        }
                                                    }
                                                }

                                                Cells {

                                                    w: 5
                                                    h: 1
                                                    color: color.color.bgOverlay

                                                    CellTextField {
                                                        id: palette_hue

                                                        w: parent.w
                                                        h: parent.h
                                                        scroll: false

                                                        disabled: !color.edit

                                                        placeholder: "Hue"
                                                        focusOnVisible: false
                                                        unfocusOnEntered: true

                                                        autoApply: true
                                                        bindText: Math.max(Math.round(Qt.color(color.color[palette.modelData] || "#000000").hsvHue * 360), 0)

                                                        color: color.color.fgBase
                                                        invert: color.color.bgSurface
                                                        visual_color: color.color.secondary
                                                        disabled_color: color.color.fgSubtle

                                                        onEntered: input => {
                                                            input = parseInt(input);
                                                            if (input >= 0 && input <= 360) {
                                                                color.setBuffer(palette.modelData, Qt.hsva(input / 360, palette_saturation.text / 100, palette_value.text / 100, 1).toString());
                                                            }
                                                        }

                                                        Keys.onPressed: event => {
                                                            if (event.key == Qt.Key_Tab) {
                                                                palette_hue.unFocus();
                                                                palette_saturation.grabFocus();
                                                                event.accepted = true;
                                                            }
                                                        }
                                                    }
                                                }

                                                Cells {

                                                    w: 5
                                                    h: 1
                                                    color: color.color.bgOverlay

                                                    CellTextField {
                                                        id: palette_saturation

                                                        w: parent.w
                                                        h: parent.h
                                                        scroll: false

                                                        disabled: !color.edit

                                                        placeholder: "Sat"
                                                        focusOnVisible: false
                                                        unfocusOnEntered: true

                                                        autoApply: true
                                                        bindText: (Qt.color(color.color[palette.modelData] || "#000000").hsvSaturation * 100).toFixed(1)

                                                        color: color.color.fgBase
                                                        invert: color.color.bgSurface
                                                        visual_color: color.color.secondary
                                                        disabled_color: color.color.fgSubtle

                                                        onEntered: input => {
                                                            input = parseFloat(input);
                                                            if (input >= 0 && input <= 100) {
                                                                color.setBuffer(palette.modelData, Qt.hsva(palette_hue.text / 360, input / 100, palette_value.text / 100, 1).toString());
                                                            }
                                                        }

                                                        Keys.onPressed: event => {
                                                            if (event.key == Qt.Key_Tab) {
                                                                palette_saturation.unFocus();
                                                                palette_value.grabFocus();
                                                                event.accepted = true;
                                                            }
                                                        }
                                                    }
                                                }

                                                Cells {

                                                    w: 5
                                                    h: 1
                                                    color: color.color.bgOverlay

                                                    CellTextField {
                                                        id: palette_value

                                                        w: parent.w
                                                        h: parent.h
                                                        scroll: false

                                                        disabled: !color.edit

                                                        placeholder: "Val"
                                                        focusOnVisible: false
                                                        unfocusOnEntered: true

                                                        autoApply: true
                                                        bindText: (Qt.color(color.color[palette.modelData] || "#000000").hsvValue * 100).toFixed(1)

                                                        color: color.color.fgBase
                                                        invert: color.color.bgSurface
                                                        visual_color: color.color.secondary
                                                        disabled_color: color.color.fgSubtle

                                                        onEntered: input => {
                                                            input = parseFloat(input);
                                                            if (input >= 0 && input <= 100) {
                                                                color.setBuffer(palette.modelData, Qt.hsva(palette_hue.text / 360, palette_saturation.text / 100, input / 100, 1).toString());
                                                            }
                                                        }

                                                        Keys.onPressed: event => {
                                                            if (event.key == Qt.Key_Tab) {
                                                                palette_value.unFocus();
                                                                palette_hex.grabFocus();
                                                                event.accepted = true;
                                                            }
                                                        }
                                                    }
                                                }

                                                CellButton {

                                                    text: "…"

                                                    clickable: color.edit

                                                    color: clickable ? (palette.selected ? color.color.accentStrong : color.color.bgOverlay) : color.color.bgOverlay
                                                    fg: clickable ? (palette.selected ? color.color.onAccent : color.color.fgBase) : color.color.fgSubtle

                                                    onReleased: button => {
                                                        if (button == "L") {
                                                            color.openPicker(palette.modelData);
                                                        }
                                                    }
                                                }
                                            }

                                            CellSeparator {
                                                w: Cell.wCount(palette_label.implicitWidth)
                                                color: color.color.bgOverlay
                                                bg: "transparent"
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        CellSeparator {
                            w: preview.w
                            type: 0
                            color: color.color.accentDim
                            bg: "transparent"
                        }

                        RowLayout {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                            spacing: Cell.w(2)

                            CellButton {

                                visible: !color.edit

                                text: "Apply"

                                clickable: Colors.current != root.result[color.selected]

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg: clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: button => {
                                    if (button == "L") {
                                        Colors.current = root.result[color.selected];
                                    }
                                }
                            }

                            CellButton {

                                visible: color.edit

                                text: "Save"

                                clickable: JSON.stringify(color.color).toLowerCase() != JSON.stringify(color.source).toLowerCase() || root.result[color.selected] != id_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg: clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: button => {
                                    if (button == "L") {
                                        id_textfield.unFocus();
                                        name_textfield.unFocus();
                                        des_textfield.unFocus();
                                        textfield.set("");
                                        if (id_textfield.text == root.result[color.selected]) {
                                            Colors.save(root.result[color.selected], color.buffer);
                                        } else {
                                            Colors.rename(root.result[color.selected], id_textfield.text, color.buffer);
                                            Colors.current = id_textfield.text;
                                        }
                                    }
                                }
                            }

                            CellButton {

                                text: "Fork"

                                // clickable: root.result[color.selected] != "auto"

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg: clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: button => {
                                    if (button == "L") {
                                        id_textfield.unFocus();
                                        name_textfield.unFocus();
                                        des_textfield.unFocus();
                                        textfield.set("");
                                        Colors.fork(root.result[color.selected], color.edit ? id_textfield.text : "");
                                    }
                                }
                            }

                            CellButton {

                                visible: color.edit && color.color_picker

                                text: "Reset"

                                clickable: color_picker.key != "" && color.source[color_picker.key].toLowerCase() != color.color[color_picker.key].toLowerCase()

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg: clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: button => {
                                    if (button == "L") {
                                        color.resetColor();
                                    }
                                }
                            }

                            CellButton {

                                visible: color.edit && des_textfield.focus

                                text: "Reset"

                                clickable: color.source.description != color.color.description || color.source.description != des_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg: clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: button => {
                                    if (button == "L") {
                                        des_textfield.unFocus();
                                        color.setBuffer("description", color.source.description);
                                    }
                                }
                            }

                            CellButton {

                                visible: color.edit && name_textfield.focus

                                text: "Reset"

                                clickable: color.source.name != color.color.name || color.source.name != name_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg: clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: button => {
                                    if (button == "L") {
                                        name_textfield.unFocus();
                                        color.setBuffer("name", color.source.name);
                                    }
                                }
                            }

                            CellButton {

                                visible: color.edit && id_textfield.focus

                                text: "Reset"

                                clickable: root.result[color.selected] != id_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg: clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: button => {
                                    if (button == "L") {
                                        id_textfield.set(root.result[color.selected]);
                                    }
                                }
                            }

                            CellButton {

                                visible: color.edit

                                text: "Reset all"

                                clickable: JSON.stringify(color.color).toLowerCase() != JSON.stringify(color.source).toLowerCase() || root.result[color.selected] != id_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg: clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: button => {
                                    if (button == "L") {
                                        des_textfield.unFocus();
                                        name_textfield.unFocus();
                                        id_textfield.unFocus();
                                        id_textfield.set(root.result[color.selected]);
                                        color.resetEdit();
                                    }
                                }
                            }

                            CellButton {

                                text: "Edit"

                                property bool available: root.result[color.selected] != "auto" && !SettingsInfo.lightMode

                                property Component hint: ColumnLayout {
                                    spacing: 0
                                    CellText {
                                        text: "<b>You cannot edit an auto generated palette</b>"
                                    }
                                    CellSeparator {
                                        w: 41
                                        color: Colors.fgSubtle
                                    }
                                    CellText {
                                        visible: root.result[color.selected] != "auto" && Colors.colors[root.result[color.selected]][SettingsInfo.lightMode ? "light" : "dark"].generated
                                        text: "<i>This palette's " + (SettingsInfo.lightMode ? "light" : "dark") + " mode has been auto generated. Please switch back to " + (SettingsInfo.lightMode ? "dark" : "light") + " mode to edit the original palette.</i>"
                                        preferedW: 41
                                        wrap: true
                                        color: Colors.fgDim
                                    }
                                    CellText {
                                        visible: root.result[color.selected] == "auto"
                                        text: "<i>This palette has been auto generated base on current the wallpaper.</i>"
                                        preferedW: 41
                                        wrap: true
                                        color: Colors.fgDim
                                    }
                                }

                                color: !available ? color.color.bgOverlay : (color.edit ? color.color.accentStrong : color.color.bgOverlay)
                                fg: !available ? color.color.fgSubtle : (color.edit ? color.color.onAccent : color.color.fgBase)

                                onReleased: button => {
                                    const global = mapToGlobal(mouseX, mouseY);
                                    if (button == "L") {
                                        if (available) {
                                            color.toggleEdit();
                                        } else {
                                            HintManager.hint = hint;
                                            HintManager.show(global.x, global.y, 3, "", 0);
                                        }
                                    }
                                }
                            }

                            CellButton {

                                visible: color.edit

                                text: "Remove"

                                clickable: root.colors.length > 1

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg: clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: button => {
                                    if (button == "L") {
                                        const toRemove = root.result[color.selected];
                                        const newSelected = Math.max(color.selected - 1, 0);
                                        textfield.set("");
                                        color.toggleEdit();
                                        color.selected = newSelected;
                                        Colors.current = root.result[newSelected];
                                        Colors.remove(toRemove);
                                    }
                                }
                            }
                        }
                    }
                }

                CellText {

                    visible: root.result.length == 0

                    x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                    y: Cell.centerHCell(implicitHeight, parent.implicitHeight) - Cell.h(1)

                    text: "Nothing to see here"
                    color: Colors.secondary
                }
            }
        }

        CellBox {

            visible: SettingsInfo.hints

            Layout.leftMargin: Cell.w(2)
            Layout.topMargin: Cell.h(2)

            w: 38 + 58
            h: 3

            RowLayout {

                x: Cell.centerWCell(implicitWidth, root.implicitWidth)

                spacing: Cell.w(2)

                CellKeyHint {
                    key: "↑/↓"
                    hint: "Up/Down"
                }

                CellKeyHint {
                    visible: !TextFieldManager.active || textfield.focus
                    key: "Tab"
                    hint: "Switch tab"
                }

                CellKeyHint {
                    key: "Enter"
                    disabled: Colors.current == root.result[color.selected]
                    hint: "Apply selected theme"
                }

                CellKeyHint {
                    key: "Esc"
                    hint: if (color.edit && !color.color_picker && !TextFieldManager.active) {
                        return "Exit editing mode";
                    } else if (color.color_picker && !TextFieldManager.active) {
                        return "Exit color picker";
                    } else if (TextFieldManager.active && !textfield.focus) {
                        return "Exit textfield";
                    } else
                        return "Exit"
                }
            }
        }
    }

    component PreviewWidget: RowLayout {

        spacing: 0

        property string label: "Buttons"
        property int label_width: 14

        CellText {
            Layout.alignment: Qt.AlignTop
            text: parent.label
            color: color.color.secondary
            preferedW: parent.label_width
        }
    }

    component WidgetSep: CellSeparator {

        w: preview.w - 2
        color: color.color.bgOverlay
        bg: "transparent"
    }
}
