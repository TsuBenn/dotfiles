pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var procstats: ({})

    Process {
        id: procstats

        running: true
        command: [SystemInfo.configdir + "/scripts/procstats", 5     // top_n
            , 50 * SystemInfo.cputhreads  // cpu_spike_threshold (%)
            , 500.0 // ram_spike_threshold (MB)
            , 50.0 // gpu_spike_threshold (%)
            , 500.0 // vram_spike_threshold (MB)
            , 1000   // interval (ms)
        ]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: text => {
                if (text) {
                    const data = JSON.parse(text);
                    // console.log(JSON.stringify(data, null, 2));
                    root.procstats = data;
                }
            }
        }
    }
}
