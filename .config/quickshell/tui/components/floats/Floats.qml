import qs.config
import qs.modules
import qs.services
import qs.components.floats

import QtQuick

Item {
    id: root

    PacmanFloats {
        id: pacman
    }

    AuthFloats {
        id: auth
    }

    ColorFloats {
        id: color
    }

    WallpaperFloats {
        id: wallpaper
    }

    Connections {

        target: SettingsInfo
        function onDebugSig() {
            FloatsManager.open("wallpaper");
        }
    }
}
