pragma Singleton

import qs.assets

import Quickshell

Singleton {
    property int gap: 7
    property int radius: 18
    property int border_width: 2

    property string clock_font: Fonts.system
    property int clock_weight: 600
    property string dateandmonth_font: "JetBrains Mono"                       
    property int dateandmonth_weight: 700                       
    property int clock_size: 85                       
    property int dateandmonth_size: clock_size * (3/8)                       
}


