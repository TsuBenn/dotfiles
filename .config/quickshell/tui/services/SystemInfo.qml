pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Singleton {
    id: root

    IdleMonitor {
        id: im
        timeout: 30
    }

    property bool idle: im.isIdle
    property bool idle_timeout: im.isIdle

    property int session

    onIdleChanged: {
        if (idle) {
            console.log("SystemInfo: IDLE MODE STARTED");
        } else {
            console.log("SystemInfo: IDLE MODE STOPPED");
        }
    }

    //OS level
    property string username: "user"
    property string homedir
    property string configdir: homedir + "/.config/quickshell/tui"
    property string hostname: "host"
    property string os: "Linux"
    property string kernel: "linux"
    property string architecture: "x86_64"
    property string systemUTF: "\udb82\udcc7"
    property string uptime: "0h0m0s"
    property int uptime_raw: 0
    property string wm: "n/a"

    signal auth(string prompt)

    signal initializedSystemInfo

    //Specs
    property string cpumodel: "CPU"
    property int cpucores
    property int cputhreads
    property real cpubase
    property real cpuboost
    property int cputotal
    property int cpuidle
    property real cputemp
    property real cpupower
    property real cpumaxpower
    property bool cpurapl
    property real cpuusage

    property var cpustats: ({}) // individual cores usage

    property var process: [] // individual process usage

    property real memtotal
    property real memused
    property real memusage: {
        const usage = (memused / memtotal) * 100;
        return usage.toFixed(2);
    }

    property bool hasgpu: false
    property string gpuvendor: ""

    property var gpumodels: []
    property real gpuname
    property real gpuusage
    property real gpusm
    property real gpumem
    property real gpuenc
    property real gpudec
    property real gputemp
    property real gpupower
    property real gpumaxpower
    property real gpufreq
    property real gpumaxfreq
    property real gpumemoryfreq
    property real gpumemorymaxfreq
    property real gpumemtotal
    property real gpumemused
    property real gpumemusage: {
        const usage = (gpumemused / gpumemtotal) * 100;
        return usage.toFixed(2);
    }

    property string board: "MOTHERBOARD"

    property var wifi: {
        "enabled": false,
        "type": "Ethernet" // Wifi, Ethernet
        ,
        // "device": "wlan0",
        "name": "Wifi",
        "localip": "0.0.0.0",
        "signal": 0,
        "channel": 0,
        "freq": 0
    }

    property var bluetooth: {
        "enabled": false,
        "devices": []
    }

    property string rootstoragename: "ROOT"
    property string networkdevice: "Wifi/Ethernet"

    // Battery
    property bool notified5: false
    property bool notified10: false
    property bool notified20: false
    property string curr_bat: ""
    property string battery: "inf"
    property string batterystate
    property string batteryhealth
    property bool onbattery

    function notify_low_battery() {
        const bat = parseInt(root.battery);
        if (bat <= 5 && !notified5) {
            notified5 = true;
            NotificationsInfo.send("System", "", "LOW BATTERY!", "5% battery remaining - plug in now!", 2);
        } else if (bat <= 10 && !notified10) {
            notified10 = true;
            NotificationsInfo.send("System", "", "Low Battery!", "10% battery remaining - best to plug in now!", 1);
        } else if (bat <= 20 && !notified20) {
            notified20 = true;
            NotificationsInfo.send("System", "", "Low Battery", "20% battery remaining - plug in soon!", 0);
        }
    }

    onBatterystateChanged: {
        if (batterystate != "discharging") {
            notified5 = false;
            notified10 = false;
            notified20 = false;
            return;
        }
        notify_low_battery();
    }

    onBatteryChanged: {
        if (batterystate != "discharging")
            return;
        notify_low_battery();
    }

    property real swaptotal
    property real swapused
    property real swapusage: {
        const usage = (swapused / swaptotal) * 100;
        return usage.toFixed(2);
    }

    property var disks: []
    property var phydisks: []

    property real rootstoragetotal
    property real rootstorageused
    property real rootstorageusage: {
        const usage = (rootstorageused / rootstoragetotal) * 100;
        return usage.toFixed(2);
    }

    property string lockedScreen: ""

    signal lockRequest
    signal unlockRequest

    function shutdown() {
        power.exec(["shutdown", "-h", "now"]);
    }
    function sleep() {
        power.exec(["systemctl", "suspend"]);
    }
    function reboot() {
        power.exec(["reboot"]);
    }
    function lock() {
        root.lockRequest();
    }
    function logout() {
        power.exec(["hyprctl", "dispatch", "hl.dsp.exit()"]);
    }

    function formatNum(num, i) {
        const str = num.toString();
        return str.padStart(i, ' ');
    }

    function ktoM(num: int): real {
        num /= 1024;
        return num.toFixed(2);
    }

    function ktoG(num: int): real {
        num /= 1024 * 1024;
        return num.toFixed(2);
    }

    function storageRounder(num, precision: int, i: int): string {
        if (num > 1024 ** 3) {
            num /= 1024 ** 3;
            return formatNum(num.toFixed(precision), i) + "GB";
        } else if (num > 1024 ** 2) {
            num /= 1024 ** 2;
            return formatNum(num.toFixed(precision), i) + "MB";
        } else if (num > 1024) {
            num /= 1024;
            return formatNum(num.toFixed(precision), i) + "KB";
        } else {
            return formatNum(num.toFixed(precision), i) + " B";
        }
    }

    function getHome(): string {
        return root.homedir;
    }

    function runDetached(command = []) {
        Quickshell.execDetached(command);
    }

    // IO stuff
    property double networktransmit // transmit speed
    property double networkreceive // receive speed

    property real diskreadspeed // read speed
    property real diskwritespeed // read speed

    property int polling_time: SettingsInfo.systemPolling ?? 1000

    // onPolling_timeChanged: {
    //     cpustat.running = false;
    // }

    function activate() {
        activator.exec(["pkexec", configdir + "/scripts/setup.sh", configdir]);
    }

    Timer {
        id: timer
        interval: root.polling_time
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.homedir)
                return;
            // cpustat.reload();
            // if (!cpustat.running)
            //     cpustat.running = true;
            if (!sysprocstats.running)
                sysprocstats.running = true;
            // if (!procstat.running)
            //     procstat.running = true;
            // if (!sysstats.running)
            //     sysstats.running = true;
            // network.reload();
            // disk.reload();
            // fastfetch.running = true;
            // batterystat.running = true;
        }
    }

    function copy_clipboard(text: string) {
        power.command = ["wl-copy", text];
        power.startDetached();
        power.command = [];
    }

    function type(text: string) {
        power.command = ["wtype", text];
        power.startDetached();
        power.command = [];
    }

    Process {
        id: power
    }

    // UNIFIED SYSTEM STATS
    Process {
        id: sysprocstats
        running: true
        command: [root.configdir + "/scripts/sysprocstats", root.polling_time]

        function cleanCpuModel(model) {
            if (!model)
                return "CPU";
            return model.replace(/\((R|TM)\)/gi, "")                          // Removes (R) and (TM)
            .replace(/\b\d+-(Core|Cores|Thread|Threads)\b/gi, "") // Removes "6-Cores", "8-Core", etc.
            .replace(/\bCPU\s*@\s*[\d\.]+\s*GHz\b/gi, "")         // Removes "CPU @ 3.80GHz"
            .replace(/\bProcessor\b/gi, "")                       // Removes "Processor"
            .replace(/\bCPU\b/gi, "")                             // Removes "CPU"
            .replace(/\s+/g, " ")                                 // Collapses multiple spaces
            .trim();
        }

        function cleanBoardModel(model) {
            if (!model)
                return "Motherboard";
            if (/To be filled|Default string|System Product|Base Board/i.test(model)) {
                return "Motherboard";
            }
            return model.replace(/Micro-Star\s+International\s+Co\.,?\s*Ltd\.?\s*(\[MSI\])?/gi, "MSI").replace(/ASUSTeK\s+COMPUTER\s+INC\.?/gi, "ASUS").replace(/Gigabyte\s+Technology\s+Co\.,?\s*Ltd\.?/gi, "Gigabyte").replace(/EVGA\s+Corporation/gi, "EVGA").replace(/\(MS-\w+\)/gi, "").replace(/\b(ASUS|MSI|Gigabyte|ASRock)\s+\1\b/gi, "$1").replace(/\s+/g, " ").trim();
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: text => {
                if (!text)
                    return;

                // try {
                const data = JSON.parse(text);

                // OS & Meta
                root.username = data.os.username;
                root.hostname = data.os.hostname;
                root.os = data.os.name;
                root.architecture = data.os.arch;
                root.kernel = data.os.kernel;
                root.uptime = DateTime.formatDuration(data.os.uptime, 3);
                root.uptime_raw = data.os.uptime;
                root.wm = data.os.wm;

                // Motherboard
                root.board = sysprocstats.cleanBoardModel(data.board.model);

                // CPU
                root.cpumodel = sysprocstats.cleanCpuModel(data.cpu.model);
                root.cpucores = data.cpu.cores;
                root.cputhreads = data.cpu.threads;
                root.cpubase = data.cpu.cur_freq_mhz;
                root.cpuboost = data.cpu.max_freq_mhz;
                root.cputemp = data.cpu.temp_c;
                root.cpupower = data.cpu.power_w;
                root.cpumaxpower = data.cpu.power_max_w;
                root.cpurapl = !data.cpu.rapl_restricted;
                root.cpuusage = data.cpu.total_usage_pct;
                root.cpustats = data.cpu.core_usage_pct;

                // GPU
                root.hasgpu = data.gpu_available ?? (data.gpus.length > 0);
                root.gpuvendor = data.gpu_vendor ?? "";
                root.gpumodels = data.gpus.map(g => ({
                            name: g.name,
                            type: g.type,
                            temp: g.temp_c,
                            power: g.power_cur_w,
                            maxpower: g.power_max_w,
                            freq: g.cur_freq_mhz,
                            maxfreq: g.max_freq_mhz,
                            memoryfreq: g.cur_mem_freq_mhz,
                            memorymaxfreq: g.max_mem_freq_mhz,
                            usage: g.gpu_util_pct,
                            sm: g.gpu_util_pct,
                            mem: g.mem_util_pct,
                            enc: g.enc_util_pct,
                            dec: g.dec_util_pct,
                            memorytotal: g.vram_total_bytes / 1024,
                            memoryused: g.vram_used_bytes / 1024,
                            cores: g.cores
                        }));

                if (data.gpus.length > 0) {
                    const primaryGpu = root.gpumodels[0];
                    root.gpuname = primaryGpu.name;
                    root.gputemp = primaryGpu.temp;
                    root.gpupower = primaryGpu.power;
                    root.gpumaxpower = primaryGpu.maxpower;
                    root.gpuusage = primaryGpu.usage;
                    root.gpusm = primaryGpu.sm;
                    root.gpumem = primaryGpu.mem;
                    root.gpuenc = primaryGpu.enc;
                    root.gpudec = primaryGpu.dec;
                    root.gpufreq = primaryGpu.freq;
                    root.gpumaxfreq = primaryGpu.maxfreq;
                    root.gpumemoryfreq = primaryGpu.memoryfreq;
                    root.gpumemorymaxfreq = primaryGpu.memorymaxfreq;
                    root.gpumemtotal = primaryGpu.memorytotal;
                    root.gpumemused = primaryGpu.memoryused;
                }

                // Memory & Swap (KB)
                root.memtotal = data.memory.ram_total_bytes / 1024;
                root.memused = data.memory.ram_used_bytes / 1024;
                root.swaptotal = data.memory.swap_total_bytes / 1024;
                root.swapused = data.memory.swap_used_bytes / 1024;

                // Disks & Disk IO
                root.disks = data.disks.map(d => ({
                            name: d.label || d.name   // Prefers filesystem label ("ROOT", "storage")
                            ,
                            mountpoint: d.mountpoint,
                            mountfrom: d.name,
                            total: d.total_bytes / 1024,
                            used: d.used_bytes / 1024,
                            filesystem: d.filesystem
                        }));

                root.phydisks = data.physical_disks.map(pd => ({
                            name: pd.name,
                            type: pd.type,
                            size: pd.total_bytes / 1024
                        }));

                root.diskreadspeed = data.disk_io.read_bytes_sec;
                root.diskwritespeed = data.disk_io.write_bytes_sec;

                // Network & Network IO
                root.wifi = {
                    enabled: data.network.enabled,
                    type: data.network.type,
                    name: data.network.name,
                    localip: data.network.local_ip,
                    signal: data.network.signal_pct,
                    freq: data.network.freq_ghz,
                    channel: data.network.channel
                };
                root.networkreceive = data.network_io.rx_bytes_sec;
                root.networktransmit = data.network_io.tx_bytes_sec;

                // Power
                root.battery = data.power.battery_pct;
                root.batteryhealth = data.power.health_pct;
                root.batterystate = data.power.state;
                root.onbattery = data.power.on_battery;

                // Processes (From merged sysprocstats binary)
                root.process = data.processes || [];
            // } catch (e) {
            //     console.log("SystemInfo (sysprocstats): JSON Parse Error!", e);
            // }
            }
        }
    }

    Process {
        running: true
        command: ["bash", "-c", "echo $HOME"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    root.homedir = text.trim();
                    root.initializedSystemInfo();
                }
            }
        }
    }

    Process {
        id: activator

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    // SettingsInfo.restart();
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {}
            }
        }
    }
}
