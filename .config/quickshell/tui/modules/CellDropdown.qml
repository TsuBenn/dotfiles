import qs.config
import qs.modules

import QtQuick

Item {

    property int w
    property int h

    property string text: "Dropdown"
    property var items: [
        {label: "Button 1", action: () => console.log("Button 1 of the dropdown has been pressed")},
        {label: "Button 2", action: () => console.log("Button 2 of the dropdown has been pressed")}
    ]



}
