pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick
import Qt5Compat.GraphicalEffects

CellPopup {

    id: root

    w: 100
    h: Cell.hCount(layout.implicitHeight) + 1

    property var result: Object.keys(Colors.colors)
    property var colors: Object.keys(Colors.colors)

    escapeToClose: textfield.focus

    CellBox {

        w: root.w + 2
        h: root.h + 2

        ColumnLayout {

            id: layout

            property string current: Colors.current

            onVisibleChanged: {
                layout.edit = false
            }

            onSelectedChanged: {
                layout.edit = false
            }

            onEditChanged: {
                if (!layout.edit) {
                    textfield.disabled = false
                    textfield.grabFocus()
                }
            }

            property bool edit: false

            spacing: 0

            property int selected: 0
            property var color: Colors.colors[root.result[selected]] ?? {
                "name": "",
                "description": "",
                "bgBase": "",
                "bgSurface": "",
                "bgOverlay": "",
                "fgBase": "",
                "onAccent": "",
                "fgDim": "",
                "fgSubtle": "",
                "accentStrong": "",
                "accentDim": "",
                "secondary": "",
                "info": "",
                "success": "",
                "warning": "",
                "danger": "",
            }

            RowLayout {

                spacing: 0

                ColumnLayout {

                    Layout.alignment: Qt.AlignTop

                    spacing: 0

                    RowLayout {

                        spacing: 0

                        ColumnLayout {

                            visible: !edit.color_picker

                            spacing: 0

                            Cells {

                                Layout.alignment: Qt.AlignTop

                                w: 37
                                h: 21

                                color: "transparent"

                                CellScrollView {

                                    id: list

                                    w: parent.w
                                    h: parent.h

                                    onVisibleChanged: {
                                        reset()
                                    }

                                    ColumnLayout {

                                        spacing: 0

                                        Repeater {

                                            model: root.result

                                            delegate: Cells {

                                                id: color

                                                required property int index
                                                required property string modelData

                                                property var source: Colors.colors[modelData]

                                                property bool selected: Colors.current == modelData
                                                property bool highlighted: layout.selected == index

                                                w: list.contentW
                                                h: 2

                                                color: highlighted ? color.source.accentStrong : (color_mouse.hovered ? color.source.bgOverlay : "transparent")

                                                ColumnLayout {

                                                    spacing: 0

                                                    CellText {

                                                        Layout.leftMargin: Cell.w(1)

                                                        text: color.source.name
                                                        color: color.highlighted ? color.source.onAccent : (color_mouse.hovered ? color.source.fgBase : Colors.fgBase)
                                                        preferedW: color.w - 2
                                                        font: Cell.fontB
                                                    }

                                                    CellSeparator {
                                                        w: color.w
                                                        type: 2
                                                        color: Colors.bgOverlay
                                                    }

                                                }

                                                MouseControl {

                                                    id: color_mouse

                                                    anchors.fill: parent
                                                    anchors.topMargin: -Cell.h(0.5)
                                                    anchors.bottomMargin: Cell.h(0.5)

                                                    onReleased: (button) => {
                                                        if (button == "L") {
                                                            layout.selected = color.index
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                            }

                            CellSeparator {

                                w: 37
                                type: 0
                                color: Colors.bgOverlay

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, list.implicitWidth)

                                spacing: Cell.w(2)

                                CellButton {

                                    text: "Edit"

                                    clickable: !layout.edit

                                    fg: clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle
                                    color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay

                                    onReleased: (button) => {
                                        if (button == "L") {
                                            layout.edit = true
                                            edit.color_buffer = layout.color
                                            edit_name.set(layout.color["name"])
                                            edit_des.set(layout.color["description"])
                                        }
                                    }

                                }

                                CellButton {

                                    text: "Add"

                                    fg: [Colors.onAccent, Colors.fgBase]
                                    color: [Colors.accentStrong, Colors.bgOverlay]

                                }

                            }

                        }

                        ColumnLayout {

                            visible: edit.color_picker

                            spacing: 0

                            onVisibleChanged: {
                                hue.requestPaint()
                                saturation.requestPaint()
                                value.requestPaint()
                                color_wheel.requestPaint()
                            }

                            Cells {

                                id: color_picker

                                property string key: ""

                                property color buffer: edit.color_buffer[key]

                                onBufferChanged: {
                                    buffer.hsvHue = Math.max(Math.min(buffer.hsvHue,1),0)
                                    edit.color_buffer[key] = buffer.toString()
                                    edit.color_bufferChanged()
                                }

                                w: 37
                                h: 16

                                color: "transparent"

                                Cells {

                                    x: Cell.w(4)
                                    y: Cell.h(1)

                                    w: parent.w - 8
                                    h: 14

                                    color: "transparent"

                                    property int value: Math.min(Math.round((1-color_picker.buffer.hsvValue)*(h-1)),h-1)
                                    property int sat: Math.min(Math.round((color_picker.buffer.hsvSaturation)*(w-0.5)),w-1)

                                    Behavior on value {NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.OutCubic
                                    }}
                                    Behavior on sat {NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.OutCubic
                                    }}

                                    Canvas {

                                        id: color_wheel

                                        implicitWidth: Cell.w(parent.w)
                                        implicitHeight: Cell.h(parent.h)

                                        property real wheel_hue: Math.max(Math.min(color_picker.buffer.hsvHue,1),0)

                                        Behavior on wheel_hue {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        onWheel_hueChanged: {
                                            requestPaint()
                                        }

                                        onPaint: {

                                            var ctx = getContext("2d")

                                            for (let i = 0; i < implicitWidth; i += Cell.w(1)) {
                                                for (let j = 0; j < implicitHeight; j += Cell.h(1)) {
                                                    ctx.fillStyle = Qt.hsva(wheel_hue,i/(implicitWidth-Cell.w(1)),1-(j/(implicitHeight-Cell.h(1))),1)
                                                    ctx.fillRect(i,j,Cell.w(1),Cell.h(1))
                                                }
                                            }
                                        }

                                    }

                                    CellText {
                                        x: Cell.w(parent.sat)
                                        y: Cell.h(parent.value)


                                        text: "+"
                                        font: Cell.fontB
                                        color: Qt.hsva(
                                            color_picker.buffer.hsvHue,
                                            1-color_picker.buffer.hsvSaturation,
                                            color_picker.buffer.hsvValue < 0.5 ? 1 : 0,
                                            1
                                        )
                                    }

                                    MouseControl {

                                        id: color_wheel_mouse

                                        implicitWidth: Cell.w(parent.w)
                                        implicitHeight: Cell.h(parent.h)

                                        function changeColor(x, y) {
                                            color_picker.buffer.hsvSaturation = Math.min(Math.max(x/implicitWidth,0),1)
                                            color_picker.buffer.hsvValue = Math.min(Math.max(1-(y/implicitHeight),0),1)
                                        }

                                        onPressed: (button) => {
                                            if (button == "L") {
                                                changeColor(mouseX, mouseY)
                                            }
                                        }

                                        onMoved: {
                                            if (buttonDown == "L") {
                                                changeColor(mouseX, mouseY)
                                            }
                                        }

                                    }

                                }

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                                spacing: 0

                                CellText {
                                    text: "H "
                                }

                                CellProgressSquare {

                                    w: 28
                                    h: 1

                                    percent: Math.max(Math.min(color_picker.buffer.hsvHue,1),0)*100

                                    percentSmoother: 200

                                    wheelInterval: 1

                                    interactive: true

                                    onAdjusted: (percent) => {
                                        color_picker.buffer.hsvHue = percent/100
                                    }

                                    onPercentChanged: {
                                        saturation.requestPaint()
                                        hue.requestPaint()
                                        color_wheel.requestPaint()
                                    }

                                    Canvas {

                                        id: hue

                                        implicitWidth: Cell.w(parent.w)
                                        implicitHeight: Cell.h(parent.h)

                                        onPaint: {

                                            var ctx = getContext("2d")

                                            const highlighted = Math.floor((parent.percent/100)*parent.w)

                                            for (let i = 0; i <= implicitWidth; i += Cell.w(1)) {
                                                ctx.fillStyle = Colors.bgSurface    
                                                ctx.fillRect(i,0,Cell.w(1),Cell.h(1))

                                                ctx.fillStyle = Qt.hsva(i/(implicitWidth-Cell.w(1)),1,1,1)
                                                if (highlighted == Math.floor(i/Cell.w(1))) {
                                                    ctx.fillRect(i-Cell.w(1),0,Cell.w(3),Cell.h(1))
                                                }
                                                ctx.fillRect(i,(Cell.h(1)-Cell.w(1))/2,Cell.w(1),Cell.w(1))
                                            }

                                        }

                                    }

                                }

                                CellText {
                                    text: " "
                                }

                                Cells {

                                    w: 4
                                    h: 1

                                    color: Colors.bgOverlay

                                    CellTextField {

                                        w: 4
                                        h: 1

                                        scroll: false
                                        focusOnVisible: false

                                        bindText: Math.round(Math.max(Math.min(color_picker.buffer.hsvHue,1),0)*100)

                                        onTextInput: (input) => {
                                            text = Math.max(Math.min(parseInt(input),100),0)
                                            unFocus()
                                        }

                                        onEntered: (input) => {
                                            const output = parseInt(input)
                                            color_picker.buffer.hsvHue = output/100
                                        }

                                    }

                                }
                            }

                            CellSeparator {

                                w: 37
                                type: 0
                                padding: 1
                                color: Colors.bgOverlay

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                                spacing: 0

                                CellText {
                                    text: "S "
                                }

                                CellProgressSquare {

                                    w: 28
                                    h: 1

                                    percent: color_picker.buffer.hsvSaturation*100

                                    percentSmoother: 200

                                    wheelInterval: 1

                                    interactive: true

                                    onAdjusted: (percent) => {
                                        color_picker.buffer.hsvSaturation = percent/100
                                    }

                                    onPercentChanged: {
                                        value.requestPaint()
                                        saturation.requestPaint()
                                    }

                                    Canvas {

                                        id: saturation

                                        implicitWidth: Cell.w(parent.w)
                                        implicitHeight: Cell.h(parent.h)

                                        onPaint: {

                                            var ctx = getContext("2d")

                                            const highlighted = Math.floor((parent.percent/100)*parent.w)

                                            for (let i = 0; i <= implicitWidth; i += Cell.w(1)) {
                                                ctx.fillStyle = Colors.bgSurface    
                                                ctx.fillRect(i,0,Cell.w(1),Cell.h(1))

                                                ctx.fillStyle = Qt.hsva(color_picker.buffer.hsvHue,i/(implicitWidth-Cell.w(1)),1,1)
                                                if (highlighted == Math.floor(i/Cell.w(1))) {
                                                    ctx.fillRect(i-Cell.w(1),0,Cell.w(3),Cell.h(1))
                                                }
                                                ctx.fillRect(i,(Cell.h(1)-Cell.w(1))/2,Cell.w(1),Cell.w(1))
                                            }

                                        }

                                    }

                                }

                                CellText {
                                    text: " "
                                }

                                Cells {

                                    w: 4
                                    h: 1

                                    color: Colors.bgOverlay

                                    CellTextField {

                                        w: 4
                                        h: 1

                                        scroll: false
                                        focusOnVisible: false

                                        bindText: Math.round(color_picker.buffer.hsvSaturation*100)

                                        onTextInput: (input) => {
                                            text = Math.max(Math.min(parseInt(input),100),0)
                                            unFocus()
                                        }

                                        onEntered: (input) => {
                                            const output = parseInt(input)
                                            color_picker.buffer.hsvSaturation = output/100
                                        }

                                    }

                                }
                            }

                            CellSeparator {

                                w: 37
                                type: 0
                                padding: 1
                                color: Colors.bgOverlay

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                                spacing: 0

                                CellText {
                                    text: "V "
                                }

                                CellProgressSquare {

                                    w: 28
                                    h: 1

                                    percent: color_picker.buffer.hsvValue*100

                                    percentSmoother: 200

                                    wheelInterval: 1

                                    interactive: true

                                    onAdjusted: (percent) => {
                                        color_picker.buffer.hsvValue = percent/100
                                    }

                                    onPercentChanged: {
                                        value.requestPaint()
                                    }

                                    Canvas {

                                        id: value

                                        implicitWidth: Cell.w(parent.w)
                                        implicitHeight: Cell.h(parent.h)

                                        onPaint: {

                                            var ctx = getContext("2d")

                                            const highlighted = Math.floor((parent.percent/100)*parent.w)

                                            for (let i = 0; i <= implicitWidth; i += Cell.w(1)) {
                                                ctx.fillStyle = Colors.bgSurface    
                                                ctx.fillRect(i,0,Cell.w(1),Cell.h(1))

                                                ctx.fillStyle = Qt.hsva(color_picker.buffer.hsvHue,color_picker.buffer.hsvSaturation,i/(implicitWidth-Cell.w(1)),1)
                                                if (highlighted == Math.floor(i/Cell.w(1))) {
                                                    ctx.fillRect(i-Cell.w(1),0,Cell.w(3),Cell.h(1))
                                                }
                                                ctx.fillRect(i,(Cell.h(1)-Cell.w(1))/2,Cell.w(1),Cell.w(1))
                                            }

                                        }

                                    }

                                }

                                CellText {
                                    text: " "
                                }

                                Cells {

                                    w: 4
                                    h: 1

                                    color: Colors.bgOverlay

                                    CellTextField {

                                        w: 4
                                        h: 1

                                        scroll: false
                                        focusOnVisible: false

                                        bindText: Math.round(color_picker.buffer.hsvValue*100)

                                        onTextInput: (input) => {
                                            text = Math.max(Math.min(parseInt(input),100),0)
                                            unFocus()
                                        }

                                        onEntered: (input) => {
                                            const output = parseInt(input)
                                            color_picker.buffer.hsvValue = output/100
                                        }

                                    }

                                }
                            }

                            CellSeparator {

                                w: 37
                                type: 0
                                padding: 1
                                color: Colors.bgOverlay

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                                spacing: Cell.w(1)

                                RowLayout {

                                    spacing: 0

                                    CellText {
                                        text: "R "
                                    }

                                    Cells {

                                        w: 4
                                        h: 1
                                        color: Colors.bgOverlay

                                        CellTextField {

                                            id: r

                                            w: parent.w
                                            h: parent.h

                                            focusOnVisible: false
                                            bindText: Math.round(color_picker.buffer.r*255)

                                            onEntered: (input) => {
                                                input = parseInt(input.trim())
                                                if (input >= 0 && input <= 255 ) {
                                                    color_picker.buffer.r = input/255
                                                }
                                                unFocus()
                                            }

                                            Keys.onPressed: (button) => {
                                                if (button.key == Qt.Key_Tab) {
                                                    r.unFocus()
                                                    g.grabFocus()
                                                }
                                            }

                                        }

                                    }
                                }

                                RowLayout {

                                    spacing: 0

                                    CellText {
                                        text: "G "
                                    }

                                    Cells {

                                        w: 4
                                        h: 1
                                        color: Colors.bgOverlay

                                        CellTextField {

                                            id: g

                                            w: parent.w
                                            h: parent.h

                                            focusOnVisible: false
                                            bindText: Math.round(color_picker.buffer.g*255)

                                            onEntered: (input) => {
                                                input = parseInt(input.trim())
                                                if (input >= 0 && input <= 255 ) {
                                                    color_picker.buffer.g = input/255
                                                }
                                                unFocus()
                                            }

                                            Keys.onPressed: (button) => {
                                                if (button.key == Qt.Key_Tab) {
                                                    g.unFocus()
                                                    b.grabFocus()
                                                }
                                            }

                                        }

                                    }
                                }

                                RowLayout {

                                    spacing: 0

                                    CellText {
                                        text: "B "
                                    }

                                    Cells {

                                        w: 4
                                        h: 1
                                        color: Colors.bgOverlay

                                        CellTextField {

                                            id: b

                                            w: parent.w
                                            h: parent.h

                                            focusOnVisible: false
                                            bindText: Math.round(color_picker.buffer.b*255)

                                            onEntered: (input) => {
                                                input = parseInt(input.trim())
                                                if ( input >= 0 && input <= 255 ) {
                                                    color_picker.buffer.b = input/255
                                                }
                                                unFocus()
                                            }

                                            Keys.onPressed: (button) => {
                                                if (button.key == Qt.Key_Tab) {
                                                    b.unFocus()
                                                    hex.grabFocus()
                                                }
                                            }

                                        }

                                    }
                                }

                                RowLayout {

                                    spacing: 0

                                    CellText {
                                        text: "Hex "
                                    }

                                    Cells {

                                        w: 8
                                        h: 1
                                        color: Colors.bgOverlay

                                        CellTextField {

                                            id: hex

                                            w: parent.w
                                            h: parent.h

                                            focusOnVisible: false
                                            bindText: color_picker.buffer.toString()

                                            onEntered: (input) => {
                                                input = input.trim()
                                                if (/^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/.test(input)) {
                                                    color_picker.buffer = input.startsWith("#") ? input : "#" + input
                                                }
                                                unFocus()
                                            }

                                            Keys.onPressed: (button) => {
                                                if (button.key == Qt.Key_Tab) {
                                                    hex.unFocus()
                                                    r.grabFocus()
                                                }
                                            }

                                        }

                                    }

                                }


                            }

                        }

                        CellSeparator {

                            h: 23
                            type: 0
                            color: Colors.fgSubtle

                            vertical: true

                        }

                    }

                    CellSeparator {

                        w: 38
                        type: 2
                        color: Colors.bgOverlay

                    }

                }


                Cells {

                    Layout.alignment: Qt.AlignTop

                    visible: layout.color.name != "" && !layout.edit

                    id: preview

                    w: root.w - 38
                    h: 23

                    color: layout.color["bgSurface"]

                    property color label: layout.color["secondary"]

                    ColumnLayout {

                        spacing: 0

                        CellSeparator {

                            w: preview.w
                            type: 2
                            color: layout.color["accentStrong"]
                            bg: layout.color["bgSurface"]

                        }

                        CellText {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                            text: "Preview"
                            color: layout.color["secondary"]
                            font: Cell.fontB

                        }

                        CellSeparator {

                            w: preview.w
                            type: 2
                            color: layout.color["accentStrong"]
                            bg: layout.color["bgSurface"]

                        }

                        Cells {

                            Layout.leftMargin: Cell.w(1)

                            w: preview.w - 2
                            h: 1
                            color: "transparent"

                            CellText {

                                text: "Name:"
                                color: layout.color["fgDim"]

                            }

                            MarqueeCellText {

                                x: Cell.w(6)

                                text: layout.color["name"]
                                fg: layout.color["fgBase"]
                                font: Cell.fontB
                                cellw: preview.w - 14

                            }

                        }

                        ColumnLayout {

                            Layout.leftMargin: Cell.w(1)

                            spacing: 0

                            CellText {

                                text: "Description:"
                                color: layout.color["fgDim"]

                            }

                            Cells {

                                w: preview.w - 2
                                h: 3

                                color: "transparent"

                                CellText {

                                    text: layout.color["description"]
                                    color: layout.color["fgBase"]
                                    preferedW: preview.w - 2
                                    font: Cell.fontB
                                    wrap: true

                                }

                            }

                        }

                        CellSeparator {

                            w: preview.w
                            type: 0
                            color: layout.color["accentDim"]
                            bg: layout.color["bgSurface"]

                        }

                        CellTabs {

                            id: tab

                            w: preview.w

                            onVisibleChanged: {
                                selected = 0
                            }

                            items: [
                                "Widgets",
                                "Color list",
                            ]

                            color {
                                bg: layout.color["bgSurface"]
                                fg: layout.color["bgOverlay"]
                                base: layout.color["fgBase"]
                                inactive: layout.color["fgSubtle"]
                                active: layout.color["accentStrong"]
                            }

                        }

                        ColumnLayout {

                            visible: tab.selected == 0
                            spacing: 0

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Button       "
                                    color: preview.label

                                }

                                CellButton {

                                    text: "Click me!"

                                    fg: [layout.color["onAccent"], layout.color["fgBase"]]
                                    color: [layout.color["accentStrong"], layout.color["bgOverlay"]]

                                }

                                CellButton {

                                    text: "Click me!"

                                    fg: layout.color["fgSubtle"]
                                    color: layout.color["bgOverlay"]

                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: layout.color["bgOverlay"]
                                bg: layout.color["bgSurface"]

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Dropdown     "
                                    color: preview.label

                                }

                                CellDropdown {

                                    w: 12

                                    text: ""

                                    items: [
                                        {label: "First", action: () => {selected = 0}},
                                        {label: "Second", action: () => {selected = 1}},
                                        {label: "Third", action: () => {selected = 2}},
                                    ]

                                    button {
                                        color: layout.color["bgOverlay"]
                                        fg: layout.color["fgBase"]
                                        active: layout.color["bgOverlay"]
                                        active_invert: layout.color["fgBase"]
                                    }

                                    menu {
                                        color: layout.color["bgOverlay"]
                                        fg: layout.color["fgBase"]
                                        active: layout.color["accentStrong"]
                                        active_invert: layout.color["onAccent"]
                                    }

                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: layout.color["bgOverlay"]
                                bg: layout.color["bgSurface"]

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Textfield    "
                                    color: preview.label

                                }

                                Cells {

                                    w: preview.w-16
                                    h: 1

                                    color: layout.color["bgOverlay"]

                                    CellTextField {

                                        focusOnVisible: false

                                        w: parent.w
                                        h: 1

                                        placeholder: "Write something here"

                                        color: layout.color["fgBase"]
                                        invert: layout.color["bgSurface"]
                                        visual_color: layout.color["secondary"]
                                        disabled_color: layout.color["fgSubtle"]

                                        onFocusChanged: {
                                            if (!focus) {
                                                textfield.grabFocus()
                                            }
                                        }

                                    }

                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: layout.color["bgOverlay"]
                                bg: layout.color["bgSurface"]

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Progress Bar "
                                    color: preview.label

                                }

                                CellProgressSquare {
                                    w: preview.w - 16
                                    fg: layout.color["accentStrong"]
                                    color: layout.color["bgOverlay"]
                                    percent: 50
                                    interactive: true
                                    onAdjusted: percent = raw_percent
                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: layout.color["bgOverlay"]
                                bg: layout.color["bgSurface"]

                            }

                            GridLayout {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                                rowSpacing: Cell.h(0)
                                columnSpacing: Cell.w(2)
                                columns: 3

                                CellText {
                                    text: "[*] VALUE"
                                    color: layout.color["fgBase"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[i] INFO"
                                    color: layout.color["info"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[✓] SUCCESS"
                                    color: layout.color["success"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[-] LABEL"
                                    color: layout.color["fgDim"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[!] WARNING"
                                    color: layout.color["warning"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[✗] DANGER"
                                    color: layout.color["danger"]
                                    font: Cell.fontB
                                }

                            }

                            CellSeparator {

                                w: preview.w

                                type: 0
                                color: layout.color["accentDim"]
                                bg: layout.color["bgSurface"]

                            }

                            CellButton {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                                text: "Apply"

                                fg: [layout.color["onAccent"], layout.color["fgBase"]]
                                color: [layout.color["accentStrong"], layout.color["bgOverlay"]]

                                onReleased: (button) => {
                                    if (button == "L") {
                                        Colors.current = root.result[layout.selected]
                                    }
                                }

                            }

                            CellSeparator {

                                w: preview.w
                                type: 2
                                color: layout.color["accentStrong"]
                                bg: layout.color["bgSurface"]

                            }

                        }

                        ColumnLayout {

                            visible: tab.selected == 1

                            spacing: 0

                            CellScrollView {

                                w: preview.w
                                h: 12

                                scrollbar {
                                    color: layout.color["fgDim"]
                                    bg_color: layout.color["bgOverlay"]
                                }

                                color: layout.color["bgSurface"]

                                GridLayout {

                                    Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                                    rowSpacing: Cell.h(0)
                                    columnSpacing: Cell.w(1)
                                    columns: 2

                                    Repeater {

                                        model: Object.keys(layout.color).slice(2)

                                        delegate: ColumnLayout {

                                            id: palette

                                            required property int index
                                            required property var modelData

                                            spacing: 0

                                            RowLayout {

                                                Layout.leftMargin: Cell.w(1)

                                                spacing: Cell.w(1)

                                                CellText {

                                                    text: palette.modelData.toString().padEnd(14, " ")
                                                    color: layout.color["fgDim"]

                                                }

                                                Cells {

                                                    w: 13
                                                    h: 1

                                                    color: layout.color[palette.modelData]

                                                }

                                            }

                                            CellSeparator {

                                                w: 30

                                                padding: 1
                                                type: 0
                                                color: layout.color["bgOverlay"]
                                                bg: layout.color["bgSurface"]

                                            }
                                        }

                                    }
                                }

                            }

                            CellSeparator {

                                w: preview.w
                                type: 2
                                color: layout.color["accentStrong"]
                                bg: layout.color["bgSurface"]

                            }

                        }

                    }

                }

                Cells {

                    Layout.alignment: Qt.AlignTop

                    visible: layout.edit

                    id: edit

                    w: root.w - 38
                    h: 23

                    onVisibleChanged: {
                        edit.color_picker = false
                    }

                    color: edit.color_buffer["bgSurface"]

                    property bool color_picker: false

                    property var color_buffer: {
                        "name": "",
                        "description": "",
                        "bgBase": "",
                        "bgSurface": "",
                        "bgOverlay": "",
                        "fgBase": "",
                        "onAccent": "",
                        "fgDim": "",
                        "fgSubtle": "",
                        "accentStrong": "",
                        "accentDim": "",
                        "secondary": "",
                        "info": "",
                        "success": "",
                        "warning": "",
                        "danger": "",
                        "borderActive": "",
                        "borderInactive": "",
                    }

                    property color label: edit.color_buffer["secondary"]

                    ColumnLayout {

                        spacing: 0

                        CellSeparator {

                            w: edit.w
                            type: 2
                            color: edit.color_buffer["accentStrong"]
                            bg: edit.color_buffer["bgSurface"]

                        }

                        CellText {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                            text: "Editing theme"
                            color: edit.color_buffer["secondary"]
                            font: Cell.fontB

                        }

                        CellSeparator {

                            w: edit.w
                            type: 2
                            color: edit.color_buffer["accentStrong"]
                            bg: edit.color_buffer["bgSurface"]

                        }

                        Cells {

                            Layout.leftMargin: Cell.w(1)

                            w: edit.w - 2
                            h: 1
                            color: "transparent"

                            CellText {

                                text: "Name:"
                                color: edit.color_buffer["fgDim"]

                            }

                            Cells {

                                x: Cell.w(6)

                                color: edit.color_buffer["bgOverlay"]
                                w: edit.w - 8
                                h: 1

                                CellTextField {

                                    id: edit_name

                                    w: parent.w
                                    h: parent.h

                                    focusOnVisible: false
                                    placeholder: "Theme name"

                                    color: edit.color_buffer["fgBase"]
                                    invert: edit.color_buffer["bgSurface"]
                                    visual_color: edit.color_buffer["secondary"]
                                    disabled_color: edit.color_buffer["fgSubtle"]

                                    Keys.onPressed: (event) => {
                                        if (event.key == Qt.Key_Tab) {
                                            edit_name.unFocus()
                                            edit_des.grabFocus()
                                        }
                                    }

                                }

                            }

                        }

                        Cells {

                            Layout.leftMargin: Cell.w(1)

                            w: edit.w - 2
                            h: 4
                            color: "transparent"

                            ColumnLayout {

                                spacing: 0

                                CellText {

                                    text: "Description:"
                                    color: edit.color_buffer["fgDim"]

                                }

                                Cells {

                                    x: Cell.w(12)

                                    color: edit.color_buffer["bgOverlay"]
                                    w: edit.w-2
                                    h: 3

                                    CellTextField {

                                        id: edit_des

                                        w: parent.w
                                        h: parent.h

                                        focusOnVisible: false
                                        placeholder: "Description"

                                        color:          edit.color_buffer["fgBase"]
                                        invert:         edit.color_buffer["bgSurface"]
                                        visual_color:   edit.color_buffer["secondary"]
                                        disabled_color: edit.color_buffer["fgSubtle"]

                                        wrap: true

                                        Keys.onPressed: (event) => {
                                            if (event.key == Qt.Key_Tab) {
                                                edit_des.unFocus()
                                                edit_name.grabFocus()
                                            }
                                        }

                                    }

                                }

                            }

                        }

                        CellSeparator {

                            w: edit.w
                            type: 0
                            color: layout.color["accentDim"]
                            bg: layout.color["bgSurface"]

                        }

                        CellTabs {

                            id: tab_edit

                            w: edit.w

                            onVisibleChanged: {
                                selected = 0
                            }

                            items: [
                                "Color list",
                                "Widgets",
                            ]

                            color {
                                bg:       edit.color_buffer["bgSurface"]
                                fg:       edit.color_buffer["bgOverlay"]
                                base:     edit.color_buffer["fgBase"]
                                inactive: edit.color_buffer["fgSubtle"]
                                active:   edit.color_buffer["accentStrong"]
                            }

                        }

                        CellScrollView {

                            visible: tab_edit.selected == 0

                            w: edit.w
                            h: 10

                            scrollbar {
                                color:    edit.color_buffer["fgDim"]
                                bg_color: edit.color_buffer["bgOverlay"]
                            }

                            GridLayout {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                                rowSpacing: Cell.h(0)
                                columnSpacing: Cell.w(1)
                                columns: 2

                                Repeater {

                                    model: Object.keys(layout.color).slice(2)

                                    delegate: ColumnLayout {

                                        id: palette

                                        required property int index
                                        required property var modelData

                                        spacing: 0

                                        RowLayout {

                                            Layout.leftMargin: Cell.w(1)

                                            spacing: Cell.w(1)

                                            CellText {

                                                text: palette.modelData.toString().padEnd(14, " ")
                                                color: edit.color_buffer["fgDim"]

                                            }

                                            Cells {

                                                w: 13
                                                h: 1

                                                color: edit.color_buffer[palette.modelData]

                                                MouseControl {

                                                    anchors.fill: parent

                                                    onReleased: (button) => {
                                                        if (button == "L") {
                                                            edit.color_picker = !edit.color_picker
                                                            color_picker.key = palette.modelData
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                        CellSeparator {

                                            w: 30

                                            padding: 1
                                            type: 0
                                            color: edit.color_buffer["bgOverlay"]
                                            bg:    edit.color_buffer["bgSurface"]

                                        }
                                    }

                                }
                            }

                        }

                        ColumnLayout {

                            visible: tab_edit.selected == 1
                            spacing: 0

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Button       "
                                    color: preview.label

                                }

                                CellButton {

                                    text: "Click me!"

                                    fg: [edit.color_buffer["onAccent"], edit.color_buffer["fgBase"]]
                                    color: [edit.color_buffer["accentStrong"], edit.color_buffer["bgOverlay"]]

                                }

                                CellButton {

                                    text: "Click me!"

                                    fg: edit.color_buffer["fgSubtle"]
                                    color: edit.color_buffer["bgOverlay"]

                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: edit.color_buffer["bgOverlay"]
                                bg: edit.color_buffer["bgSurface"]

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Dropdown     "
                                    color: preview.label

                                }

                                CellDropdown {

                                    w: 12

                                    text: ""

                                    items: [
                                        {label: "First", action: () => {selected = 0}},
                                        {label: "Second", action: () => {selected = 1}},
                                        {label: "Third", action: () => {selected = 2}},
                                    ]

                                    button {
                                        color:         edit.color_buffer["bgOverlay"]
                                        fg:            edit.color_buffer["fgBase"]
                                        active:        edit.color_buffer["bgOverlay"]
                                        active_invert: edit.color_buffer["fgBase"]
                                    }

                                    menu {
                                        color:         edit.color_buffer["bgOverlay"]
                                        fg:            edit.color_buffer["fgBase"]
                                        active:        edit.color_buffer["accentStrong"]
                                        active_invert: edit.color_buffer["onAccent"]
                                    }

                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: edit.color_buffer["bgOverlay"]
                                bg:    edit.color_buffer["bgSurface"]

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Textfield    "
                                    color: preview.label

                                }

                                Cells {

                                    w: preview.w-16
                                    h: 1

                                    color: edit.color_buffer["bgOverlay"]

                                    CellTextField {

                                        focusOnVisible: false

                                        w: parent.w
                                        h: 1

                                        placeholder: "Write something here"

                                        color:          edit.color_buffer["fgBase"]
                                        invert:         edit.color_buffer["bgSurface"]
                                        visual_color:   edit.color_buffer["secondary"]
                                        disabled_color: edit.color_buffer["fgSubtle"]

                                        onFocusChanged: {
                                            if (!focus) {
                                                textfield.grabFocus()
                                            }
                                        }

                                    }

                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: edit.color_buffer["bgOverlay"]
                                bg:    edit.color_buffer["bgSurface"]

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Progress Bar "
                                    color: preview.label

                                }

                                CellProgressSquare {
                                    w: preview.w - 16
                                    fg:    edit.color_buffer["accentStrong"]
                                    color: edit.color_buffer["bgOverlay"]
                                    percent: 50
                                    interactive: true
                                    onAdjusted: percent = raw_percent
                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: edit.color_buffer["bgOverlay"]
                                bg:    edit.color_buffer["bgSurface"]

                            }

                            GridLayout {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                                rowSpacing: Cell.h(0)
                                columnSpacing: Cell.w(2)
                                columns: 3

                                CellText {
                                    text: "[*] VALUE"
                                    color: edit.color_buffer["fgBase"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[i] INFO"
                                    color: edit.color_buffer["info"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[✓] SUCCESS"
                                    color: edit.color_buffer["success"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[-] LABEL"
                                    color: edit.color_buffer["fgDim"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[!] WARNING"
                                    color: edit.color_buffer["warning"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[✗] DANGER"
                                    color: edit.color_buffer["danger"]
                                    font: Cell.fontB
                                }

                            }


                        }

                        CellSeparator {

                            w: preview.w

                            padding: 1
                            type: 0
                            color: edit.color_buffer["accentDim"]
                            bg: edit.color_buffer["bgSurface"]

                        }

                        CellButton {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                            text: "Apply"

                            fg: [edit.color_buffer["onAccent"], edit.color_buffer["fgBase"]]
                            color: [edit.color_buffer["accentStrong"], edit.color_buffer["bgOverlay"]]

                            onReleased: (button) => {
                                if (button == "L") {
                                    Colors.current = root.result[layout.selected]
                                }
                            }

                        }

                        CellSeparator {

                            w: preview.w
                            type: 2
                            color: edit.color_buffer["accentStrong"]
                            bg:    edit.color_buffer["bgSurface"]

                        }
                    }

                }

                Cells {

                    id: empty

                    w: root.w - 38
                    h: 23

                    color: "transparent"

                    CellText {

                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                        y: Cell.h(Math.round(parent.h*0.5 - 1))

                        text: "No themes found."
                        color: Colors.fgSubtle
                    }
                }

            }

            CellBox {

                id: text_box

                Layout.leftMargin: Cell.w(1)
                Layout.topMargin: Cell.h(1)

                border.type: 4

                w: root.w
                h: 3

                Item {

                    id: text_layout

                    CellTextField {

                        id: textfield

                        x: Cell.w(1)

                        w: text_box.contentW - 2
                        h: 1

                        placeholder: "Search colors"

                        disabled: layout.edit

                        onTextInput: (input) => {
                            layout.selected = 0
                            list.reset()
                            if (input.length == 0) {
                                root.result = Object.keys(Colors.colors)
                            } else {
                                let buffer = []
                                let color_buffer = ({})
                                buffer = Object.keys(Colors.colors).filter((item) => {
                                    if (Colors.colors[item].name.toLowerCase().replace(" ", "").includes(input.toLowerCase().replace(" ", ""))) {
                                        return true
                                    }
                                    else if (Colors.colors[item].description.toLowerCase().replace(" ", "").includes(input.toLowerCase().replace(" ", ""))) {
                                        return true
                                    }
                                    return false
                                })
                                root.result = buffer
                            }
                        }

                    }

                }

            }

        }

    }

}
