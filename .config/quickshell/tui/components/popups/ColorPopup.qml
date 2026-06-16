pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick
import Qt5Compat.GraphicalEffects

CellPopup {

    id: root

    w: Cell.wCount(popup.implicitWidth)
    h: Cell.hCount(popup.implicitHeight)

    property bool minimal: SettingsInfo.minimal

    property var result: Object.keys(Colors.colors)

    property var colors: Object.keys(Colors.colors)

    escapeToClose: textfield.focus

    function getNextCopyNumber(array, baseString) {
        let maxCounter = 0;

        array.forEach(item => {
            if (item === baseString) {
                maxCounter = Math.max(maxCounter, 0);
            } else if (item.startsWith(`${baseString}_`)) {
                // Extract the number after the underscore
                const parts = item.split("_");
                const num = parseInt(parts[parts.length - 1], 10);
                if (!isNaN(num)) {
                    maxCounter = Math.max(maxCounter, num);
                }
            }
        });

        return maxCounter + 1;
    }

    ShortcutHandler {
        shortcuts: [
            {
                binds: "Up",
                action: () => {
                    color.selected = Math.max(color.selected - 1,0)
                    if (color.selected - list.offset/2 < 0) {
                        list.offset = Math.floor(color.selected/13)*26
                    }
                }
            },
            {
                binds: "Down",
                action: () => {
                    color.selected = Math.min(color.selected + 1,root.result.length-1)
                    if (color.selected - list.offset/2 >= 13) {
                        list.offset = Math.floor(color.selected/13)*26
                    }
                }
            },
            {
                binds: "Tab",
                active: !TextFieldManager.active || textfield.focus,
                action: () => {
                    preview_tab.selected = (preview_tab.selected + 1 + 2)%2
                }
            },
            {
                binds: "Return",
                active: Colors.current != root.result[color.selected],
                action: () => {
                    Colors.current = root.result[color.selected]
                }
            },
            {
                binds: "Escape",
                active: color.edit && !TextFieldManager.active,
                action: () => {
                    if (color.color_picker) {
                        color.color_picker = false
                    } else {
                        color.toggleEdit()
                    }
                }
            },
        ]
    }

    onVisibleChanged: {
        if (color.edit) {
            color.toggleEdit()
        }
        //resetList()
    }

    function resetList() {
        color.selected = result.findIndex(item => item == Colors.current)
        if (color.selected == -1) {
            color.selected = 0
        }
        list.offset = Math.floor(color.selected/13)*26
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

                property var source: Colors.colors[root.result[selected]] ?? Colors.dummy

                property var color: source

                property int selected: 0

                property int push: 0

                property int h: 28

                signal unFocusPalette()

                function openPicker(key: string) {
                    des_textfield.unFocus()
                    name_textfield.unFocus()
                    unFocusPalette()
                    if (color_picker.key == "") {
                        color.color_picker = true
                        color_picker.key = key
                        color_picker.buffer = Qt.color(color.color[key])
                    } else if (color_picker.key != key){
                        color_picker.key = key
                        color_picker.buffer = Qt.color(color.color[key])
                    } else {
                        color.color_picker = false
                    }
                }

                function resetColor() {
                    color.buffer[color_picker.key] = source[color_picker.key]
                    colorChanged()
                    color_picker.buffer = Qt.color(color.color[color_picker.key])
                }

                function resetEdit() {
                    color.buffer = JSON.parse(JSON.stringify(color.source))
                    colorChanged()
                    color_picker.buffer = Qt.color(color.color[color_picker.key])
                }

                function toggleEdit() {
                    if (root.result[color.selected] == "auto") return
                    edit = !edit
                    des_textfield.unFocus()
                    name_textfield.unFocus()
                    if (edit) {
                        push = preview_tab.selected
                        id_textfield.set(root.result[color.selected])
                        textfield.unFocus()
                        preview_tab.selected = 1
                        color.buffer = JSON.parse(JSON.stringify(color.source))
                        color.color = Qt.binding(()=>color.buffer)
                    } else {
                        id_textfield.set("")
                        preview_tab.selected = push
                        textfield.grabFocus()
                        color.color = Qt.binding(()=>color.source)
                        color.color_picker = false
                    }

                }

                Component.onCompleted: {
                    root.resultChanged.connect(()=> {
                        //root.resetList()
                    })
                    Colors.currentChanged.connect(()=> {
                        //root.resetList()
                    })
                }

            }

            CellBox {

                w: 38
                h: color.h+2

                ColumnLayout {

                    visible: !color.color_picker

                    spacing: 0

                    CellScrollView {

                        id: list

                        w: 36
                        h: color.h-2

                        onContentHChanged: {
                            root.resetList()
                        }

                        onMaxOffsetChanged: {
                            list.snapBack()
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

                                        property var source: Colors.colors[modelData] ?? Colors.dummy

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

                                            visible: !color.edit

                                            id: theme_mouse

                                            anchors.fill: parent

                                            onReleased: (button) => {
                                                if (button == "L") {
                                                    color.selected = theme.index
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

                                w: 26
                                h: 1

                                placeholder: "Search themes"

                                focusOnVisible: !color.edit

                                onVisibleChanged: {
                                    if (visible) {
                                        root.result = root.colors
                                    }
                                }

                                onFocusChanged: {
                                    if (color.edit && focus) {
                                        color.toggleEdit()
                                    }
                                }

                                onTextInput: (input) => {
                                    if (input == "") {
                                        root.result = root.colors
                                    } else {
                                        root.result = root.colors.filter((item) => {
                                            return Colors.colors[item].name.toLowerCase().includes(input.toLowerCase())
                                            || Colors.colors[item].description.toLowerCase().includes(input.toLowerCase())
                                            || item.includes(input.toLowerCase())
                                        })
                                    }
                                }

                            }

                            CellButton {

                                text: "Light"

                                color: SettingsInfo.lightMode ? Colors.accentStrong : Colors.bgOverlay
                                fg: SettingsInfo.lightMode ? Colors.onAccent : Colors.fgBase

                                onReleased: (button) => {
                                    if (button == "L") {
                                        SettingsInfo.toggle("userLightMode")
                                    }
                                }

                            }
                        }

                    }


                }

                Cells {

                    id: color_picker

                    visible: color.color_picker

                    onVisibleChanged: {
                        if (!visible) {
                            key = ""
                        }
                    }

                    property string key: "bgSurface"

                    property color buffer: "black"

                    onBufferChanged: {
                        if (buffer.hsvHue < 0) {
                            buffer.hsvHue = 0
                        }
                        sv_square.requestPaint()
                        color.buffer[key] = buffer.toString()
                        color.colorChanged()
                    }

                    w: 36
                    h: color.h

                    color: "transparent"

                    ColumnLayout {

                        y: Cell.h(0)

                        spacing: Cell.h(0)

                        RowLayout {

                            Layout.leftMargin: Cell.w(3)

                            spacing: 0

                            Cells {

                                w: 15
                                h: 1.5
                                color: Qt.color(color.source[color_picker.key] || "#000000")

                            }

                            Cells {

                                w: 15
                                h: 1.5
                                color: color_picker.buffer

                            }

                        }

                        CellText {
                            text: " "
                        }

                        Canvas {

                            Layout.leftMargin: Cell.w(3)

                            id: sv_square

                            implicitWidth: Cell.w(30)
                            implicitHeight: Cell.h(15)

                            onPaint: {

                                var ctx = getContext("2d")

                                for (let i = 0; i < implicitWidth; i += Cell.w(1)) {

                                    for (let j = 0; j < implicitHeight; j += Cell.h(1)) {

                                        ctx.fillStyle = Qt.hsva(
                                            color_picker.buffer.hsvHue,
                                            i/(implicitWidth-Cell.w(1)),
                                            1-j/(implicitHeight-Cell.h(1)),
                                            1
                                        )
                                        ctx.fillRect(i, j, Cell.w(1), Cell.h(1))

                                    }

                                }

                            }

                            CellText {

                                x: Cell.w(Math.round(color_picker.buffer.hsvSaturation*29))
                                y: Cell.h(Math.round((1-color_picker.buffer.hsvValue)*14))

                                text: "✕"

                                color: Qt.hsva(
                                    color_picker.buffer.hsvHue,
                                    (1-color_picker.buffer.hsvSaturation)*0.8,
                                    color_picker.buffer.hsvValue > 0.5 ? 0 : 1,
                                    1
                                )


                                font: Cell.fontBB
                            }

                            MouseControl {

                                anchors.fill: parent

                                function setColor() {
                                    if (buttonDown == "L") {
                                        color_picker.buffer.hsvSaturation = Math.max(Math.min(mouseX/(parent.implicitWidth-Cell.w(0.5)),1),0)
                                        color_picker.buffer.hsvValue = Math.max(Math.min(1-mouseY/(parent.implicitHeight-Cell.h(0.5)),1),0)
                                    }
                                }

                                onReleased: {
                                    setColor()
                                }
                                onPressed: {
                                    setColor()
                                }
                                onMoved: {
                                    setColor()
                                }

                            }

                        }

                        component Slider: RowLayout {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, color_picker.implicitWidth)

                            property real value: color_picker.buffer.hsvHue*100

                            property color knob_color: Qt.hsva(color_picker.buffer.hsvHue,1,1,1)

                            property string placeholder: "Hue"
                            property var slider: color_slider

                            property var render: () => {}

                            signal adjusted(percent: real)
                            signal entered(percent: real)

                            signal tabbed()

                            function grabFocus() {
                                color_picker_slider.grabFocus()
                            }

                            function unFocus() {
                                color_picker_slider.unFocus()
                            }

                            spacing: Cell.w(2)

                            CellProgressSquare {

                                w: 25
                                h: 1

                                percent: parent.value

                                color: "transparent"
                                fg: "transparent"

                                percentSmoother: 100

                                wheelInterval: 0.1

                                interactive: true

                                syncDelay: 0

                                onAdjusted: (percent) => parent.adjusted(percent)

                                Canvas {

                                    id: color_slider

                                    implicitWidth: Cell.w(parent.w)
                                    implicitHeight: Cell.h(parent.h)

                                    onPaint: parent.parent.render()

                                }

                                Cells {

                                    x: Cell.w(Math.round((parent.percent/100)*(parent.w-1)))

                                    w: 1
                                    h: 1

                                    color: parent.parent.knob_color

                                }

                            }

                            Cells {

                                w: 5
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {

                                    id: color_picker_slider

                                    w: parent.w
                                    h: parent.h

                                    focusOnVisible: false
                                    unfocusOnEntered: true

                                    autoApply: true
                                    bindText: parent.parent.value.toFixed(1)

                                    placeholder: parent.placeholder ?? ""

                                    onEntered: (input) => {
                                        parent.parent.entered(input)
                                    }

                                    Keys.onPressed: (event) => {
                                        parent.parent.tabbed()
                                    }

                                }

                            }

                        }

                        CellText {
                            text: " "
                        }

                        CellSeparator {
                            w: color_picker.w
                            color: Colors.accentDim
                        }

                        Slider {

                            id: slider_hue

                            value: color_picker.buffer.hsvHue*100
                            knob_color: Qt.hsva(color_picker.buffer.hsvHue,1,1,1)
                            placeholder: "Hue"
                            render: () => {

                                var ctx = slider.getContext("2d")

                                const width = Cell.w(26)
                                const height = Cell.h(1)

                                for (let i = 0; i < width; i += Cell.w(1)) {
                                    ctx.fillStyle = Qt.hsva(
                                        i/(width-Cell.w(1)),
                                        1,
                                        1,
                                        1
                                    )
                                    ctx.fillRect(i, (Cell.h(1)-Cell.w(1))/2, Cell.w(1), Cell.w(1))
                                }

                            }

                            onAdjusted: (percent) => {
                                sv_square.requestPaint()
                                percent = Math.max(Math.min(percent,100),0)
                                color_picker.buffer.hsvHue = percent.toFixed(1)/100
                            }

                            onEntered: (percent) => {
                                sv_square.requestPaint()
                                percent = Math.max(Math.min(parseFloat(percent),100),0)
                                color_picker.buffer.hsvHue = percent.toFixed(1)/100
                            }

                            onTabbed: {
                                slider_hue.unFocus()
                                slider_saturation.grabFocus()
                            }

                        }

                        CellSeparator {
                            w: color_picker.w
                            padding: 1
                            color: Colors.bgOverlay
                        }

                        Slider {

                            id: slider_saturation

                            value: color_picker.buffer.hsvSaturation*100
                            knob_color: Qt.hsva(1,color_picker.buffer.hsvSaturation,1,1)
                            placeholder: "Hue"
                            render: () => {

                                var ctx = slider.getContext("2d")

                                const width = Cell.w(26)
                                const height = Cell.h(1)

                                for (let i = 0; i < width; i += Cell.w(1)) {
                                    ctx.fillStyle = Qt.hsva(
                                        1,
                                        i/(width-Cell.w(1)),
                                        1,
                                        1
                                    )
                                    ctx.fillRect(i, (Cell.h(1)-Cell.w(1))/2, Cell.w(1), Cell.w(1))
                                }

                            }

                            onAdjusted: (percent) => {
                                percent = Math.max(Math.min(percent,100),0)
                                color_picker.buffer.hsvSaturation = percent.toFixed(1)/100
                            }

                            onEntered: (percent) => {
                                percent = Math.max(Math.min(parseFloat(percent),100),0)
                                color_picker.buffer.hsvSaturation = percent.toFixed(1)/100
                            }

                            onTabbed: {
                                slider_saturation.unFocus()
                                slider_value.grabFocus()
                            }

                        }

                        CellSeparator {
                            w: color_picker.w
                            padding: 1
                            color: Colors.bgOverlay
                        }

                        Slider {

                            id: slider_value

                            value: color_picker.buffer.hsvValue*100
                            knob_color: Qt.hsva(1,0,color_picker.buffer.hsvValue,1)
                            placeholder: "Hue"
                            render: () => {

                                var ctx = slider.getContext("2d")

                                const width = Cell.w(26)
                                const height = Cell.h(1)

                                for (let i = 0; i < width; i += Cell.w(1)) {
                                    ctx.fillStyle = Qt.hsva(
                                        1,
                                        0,
                                        i/(width-Cell.w(1)),
                                        1
                                    )
                                    ctx.fillRect(i, (Cell.h(1)-Cell.w(1))/2, Cell.w(1), Cell.w(1))
                                }

                            }

                            onAdjusted: (percent) => {
                                percent = Math.max(Math.min(percent,100),0)
                                color_picker.buffer.hsvValue = percent.toFixed(1)/100
                            }

                            onEntered: (percent) => {
                                percent = Math.max(Math.min(parseFloat(percent),100),0)
                                color_picker.buffer.hsvValue = percent.toFixed(1)/100
                            }

                            onTabbed: {
                                slider_value.unFocus()
                                slider_hue.grabFocus()
                            }

                        }

                        CellSeparator {
                            w: color_picker.w
                            padding: 1
                            color: Colors.bgOverlay
                        }

                        RowLayout {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, color_picker.implicitWidth)

                            spacing: Cell.w(1)

                            component Detail: Cells {

                                id: color_picker_detail

                                w: 8
                                h: 1
                                color: Colors.bgOverlay

                                property string placeholder: "#RRGGBB"
                                property string bindText: color_picker.buffer.toString()

                                signal entered(input: string)
                                signal tabbed()

                                function unFocus() {
                                    color_picker_rgb.unFocus()
                                }

                                function grabFocus() {
                                    color_picker_rgb.grabFocus()
                                }

                                CellTextField {

                                    id: color_picker_rgb

                                    w: parent.w
                                    h: parent.h
                                    scroll: false

                                    unfocusOnEntered: true

                                    placeholder: parent.placeholder
                                    focusOnVisible: false

                                    autoApply: true
                                    bindText: parent.bindText

                                    onEntered: (input) => {
                                        parent.entered(input)
                                    }

                                    Keys.onPressed: (event) => {
                                        if (event.key == Qt.Key_Tab) {
                                            color_picker_detail.tabbed()
                                        }
                                    }

                                }

                            }

                            CellText {
                                text: "HEX"
                            }

                            Detail {

                                id: color_picker_hex

                                w: 8
                                placeholder: "#RRGGBB"
                                bindText: color_picker.buffer.toString()

                                onEntered: (input) => {
                                    if (/^#?([a-fA-F0-9]{3}|[a-fA-F0-9]{6})$/.test(input)) {
                                        color_picker.buffer = Qt.color(input.startsWith("#") ? input : "#" + input)
                                    }
                                }

                                onTabbed:{
                                    color_picker_hex.unFocus()
                                    color_picker_r.grabFocus()
                                }

                            }

                            CellText {
                                text: "R"
                            }

                            Detail {

                                id: color_picker_r

                                w: 4
                                placeholder: "RRR"
                                bindText: Math.round(color_picker.buffer.r*255)

                                onEntered: (input) => {
                                    input = parseInt(input)
                                    if (input >= 0 && input <= 255 ) {
                                        color_picker.buffer.r = input/255
                                    }
                                }

                                onTabbed:{
                                    color_picker_r.unFocus()
                                    color_picker_g.grabFocus()
                                }

                            }

                            CellText {
                                text: "G"
                            }

                            Detail {

                                id: color_picker_g

                                w: 4
                                placeholder: "GGG"
                                bindText: Math.round(color_picker.buffer.g*255)

                                onEntered: (input) => {
                                    input = parseInt(input)
                                    if (input >= 0 && input <= 255 ) {
                                        color_picker.buffer.g = input/255
                                    }
                                }

                                onTabbed:{
                                    color_picker_g.unFocus()
                                    color_picker_b.grabFocus()
                                }

                            }

                            CellText {
                                text: "B"
                            }

                            Detail {

                                id: color_picker_b

                                w: 4
                                placeholder: "BBB"
                                bindText: Math.round(color_picker.buffer.b*255)

                                onEntered: (input) => {
                                    input = parseInt(input)
                                    if (input >= 0 && input <= 255 ) {
                                        color_picker.buffer.b = input/255
                                    }
                                }

                                onTabbed:{
                                    color_picker_b.unFocus()
                                    color_picker_hex.grabFocus()
                                }

                            }


                        }

                    }

                }

            }

            CellBox {

                w: 58
                h: color.h+2

                border {
                    type: 4
                    color: root.result.length > 0 ? color.color.accentStrong : Colors.accentStrong
                }

                color: root.result.length > 0 ? color.color.bgSurface : Colors.bgSurface

                Cells {

                    visible: root.result.length > 0 

                    id: preview

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
                            preferedW: preview.w-2
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

                                color: color.color.fgBase
                                invert: color.color.bgSurface
                                visual_color: color.color.secondary
                                disabled_color: color.color.fgSubtle

                                autoApply: true
                                bindText: color.color.name
                                wrap: true

                                onEntered: (input) => {
                                    color.buffer.name = input
                                    color.colorChanged()
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
                            preferedW: preview.w-2
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

                                color: color.color.fgBase
                                invert: color.color.bgSurface
                                visual_color: color.color.secondary
                                disabled_color: color.color.fgSubtle

                                autoApply: true
                                bindText: color.color.description
                                wrap: true

                                onEntered: (input) => {
                                    color.buffer.description = input
                                    color.colorChanged()
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

                            onVisibleChanged: {
                                selected = 0
                            }

                            id: preview_tab

                            w: preview.w

                            items: [
                                "Widgets",
                                "Color list",
                            ]

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

                                visible: preview_tab.selected == 0

                                id: preview_widgets

                                Layout.leftMargin: Cell.w(1)

                                property int label_width: 14
                                property int widgets_width: preview.w - 2 - label_width

                                spacing: 0

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
                                                if (!focus) textfield.grabFocus()
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
                                            { label: "Item 1", action: () => {selected = 0} },
                                            { label: "Item 2", action: () => {selected = 1} },
                                            { label: "Item 3", action: () => {selected = 2} },
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
                                                this.percent = raw_percent
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

                                        model: [
                                            "bgBase",
                                            "bgSurface",
                                            "bgOverlay",
                                            "fgBase",
                                            "onAccent",
                                            "fgDim",
                                            "fgSubtle",
                                            "accentStrong",
                                            "accentDim",
                                            "secondary",
                                            "info",
                                            "success",
                                            "warning",
                                            "danger",
                                            "borderActive",
                                            "borderInactive",
                                        ]

                                        delegate: ColumnLayout {

                                            id: palette

                                            required property string modelData

                                            property bool selected: color_picker.key == modelData

                                            Component.onCompleted: {
                                                color.unFocusPalette.connect(()=>{
                                                    palette_hex?.unFocus()
                                                    palette_hue?.unFocus()
                                                    palette_saturation?.unFocus()
                                                    palette_value?.unFocus()

                                                })
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

                                                        onEntered: (input) => {
                                                            if (/^#?([a-fA-F0-9]{3}|[a-fA-F0-9]{6})$/.test(input)) {
                                                                color.buffer[palette.modelData] = Qt.color(input.startsWith("#") ? input : "#" + input).toString()
                                                                color.colorChanged()
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
                                                        bindText: Math.max(Math.round(Qt.color(color.color[palette.modelData] || "#000000").hsvHue*360),0)

                                                        color: color.color.fgBase
                                                        invert: color.color.bgSurface
                                                        visual_color: color.color.secondary
                                                        disabled_color: color.color.fgSubtle

                                                        onEntered: (input) => {
                                                            input = parseInt(input)
                                                            if (input >= 0 && input <= 360) {
                                                                color.buffer[palette.modelData] = Qt.hsva(input/360,palette_saturation.text/100,palette_value.text/100,1).toString()
                                                                color.colorChanged()
                                                            }
                                                        }

                                                        Keys.onPressed: (event) => {
                                                            if (event.key == Qt.Key_Tab) {
                                                                palette_hue.unFocus()
                                                                palette_saturation.grabFocus()
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
                                                        bindText: (Qt.color(color.color[palette.modelData] || "#000000").hsvSaturation*100).toFixed(1)

                                                        color: color.color.fgBase
                                                        invert: color.color.bgSurface
                                                        visual_color: color.color.secondary
                                                        disabled_color: color.color.fgSubtle

                                                        onEntered: (input) => {
                                                            input = parseFloat(input)
                                                            if (input >= 0 && input <= 100) {
                                                                color.buffer[palette.modelData] = Qt.hsva(palette_hue.text/360,input/100,palette_value.text/100,1).toString()
                                                                color.colorChanged()
                                                            }
                                                        }

                                                        Keys.onPressed: (event) => {
                                                            if (event.key == Qt.Key_Tab) {
                                                                palette_saturation.unFocus()
                                                                palette_value.grabFocus()
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
                                                        bindText: (Qt.color(color.color[palette.modelData] || "#000000").hsvValue*100).toFixed(1)

                                                        color: color.color.fgBase
                                                        invert: color.color.bgSurface
                                                        visual_color: color.color.secondary
                                                        disabled_color: color.color.fgSubtle

                                                        onEntered: (input) => {
                                                            input = parseFloat(input)
                                                            if (input >= 0 && input <= 100) {
                                                                color.buffer[palette.modelData] = Qt.hsva(palette_hue.text/360,palette_saturation.text/100,input/100,1).toString()
                                                                color.colorChanged()
                                                            }
                                                        }

                                                        Keys.onPressed: (event) => {
                                                            if (event.key == Qt.Key_Tab) {
                                                                palette_value.unFocus()
                                                                palette_hex.grabFocus()
                                                            }
                                                        }

                                                    }

                                                }

                                                CellButton {

                                                    text: "…"

                                                    clickable: color.edit

                                                    color: clickable ? (palette.selected ? color.color.accentStrong : color.color.bgOverlay) : color.color.bgOverlay
                                                    fg:    clickable ? (palette.selected ? color.color.onAccent : color.color.fgBase) : color.color.fgSubtle

                                                    onReleased: (button) => {
                                                        if (button == "L") {
                                                            color.openPicker(palette.modelData)
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
                                fg:    clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        Colors.current = root.result[color.selected]
                                    }
                                }

                            }

                            CellButton {

                                visible: color.edit

                                text: "Save"

                                clickable: JSON.stringify(color.color).toLowerCase() != JSON.stringify(color.source).toLowerCase() || root.result[color.selected] != id_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg:    clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        id_textfield.unFocus()
                                        name_textfield.unFocus()
                                        des_textfield.unFocus()
                                        textfield.set("")
                                        const selected = color.selected
                                        if (root.result[color.selected] == id_textfield.text) {
                                            Colors.colors[root.result[color.selected]] = color.buffer
                                        } else {
                                            const new_color = {}
                                            Object.keys(Colors.colors).forEach(key => {
                                                if (key == root.result[color.selected]) {
                                                    new_color[id_textfield.text] = Colors.colors[root.result[color.selected]]; // Insert the new key name with the old value
                                                } else {
                                                    new_color[key] = Colors.colors[key];       // Keep everything else exactly as it was
                                                }
                                            })  
                                            Colors.colors = new_color
                                            Colors.current = id_textfield.text
                                        }
                                        Colors.colorsChanged()
                                        color.selected = selected
                                        color.toggleEdit()
                                        root.result = root.colors
                                        Colors.save() // Careful now
                                    }
                                }

                            }

                            CellButton {

                                visible: color.edit

                                text: "Fork"

                                clickable: JSON.stringify(color.color).toLowerCase() != JSON.stringify(color.source).toLowerCase() || root.result[color.selected] != id_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg:    clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        textfield.set("")
                                        if (root.result[color.selected] == id_textfield.text) {
                                            Colors.colors[`${root.result[color.selected]}_${root.getNextCopyNumber(root.result, root.result[color.selected])}`] = color.buffer
                                        } else {
                                            Colors.colors[id_textfield.text] = color.buffer
                                            Colors.current = id_textfield.text
                                        }
                                        Colors.colorsChanged()
                                        color.toggleEdit()
                                        root.result = root.colors
                                        color.selected = root.result.length-1
                                        Colors.save() // Careful now
                                    }
                                }

                            }

                            CellButton {

                                visible: color.edit && color.color_picker

                                text: "Reset"

                                clickable: color_picker.key != "" && color.source[color_picker.key].toLowerCase() != color.color[color_picker.key].toLowerCase()

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg:    clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        color.resetColor()
                                    }
                                }

                            }

                            CellButton {

                                visible: color.edit && des_textfield.focus

                                text: "Reset"

                                clickable: color.source.description != color.color.description || color.source.description != des_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg:    clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        des_textfield.unFocus()
                                        color.buffer.description = color.source.description
                                        color.colorChanged()
                                    }
                                }

                            }

                            CellButton {

                                visible: color.edit && name_textfield.focus

                                text: "Reset"

                                clickable: color.source.name != color.color.name || color.source.name != name_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg:    clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        name_textfield.unFocus()
                                        color.buffer.name = color.source.name
                                        color.colorChanged()
                                    }
                                }

                            }

                            CellButton {

                                visible: color.edit && id_textfield.focus

                                text: "Reset"

                                clickable: root.result[color.selected] != id_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg:    clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        id_textfield.set(root.result[color.selected])
                                    }
                                }

                            }

                            CellButton {

                                visible: color.edit

                                text: "Reset all"

                                clickable: JSON.stringify(color.color).toLowerCase() != JSON.stringify(color.source).toLowerCase() || root.result[color.selected] != id_textfield.text

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg:    clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        des_textfield.unFocus()
                                        name_textfield.unFocus()
                                        id_textfield.unFocus()
                                        id_textfield.set(root.result[color.selected])
                                        color.resetEdit()
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
                                        visible: root.result[color.selected] != "auto" && SettingsInfo.lightMode
                                        text: "<i>This palette's light mode has been auto generated. Please switch back to dark mode to edit the original palette.</i>"
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
                                fg:    !available ? color.color.fgSubtle : (color.edit ? color.color.onAccent : color.color.fgBase)

                                onReleased: (button) => {
                                    const global = mapToGlobal(mouseX, mouseY)
                                    if (button == "L") {
                                        if (available) {
                                            color.toggleEdit()
                                        } else {
                                            HintManager.hint = hint
                                            HintManager.show(global.x, global.y, 3, "", 0)
                                        }
                                    }
                                }


                            }

                            CellButton {

                                visible: color.edit

                                text: "Remove"

                                clickable: root.colors.length > 1

                                color: clickable ? [color.color.accentStrong, color.color.bgOverlay] : color.color.bgOverlay
                                fg:    clickable ? [color.color.onAccent, color.color.fgBase] : color.color.fgSubtle

                                onReleased: (button) => {
                                    if (button == "L") {
                                        textfield.set("")
                                        delete Colors.colors[root.result[color.selected]]
                                        Colors.current = root.result[Math.max(color.selected-1,1)]
                                        Colors.colorsChanged()
                                        color.toggleEdit()
                                        root.result = root.colors
                                        color.selected = Math.max(color.selected-1,0)
                                        Colors.save() // Careful now
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

            w: 38+58
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
                        return "Exit editing mode"
                    } else if (color.color_picker && !TextFieldManager.active) {
                        return "Exit color picker"
                    } else if (TextFieldManager.active && !textfield.focus) {
                        return "Exit textfield"
                    } else return "Exit"
                }

            }

        }

    }


}
