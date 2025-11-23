pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    //OS level
    property string username: "user"
    property string hostname: "host"
    property string systemUTF: "\udb82\udcc7"

    //Specs
    property string cpumodel: "CPU"
    property string gpumodel: "GPU"
    property string rootstoragename: "ROOT"
    property string networkdevice: "Wifi/Ethernet"
    property string monitorname: "Wifi/Ethernet"
    property int monitorheight: 1920
    property int monitorwidth: 1080
    property real monitorscale: 1

    //Process
    property int cputotal
    property int cpuidle
    property int cputemp
    property int cputotalprev
    property int cpuidleprev
    property real cpuusage

    property int memtotal
    property int memused
    property real memusage: {
        const usage = (memused/memtotal)*100
        return usage.toFixed(2)
    }

    property int swaptotal
    property int swapused
    property real swapusage: {
        const usage = (swapused/swaptotal)*100
        return usage.toFixed(2)
    }

    property int gpuusage
    property int gputemp
    property int gpumemtotal
    property int gpumemused
    property real gpumemusage: {
        const usage = (gpumemused/gpumemtotal)*100
        return usage.toFixed(2)
    }

    property int rootstoragetotal
    property int rootstorageused
    property real rootstorageusage: {
        const usage = (rootstorageused/rootstoragetotal)*100
        return usage.toFixed(2)
    }

    function formatNum(num, i) {
        const str = num.toString();
        return str.padStart(i, ' ');
    }

    function ktoM(num: int ): real {
        num /= 1024
        return num.toFixed(2)
    }

    function ktoG(num: int ): real {
        num /= 1024*1024
        return num.toFixed(2)
    }

    function storageRounder(num ,precision: int,i: int): string {
        if (num > 1024**3) {
            num /= 1024**3
            return formatNum(num.toFixed(precision),i) + "GB"
        } else if (num > 1024**2) {
            num /= 1024**2
            return formatNum(num.toFixed(precision),i) + "MB"
        } else if (num > 1024) {
            num /= 1024
            return formatNum(num.toFixed(precision),i) + "KB"
        } else {
            return formatNum(num.toFixed(precision),i) + " B"
        }
    }

    function notifyerr(error: string) {
        run.exec(["bash", "-c", "notify-send 'System Error!' '" + error.trim() + "'"])
    }

    property int networktransmit
    property int networkreceive

    property int receivedbytes
    property int transmitedbytes

    property int diskread
    property real diskreadspeed
    property int diskwrite
    property real diskwritespeed
    property int diskusage

    property int diskreaded
    property real diskreadedspeed
    property int diskwrote
    property real diskwrotespeed
    property int diskused

    Timer {
        id: timer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpustat.reload()
            memstat.reload()
            gpustat.running = true
            cputemp.running = true
            rootstorage.running = true
            network.reload()
            disk.reload()
        }
    }

    FileView {
        id: cpumodel

        path: "/proc/cpuinfo"

        onLoaded: {
            const intel = text().match(/^.*model name\s+:\s+(Intel\(R\) Core\(TM\) [^ ]+).*$/m)
            const amd = text().match((/^.*model name\s+:\s+(AMD Ryzen [0-9]+ [0-9A-Za-z]+).*$/m))
            root.cpumodel = intel[1] ?? amd[1]
        }
    }

    //get CPU STAT
    FileView {
        id: cpustat

        path: "/proc/stat"

        onLoaded: {
            const data = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            const cpudata = data.slice(1).map(x => parseInt(x, 10))
            if (data) {
                root.cputotal = cpudata.reduce((acc,cur) => acc + cur, 0);
                root.cpuidle = cpudata[3] + cpudata[4];

                const totald = root.cputotal - (root.cputotalprev ?? 0)
                const idled = root.cpuidle - (root.cpuidleprev ?? 0)

                root.cpuusage = ((totald - idled)/totald)*100
                root.cpuusage = root.cpuusage.toFixed(2)

                root.cpuidleprev = root.cpuidle
                root.cputotalprev = root.cputotal
            }
        }
    }

    //get MEM STAT
    FileView {
        id: memstat

        path: "/proc/meminfo"

        onLoaded: {
            let total = parseInt(text().match(/MemTotal: *(\d+)/)[1], 10)
            let used = total - parseInt(text().match(/MemAvailable: *(\d+)/)[1], 10)
            root.memtotal = total
            root.memused = used

            total = parseInt(text().match(/SwapTotal: *(\d+)/)[1], 10)
            used = total - parseInt(text().match(/SwapFree: *(\d+)/)[1], 10)
            root.swaptotal = total
            root.swapused = used
        }
    }

    //get CPU TEMP
    Process {
        id: cputemp

        running: true
        command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone*/temp"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.cputemp = parseInt(text, 10)/1000
            }
        }
    }

    //get GPU STAT
    Process {
        id: gpustat

        running: true
        command: ["nvidia-smi", "--query-gpu=name,utilization.gpu,memory.total,memory.used,temperature.gpu", "--format=csv,noheader,nounits"]

        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.split(", ")
                root.gpumodel = data[0]
                root.gpuusage = parseInt(data[1], 10)
                root.gpumemtotal = parseInt(data[2], 10)
                root.gpumemused = parseInt(data[3], 10)
                root.gputemp = parseInt(data[4], 10)
            }
        }
    }

    //get ROOTSTORAGE STAT
    Process {
        id: rootstorage

        running: true
        command: ["bash", "-c", "df | grep '^/dev/' | awk '{print $1, $3, $4}'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.split(" ")
                //console.log(data)
                root.rootstoragename = data[0]
                root.rootstoragetotal = parseInt(data[1], 10) + parseInt(data[2], 10)
                root.rootstorageused = parseInt(data[1], 10)
            }
        }
    }

    //get NETWORK STAT
    FileView {
        id: network

        path: "/proc/net/dev"

        onLoaded: {
            const data = text().split("\n").slice(2)
            let bytesin = 0
            let bytesout = 0
            //console.log(data[3].trim().match(/\w+:\s+(\d+)\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+/))
            for (const wifi of data) {
                if (wifi) {
                    let bytes = wifi.trim().match(/\w+:\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+/)
                    bytesin += parseInt(bytes[1],10)
                    bytesout += parseInt(bytes[2],10)
                }
            }

            const din = bytesin - (root.receivedbytes ?? 0)
            const dout = bytesout - (root.transmitedbytes ?? 0)

            root.networkreceive = din/(timer.interval/1000)
            root.networktransmit = dout/(timer.interval/1000)

            root.receivedbytes = bytesin
            root.transmitedbytes = bytesout

            //console.log(root.storageRounder(root.networkreceive, 2) + " " + root.storageRounder(root.networktransmit, 2))
        }
    }

    //get DISK STAT
    FileView {
        id: disk

        path: "/proc/diskstats"

        onLoaded: {
            const data = text().split("\n")
            let read = 0
            let readms = 0
            let write = 0
            let writems = 0
            let ioms = 0
            for (const device of data) {
                let minidata = device.trim().match(/\d+\s+\d+\s+\w+\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+/)
                if (minidata) {
                    read += parseInt(minidata[1])
                    readms += parseInt(minidata[2])
                    write += parseInt(minidata[3])
                    writems += parseInt(minidata[4])
                    ioms += parseInt(minidata[5])
                }
            }

            const dread = (read - root.diskreaded) ?? 0
            const dreadusage = (readms - root.diskreadedspeed) ?? 0
            const dwrite = (write - root.diskwrote) ?? 0
            const dwriteusage = (writems - root.diskwrotespeed) ?? 0
            const dusage = (ioms - root.diskused) ?? 0

            root.diskread = dread*512
            root.diskreadspeed = dread*512/(timer.interval/1000)
            root.diskwrite = dwrite*512
            root.diskwritespeed = dwrite*512/(timer.interval/1000)
            root.diskusage = dusage/timer.interval

            root.diskreaded = read
            root.diskreadedspeed = readms
            root.diskwrote = write
            root.diskwrotespeed = writems
            root.diskused = ioms

            //console.log(root.storageRounder(root.diskwritespeed, 2))

        }
    }


    Process {
        id: getUsername
        running: true

        command: ["whoami"]
        stdout: StdioCollector {
            onStreamFinished: root.username = text.trim()
        }
    }

    Process {
        id: getMonitor
        running: true

        command: ["hyprctl", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.split("\n")
                let name = data[0].match(/^Monitor\s+([\S]+).*/)
                let scale = text.match(/^\s+scale:\s+(.*)$/m)
                let resolution = data[1].match(/\s+(\d+)x(\d+)@.*/)


                root.monitorname = name
                root.monitorscale = parseFloat(scale[1])
                root.monitorwidth = resolution[1]
                root.monitorheight = resolution[2]
            }
        }
    }

    Process {
        id: getHostname
        running: true

        command: ["uname", "-n"]
        stdout: StdioCollector {
            onStreamFinished: root.hostname = text.trim()
        }
    }

    Process {
        id: run
    }

}


