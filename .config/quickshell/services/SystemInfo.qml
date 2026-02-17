pragma Singleton 

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    //OS level
    property string username: "user"
    property string hostname: "host"
    property string os: "Linux"
    property string kernel: "linux"
    property string systemUTF: "\udb82\udcc7"
    property string uptime: "0h0m0s"
    property string wm: "n/a"

    //Specs
    property string cpumodel: "CPU"
    property var gpumodels: []
    property string rootstoragename: "ROOT"
    property string networkdevice: "Wifi/Ethernet"
    property string monitorname: "Wifi/Ethernet"
    property int    monitorheight: 1920
    property int    monitorwidth: 1080
    property int    monitorrefreshrate: 60
    property real   monitorscale: 1

    //Process
    property int  cputotal
    property int  cpuidle
    property string cputemp
    property int  cputotalprev
    property int  cpuidleprev
    property real cpuusage
    property int  memtotal
    property int  memused
    property real memusage: {
        const usage = (memused/memtotal)*100
        return usage.toFixed(2)
    }

    property string battery
    property string batterystate
    property string batteryhealth
    property bool onbattery

    property int  swaptotal
    property int  swapused
    property real swapusage: {
        const usage = (swapused/swaptotal)*100
        return usage.toFixed(2)
    }

    property int  gpuusage
    property string  gputemp
    property int  gpumemtotal
    property int  gpumemused
    property real gpumemusage: {
        const usage = (gpumemused/gpumemtotal)*100
        return usage.toFixed(2)
    }

    property var  disks

    property int  rootstoragetotal
    property int  rootstorageused
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

    property int  networktransmit
    property int  networkreceive

    property int  receivedbytes
    property int  transmitedbytes

    property int  diskread
    property real diskreadspeed
    property int  diskwrite
    property real diskwritespeed
    property int  diskusage

    property int  diskreaded
    property real diskreadedspeed
    property int  diskwrote
    property real diskwrotespeed
    property int  diskused

    Timer {
        id: timer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpustat.reload()
            gpustat.running = true
            cputemp.running = true
            network.reload()
            disk.reload()
            fastfetch.running = true
            batterystat.running = true
        }
    }

    Process {
        id: fastfetch

        command: ["fastfetch", "-j" , "true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const datas = JSON.parse(text)

                root.username = datas[0].result.userName
                root.hostname = datas[0].result.hostName
                root.os = datas[2].result.prettyName
                root.kernel = datas[4].result.release
                const uptime_hours = Math.floor(datas[5].result.uptime/3600000)
                const uptime_minutes = Math.floor((datas[5].result.uptime - uptime_hours*3600000)/60000)
                const uptime_seconds = Math.floor((datas[5].result.uptime - uptime_hours*3600000 - uptime_minutes*60000)/1000)
                root.uptime = `${uptime_hours}h${uptime_minutes}m${uptime_seconds}s`

                root.monitorname = datas[8].result[0].name
                root.monitorwidth = datas[8].result[0].scaled.width
                root.monitorheight = datas[8].result[0].scaled.height
                root.monitorscale = datas[8].result[0].scaled.height/datas[8].result[0].preferred.height
                root.monitorrefreshrate = datas[8].result[0].output.refreshRate

                root.wm = datas[10].result.prettyName

                root.cpumodel = datas[18].result.cpu

                var gpumodels = []
                for (const gpu of datas[19].result) {
                    gpumodels.push({"type": gpu.type, "name": gpu.name})
                }
                root.gpumodels = gpumodels

                root.memtotal = datas[20].result.total/1000
                root.memused = datas[20].result.used/1000

                var swaptotal = 0
                var swapused = 0
                for (const swap of datas[21].result) {
                    swaptotal += swap.total/1000
                    swapused += swap.used/1000
                }
                root.swaptotal = swaptotal
                root.swapused = swapused

                var disks = []
                for (const disk of datas[22].result) {

                    if (disk.mountpoint == "/") {
                        root.rootstoragetotal = disk.bytes.total/1000
                        root.rootstorageused = disk.bytes.used/1000
                    }

                    disks.push({
                        "name": disk.mountpoint == "/" ? "root" : disk.name,
                        "mountpoint": disk.mountpoint,
                        "total": disk.bytes.total/1000,
                        "used": disk.bytes.used/1000,
                        "filesystem": disk.filesystem/1000,
                    })
                }
                root.disks = disks

            }
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

    //get CPU TEMP
    Process {
        id: cputemp

        running: true
        command: ["sensors"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text) {
                    if (root.cpumodel.match(/^Intel/)) {
                        root.cputemp = text.match(/^Package id 0:\s+\+(.*)°C/m)[1]
                    }
                    else if (root.cpumodel.match(/^AMD/)) {
                        root.cputemp = text.match(/^Tctl:\s+\+(.*)°C/m)[1]
                    }
                }
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
                root.gpuusage = parseInt(data[1], 10)
                root.gpumemtotal = parseInt(data[2], 10)
                root.gpumemused = parseInt(data[3], 10)
                root.gputemp = parseInt(data[4], 10)
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
        id: batterystat
        running: true

        command: ["bash", "-c", "upower -i $(upower -e | grep BAT)"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.match(/^Failed/)) {
                    root.battery = text.match(/^\s+percentage:\s+(\d+%)/m)[1]
                    root.batterystate = text.match(/^\s+state:\s+(.*)\s+/m)[1]
                    root.batteryhealth = text.match(/^\s+capacity:\s+(\d+%)/m)[1]
                    root.onbattery = true

                } else {
                    root.battery = "inf"
                    root.batterystate = "PSU"
                    root.onbattery = false
                }
            }
        }
    }

    Process {
        id: run
    }

}


