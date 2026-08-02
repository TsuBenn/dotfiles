pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // CPU
    property real cpu_spike_delta: 150

    // RAM
    property real ram_spike_delta_mb: 500

    // GPU
    property real vram_spike_delta_mb: 1000

    property real gpu_spike_delta: 30
    property real mem_spike_delta: 30
    property real enc_spike_delta: 20
    property real dec_spike_delta: 20

    property int cpu_high_usage: 80.0 * SystemInfo.cputhreads
    property int gpu_high_usage: 80.0
    property int mem_high_usage: 80.0
    property int enc_high_usage: 80.0
    property int dec_high_usage: 80.0

    property int high_usage_milestone: 5 // 5 minutes

    // How many consecutive "below threshold" ticks are tolerated before a
    // sustained-usage streak is actually broken. Prevents one noisy dip
    // from wiping out minutes of accumulated duration.
    property int sustained_grace_ticks: 5

    // EMA blend factor used only for the sustained-usage check. Lower =
    // smoother/slower to react, higher = snappier/noisier. Spike detection
    // deliberately does NOT use this — spikes are supposed to be sudden.
    property real smoothing_alpha: 0.3

    signal spiked(string program, var types, var deltas)
    signal sustained(string program, var types, var usages, int milestone)

    onSpiked: (program, types, deltas) => {
        NotificationsInfo.send("", "", "SPIKED!", `${program} - ${types.join(", ")} - ${deltas.join(", ")}`, 0, true, "echo hello");
    }
    onSustained: (program, types, usages, milestone) => {
        NotificationsInfo.send("", "", "SUSTAINED!", `${program} - ${types.join(", ")} - ${usages.join(", ")} - ${milestone}`, 0, true, "echo hello");
    }

    property bool spike_detection: true
    property bool sustained_detection: true

    property var process: SystemInfo.process

    // onProcessChanged: {
    // }

    property var pid_process: ({})
    property var name_process: ({})

    property var _prev_name_process: ({})
    property var _smoothed_process: ({})

    property var pids: Object.keys(pid_process)
    property var programs: Object.keys(name_process)

    property var high_usage: ({})
}
