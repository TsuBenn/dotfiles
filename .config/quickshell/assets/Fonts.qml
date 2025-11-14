pragma Singleton

import Quickshell
import QtQuick

Singleton {

    FontLoader { id: zzz_us; source: "fonts/ZZZ_US.ttf" }
    FontLoader { id: zzz_vn; source: "fonts/ZZZ_VN.ttf" }
    FontLoader { id: montserrat; source: "fonts/Montserrat/Montserrat-Bold.ttf" }
    FontLoader { id: zalandosans; source: "fonts/ZalandoSans/ZalandoSansSemiExpanded-Bold.ttf" }
    FontLoader { id: plexmono; source: "fonts/IBMPlexMono/IBMPlexMono-Medium.ttf" }

    property string system: "JetBrains Mono Nerd Font"
    property string emoji: "Noto Color Emoji"
    property string zzz_us_font: zzz_us.name
    property string zzz_vn_font: zzz_vn.name
    property string montserrat_font: montserrat.name
    property string zalandosans_font: zalandosans.name
    property string plexmono_font: plexmono.name
}
