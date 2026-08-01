pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu_spike_delta: 150
    property real gpu_spike_delta: 30
    property real ram_spike_delta_mb: 500
    property real vram_spike_delta_mb: 1000

    property int cpu_high_usage: 80.0 * SystemInfo.cputhreads
    property int gpu_high_usage: 80.0

    property int high_usage_milestone: 5 * 60 // 5 minutes

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

    property bool spike_detection: true
    property bool sustained_detection: true

    property var process: SystemInfo.process

    onProcessChanged: {
        index();
        updateSmoothed();
        analyze();
    }

    property var pid_process: ({})
    property var name_process: ({})

    property var _prev_name_process: ({})
    property var _smoothed_process: ({})

    property var pids: Object.keys(pid_process)
    property var programs: Object.keys(name_process)

    property var high_usage: ({})

    function index() {
        let new_pid_process = {};
        let new_name_process = {};

        for (let proc of process) {
            // Index by PID
            new_pid_process[proc.pid] = {
                name: proc.name,
                cpu_pct: proc.cpu_pct,
                ram_mb: proc.ram_mb,
                vram_mb: proc.vram_mb,
                gpu_pct: proc.gpu_pct
            };

            // Aggregate metrics by Process Name (sums up multi-process apps)
            if (!new_name_process[proc.name]) {
                new_name_process[proc.name] = {
                    cpu_pct: 0,
                    ram_mb: 0,
                    vram_mb: 0,
                    gpu_pct: 0
                };
            }

            new_name_process[proc.name].cpu_pct += proc.cpu_pct;
            new_name_process[proc.name].ram_mb += proc.ram_mb;
            new_name_process[proc.name].vram_mb += proc.vram_mb;
            new_name_process[proc.name].gpu_pct += proc.gpu_pct;
        }

        pid_process = new_pid_process;
        name_process = new_name_process;
    }

    // Blends each program's metrics with its previous smoothed value so
    // sustained-usage checks aren't thrown off by single noisy ticks.
    // Rebuilt fresh from name_process every call, so it can't leak entries
    // for programs that have exited.
    function updateSmoothed() {
        let new_smoothed = {};

        for (const name in name_process) {
            const current = name_process[name];
            const prevSmoothed = _smoothed_process[name];

            if (!prevSmoothed) {
                new_smoothed[name] = Object.assign({}, current);
            } else {
                new_smoothed[name] = {
                    cpu_pct: smoothing_alpha * current.cpu_pct + (1 - smoothing_alpha) * prevSmoothed.cpu_pct,
                    gpu_pct: smoothing_alpha * current.gpu_pct + (1 - smoothing_alpha) * prevSmoothed.gpu_pct,
                    ram_mb: smoothing_alpha * current.ram_mb + (1 - smoothing_alpha) * prevSmoothed.ram_mb,
                    vram_mb: smoothing_alpha * current.vram_mb + (1 - smoothing_alpha) * prevSmoothed.vram_mb
                };
            }
        }

        _smoothed_process = new_smoothed;
    }

    function analyze() {
        // Skip frame 1 to seed history
        if (Object.keys(_prev_name_process).length === 0) {
            _prev_name_process = Object.assign({}, name_process);
            return;
        }

        // Prune high_usage entries for programs that have fully exited.
        // The loop below only ever visits names in the CURRENT `programs`
        // list, so a program that closes/crashes disappears from that
        // list entirely and its high_usage entry would otherwise never
        // get deleted — it'd sit there forever. Note this is separate from
        // (and takes priority over) the grace-period logic below: an exited
        // program has no more data coming, so there's nothing to wait for.
        for (const tracked in high_usage) {
            if (!(tracked in name_process)) {
                delete high_usage[tracked];
            }
        }

        for (const i of programs) {
            const current = name_process[i];
            const smoothed = _smoothed_process[i];
            const prev = _prev_name_process[i] || {
                cpu_pct: 0,
                gpu_pct: 0,
                ram_mb: 0,
                vram_mb: 0
            };

            // 1. High Sustained Usage Detection (uses smoothed values +
            //    hysteresis + milestone-catchup)
            if (sustained_detection) {
                let high_cpu = smoothed.cpu_pct > cpu_high_usage;
                let high_gpu = smoothed.gpu_pct > gpu_high_usage;

                if (high_cpu || high_gpu) {
                    if (i in high_usage) {
                        high_usage[i].duration += 1;
                        high_usage[i].low_streak = 0;
                        high_usage[i].cpu_pct = current.cpu_pct;
                        high_usage[i].gpu_pct = current.gpu_pct;
                        high_usage[i].ram_mb = current.ram_mb;
                        high_usage[i].vram_mb = current.vram_mb;

                        while (high_usage[i].duration >= high_usage[i].next_milestone) {
                            let types = [];
                            let usages = [];
                            if (high_cpu) {
                                types.push("cpu");
                                usages.push(current.cpu_pct);
                            }
                            if (high_gpu) {
                                types.push("gpu");
                                usages.push(current.gpu_pct);
                            }

                            let milestone = Math.floor(high_usage[i].next_milestone / high_usage_milestone);
                            sustained(i, types, usages, milestone);

                            high_usage[i].next_milestone += high_usage_milestone;
                        }
                    } else {
                        high_usage[i] = {
                            duration: 0,
                            low_streak: 0,
                            next_milestone: high_usage_milestone,
                            cpu_pct: current.cpu_pct,
                            gpu_pct: current.gpu_pct,
                            ram_mb: current.ram_mb,
                            vram_mb: current.vram_mb
                        };
                    }
                } else {
                    if (i in high_usage) {
                        high_usage[i].low_streak += 1;
                        if (high_usage[i].low_streak >= sustained_grace_ticks) {
                            delete high_usage[i];
                        }
                        // else: still within grace period, duration survives
                    }
                }
            }

            // 2. Spike Detection — deliberately RAW (current vs prev), not
            //    smoothed, since spikes are supposed to be sudden.
            if (spike_detection) {
                let cpu_delta = current.cpu_pct - prev.cpu_pct;
                let gpu_delta = current.gpu_pct - prev.gpu_pct;
                let ram_delta = current.ram_mb - prev.ram_mb;
                let vram_delta = current.vram_mb - prev.vram_mb;

                let types = [];
                let deltas = [];

                if (cpu_delta > cpu_spike_delta) {
                    types.push("cpu");
                    deltas.push(cpu_delta.toFixed(2));
                }
                if (gpu_delta > gpu_spike_delta) {
                    types.push("gpu");
                    deltas.push(gpu_delta.toFixed(2));
                }
                if (ram_delta > ram_spike_delta_mb) {
                    types.push("ram");
                    deltas.push(ram_delta.toFixed(2));
                }
                if (vram_delta > vram_spike_delta_mb) {
                    types.push("vram");
                    deltas.push(vram_delta.toFixed(2));
                }

                // Only emit if a spike actually happened
                if (types.length > 0) {
                    spiked(i, types, deltas);
                }
            }
        }

        // Save current frame as previous for next tick
        _prev_name_process = Object.assign({}, name_process);
    }
}
