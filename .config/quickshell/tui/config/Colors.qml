pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string current: "hutao"

    onCurrentChanged: {
        if (Object.keys(colors).includes(current)) {
            load_config.setText(current);
            apply();
        } else {
            NotificationsInfo.send("System", "", "Colors", `Color palette "${current}" not found!`);
        }
    }

    function reload() {
        load.running = true;
    }

    function init() {
        reload();
    }

    signal applied

    // Background
    property color bgBase: "black"
    property color bgSurface: "black"
    property color bgOverlay: "#222222"

    // Foreground
    property color fgBase: "white"
    property color onAccent: "black"
    property color fgDim: "#999999"
    property color fgSubtle: "#555555"

    // Accent
    property color accentStrong: "white"
    property color accentDim: "gray"
    property color secondary: "white"

    // Semantic
    property color info: "blue"
    property color success: "green"
    property color warning: "yellow"
    property color danger: "red"

    // Border
    property color borderActive: "white"
    property color borderInactive: bgOverlay

    // Behavior on bgBase       {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on bgSurface    {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on bgOverlay    {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on fgBase       {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on onAccent     {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on fgDim        {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on fgSubtle     {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on accentStrong {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on accentDim    {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on secondary    {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on info         {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on success      {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on warning      {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    // Behavior on danger       {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}

    // Helpers
    function transparent(c, factor) {
        return Qt.rgba(c.r, c.g, c.b, c.a * factor);
    }

    function blend(c1: color, c2: color, t: real): color {
        return Qt.rgba(c1.r + (c2.r - c1.r) * t, c1.g + (c2.g - c1.g) * t, c1.b + (c2.b - c1.b) * t, c1.a + (c2.a - c1.a) * t);
    }

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

    function fork(name: string, new_name = "") {
        // if (name == "auto") return
        const new_id = name + "_" + getNextCopyNumber(Object.keys(flat_colors), name);
        if (new_name == "" || name == new_name) {
            if (name == "auto") {
                flat_colors[new_id] = colors.auto[SettingsInfo.lightMode ? "light" : "dark"];
            } else {
                flat_colors[new_id] = flat_colors[name];
            }
            root.current = new_id;
        } else {
            flat_colors[new_name] = flat_colors[name];
            root.current = new_name;
        }
        write();
    }

    function remove(name: string) {
        if (name == "auto")
            return;
        delete flat_colors[name];
        write();
    }

    function save(name: string, new_color: var) {
        if (name == "auto")
            return;
        flat_colors[name] = new_color;
        write();
    }

    function rename(oldName: string, newName: string, newColor: var) {
        if (oldName == "auto")
            return;
        delete flat_colors[oldName];
        flat_colors[newName] = newColor;
        write();  // single write/reload
    }

    function write() {
        get_flat.setText(JSON.stringify(flat_colors, null, 2));
    }

    function apply() {
        const theme = colors[current][SettingsInfo.lightMode ? "light" : "dark"];

        bgBase = theme.bgBase;
        bgSurface = theme.bgSurface;
        bgOverlay = theme.bgOverlay;

        fgBase = theme.fgBase;
        onAccent = theme.onAccent;
        fgDim = theme.fgDim;
        fgSubtle = theme.fgSubtle;

        accentStrong = theme.accentStrong;
        accentDim = theme.accentDim;
        secondary = theme.secondary;
        info = theme.info;

        success = theme.success;
        warning = theme.warning;
        danger = theme.danger;

        borderActive = theme.borderActive;
        borderInactive = theme.borderInactive;

        root.applied();
    }

    property var colors: ({})
    property var flat_colors: ({})
    property var auto_colors: dummy

    property bool preferredLightMode: false

    property var dummy: {
        "name": "Basic",
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
        "borderInactive": ""
    }

    Component.onCompleted: {
        WallpaperInfo.rescanned.connect(() => {
            if (!SettingsInfo.initialized)
                return;
            root.reload();
        });
        WallpaperInfo.currentChanged.connect(() => {
            if (!SettingsInfo.initialized)
                return;
            if (WallpaperInfo.current == "")
                return;
            root.reload();
        });
        SettingsInfo.lightModeChanged.connect(() => {
            if (!SettingsInfo.initialized)
                return;
            root.reload();
        });
    }

    Process {
        id: load

        command: ["python", SystemInfo.configdir + `/scripts/color_manager.py`, "--config-dir", SystemInfo.configdir, "--wallpaper-dir", SystemInfo.homedir + WallpaperInfo.cache_path, WallpaperInfo.getCacheLocation()]

        stdout: StdioCollector {
            onStreamFinished: {
                const data = JSON.parse(text);

                root.preferredLightMode = data.prefered_mode == "light";
                delete data.prefered_mode;
                root.colors = data;

                if (load_config.preload) {
                    root.apply();
                } else {
                    get_flat.preload = true;
                }
            }
        }

        stderr: SplitParser {
            onRead: text => {
                if (text && !text.startsWith("[pipeline]"))
                    console.log("Colors (load): " + text);
            }
        }
    }

    FileView {
        id: get_flat

        preload: false

        path: SystemInfo.configdir + "/scripts/colors.json"

        printErrors: false

        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                setText("{}");
            }
        }

        onLoaded: {
            root.flat_colors = JSON.parse(text());
            load_config.preload = true;
        }

        onSaved: {
            root.reload();
        }
    }

    FileView {
        id: load_config

        preload: false

        path: SystemInfo.configdir + "/scripts/colors_config.txt"

        printErrors: false

        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                setText("auto");
            }
        }

        onLoaded: {
            if (Object.keys(root.flat_colors).includes(text()) || text().trim() == "auto") {
                root.current = text().trim();
            } else {
                root.current = Object.keys(root.flat_colors)[0];
            }
            root.apply();
            SettingsInfo.colorsLoaded = true;
        }
    }
}
