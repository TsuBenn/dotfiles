pragma Singleton

import qs.services

import Quickshell
import QtQuick

// import Quickshell.Io

Singleton {
    id: root

    // CPU
    property real cpu_spike_delta: 150

    // RAM
    property real ram_spike_delta_mb: 500

    // GPU
    property real vram_spike_delta_mb: 1000

    property real sm_spike_delta: 30
    property real mem_spike_delta: 30
    property real enc_spike_delta: 20
    property real dec_spike_delta: 20

    property int cpu_high_usage: 80.0 * SystemInfo.cputhreads
    property int ram_high_usage_mb: 0.8 * SystemInfo.memtotal
    property int vram_high_usage_mb: 0.8 * SystemInfo.gpumemtotal
    property int sm_high_usage: 80.0
    property int mem_high_usage: 80.0
    property int enc_high_usage: 80.0
    property int dec_high_usage: 80.0

    // How long does it take to alert the user about the sustained high usage
    property int high_usage_milestone: 5 * 60 // seconds

    // How long does it take to consider a process to be sustained high usage
    property int sustained_high_usage_threshold: 10 // seconds

    property int sustained_grace_ticks: 10

    signal spiked(spike_data: var)
    signal sustained(sustained_data: var)
    signal sustainEnded(sustained_data: var)
    signal updated

    onSpiked: data => {
        // NotificationsInfo.send("", "", "SPIKED!", `${data.program} ${JSON.stringify(data.spikes)} `, 0, true, "echo hello");
        logSpike(data);
    }
    onSustained: data => {
    // NotificationsInfo.send("", "", "SUSTAINED!", `${data.program} ${JSON.stringify(data.metrics)} ${JSON.stringify(DateTime.getDuration(data.startTime) / 1000)}`, 0, true, "echo hello");
    }

    onSustainEnded: data => {
        logSustained(data);
    // console.log(JSON.stringify(data, null, 2));
    }

    property bool spike_detection: true
    property bool sustained_detection: true

    property var system: ({})
    property var process: SystemInfo.process
    property var clean_process: ({})

    onProcessChanged: {
        index();
        spikeCheck();
        sustainedCheck();
        logTick();
        updated();
    }

    property var sustained_data: ({})

    property var _prev_spiked_data: ({})

    property var _prev_name_process: ({})

    property var name_process: ({})
    property var programs: []

    // I don't know really I don't think I'd use PID that much anyway
    // property var pid_process: ({})
    // property var pids: Object.keys(pid_process)

    property var high_usage: ({})

    // Connections {
    //     target: SettingsInfo
    //     function onDebugSig() {
    //         // console.log(JSON.stringify(root.getSortedCPU(5), null, 2));
    //         // console.log(JSON.stringify(root.sustained_data, null, 2));
    //         // console.log(Object.values({}));
    //         console.log(DateTime.getStartDay().getTime());
    //         console.log(DateTime.getEndDay().getTime());
    //     }
    // }

    Connections {
        target: DBInfo
        function onActiveChanged() {
            if (DBInfo.active) {
                root.initDB();
            }
        }
    }

    function initDB(callback) {
        DBInfo.execMany([DBInfo.sql`
                CREATE TABLE IF NOT EXISTS uptime.system_ticks (
                    timestamp INTEGER DEFAULT (CAST(unixepoch('subsec')*1000 AS INTEGER)),
                    cpu_pct REAL DEFAULT 0,
                    ram_mb REAL DEFAULT 0,
                    vram_mb REAL DEFAULT 0,
                    sm_pct REAL DEFAULT 0,
                    mem_pct REAL DEFAULT 0,
                    enc_pct REAL DEFAULT 0,
                    dec_pct REAL DEFAULT 0
                )
        `, DBInfo.sql`
            CREATE INDEX IF NOT EXISTS uptime.idx_ticks_time ON system_ticks(timestamp)
        `, DBInfo.sql`
                CREATE TABLE IF NOT EXISTS uptime.process_ticks (
                    timestamp INTEGER DEFAULT (CAST(unixepoch('subsec')*1000 AS INTEGER)),
                    program TEXT NOT NULL,
                    pid TEXT NOT NULL,
                    cpu_pct REAL DEFAULT 0,
                    ram_mb REAL DEFAULT 0,
                    vram_mb REAL DEFAULT 0,
                    gpu_type TEXT DEFAULT 'N/A',
                    sm_pct REAL DEFAULT 0,
                    mem_pct REAL DEFAULT 0,
                    enc_pct REAL DEFAULT 0,
                    dec_pct REAL DEFAULT 0
                )
        `, DBInfo.sql`
            CREATE INDEX IF NOT EXISTS uptime.idx_ticks_name ON process_ticks(program)
        `, DBInfo.sql`
            CREATE INDEX IF NOT EXISTS uptime.idx_ticks_time ON process_ticks(timestamp)
        `, DBInfo.sql`
            CREATE TABLE IF NOT EXISTS spikes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                start_time INTEGER NOT NULL,
                program TEXT NOT NULL,
                pid TEXT NOT NULL,
                severity TEXT DEFAULT 'normal',
                severity_score INTEGER DEFAULT 1,
                cpu_delta REAL,
                ram_delta REAL,
                vram_delta REAL,
                gpu_type TEXT DEFAULT 'N/A',
                sm_delta REAL,
                mem_delta REAL,
                enc_delta REAL,
                dec_delta REAL
            )
        `, DBInfo.sql`
            CREATE INDEX IF NOT EXISTS idx_spikes_time ON spikes(start_time)
        `, DBInfo.sql`
            CREATE INDEX IF NOT EXISTS idx_spikes_prog_time ON spikes(program, start_time)
        `, DBInfo.sql`
            CREATE TABLE IF NOT EXISTS sustained (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                start_time INTEGER NOT NULL,
                duration INTEGER NOT NULL,
                program TEXT NOT NULL,
                pid TEXT NOT NULL,
                milestone INTEGER DEFAULT 0,
                avg_cpu REAL,
                avg_ram REAL,
                avg_vram REAL,
                gpu_type TEXT DEFAULT 'N/A',
                avg_sm REAL,
                avg_mem REAL,
                avg_enc REAL,
                avg_dec REAL
            )
        `, DBInfo.sql`
            CREATE INDEX IF NOT EXISTS idx_sustained_time ON sustained(start_time)
        `, DBInfo.sql`
            CREATE INDEX IF NOT EXISTS idx_sustained_prog_time ON sustained(program, start_time)
        `], callback);
    }

    function copyMetrics(src) {
        src = src || {};
        return {
            cpu_pct: src.cpu_pct || 0,
            ram_mb: src.ram_mb || 0,
            vram_mb: src.vram_mb || 0,
            sm_pct: src.sm_pct || 0,
            mem_pct: src.mem_pct || 0,
            enc_pct: src.enc_pct || 0,
            dec_pct: src.dec_pct || 0
        };
    }

    function getRealTimeTicks(callback) {
        DBInfo.query(DBInfo.sql`
            SELECT
                timestamp,
                cpu_pct,
                ram_mb,
                vram_mb,
                sm_pct,
                mem_pct,
                enc_pct,
                dec_pct
            FROM system_ticks
            ORDER BY timestamp DESC
        `, callback);
    }

    function getProcessTicks(timestamp, callback) {
        DBInfo.query(DBInfo.sql`
            SELECT
                timestamp,
                program,
                pid,
                cpu_pct,
                ram_mb,
                vram_mb,
                sm_pct,
                mem_pct,
                enc_pct,
                dec_pct
            FROM process_ticks
            WHERE timestamp = ${timestamp}
            ORDER BY timestamp DESC
        `, callback);
    }

    function getSortedCPU(max: int): var {
        if (!clean_process || !Array.isArray(clean_process))
            return [];

        const getGpuPeak = p => Math.max(p.sm_pct || 0, p.mem_pct || 0, p.enc_pct || 0, p.dec_pct || 0);

        return clean_process.slice().sort((a, b) => {
            const cpuDiff = (b.cpu_pct || 0) - (a.cpu_pct || 0);
            if (Math.abs(cpuDiff) > 0.001)
                return cpuDiff;

            const ramDiff = (b.ram_mb || 0) - (a.ram_mb || 0);
            if (ramDiff !== 0)
                return ramDiff;

            const vramDiff = (b.vram_mb || 0) - (a.vram_mb || 0);
            if (vramDiff !== 0)
                return vramDiff;

            return getGpuPeak(b) - getGpuPeak(a);
        }).slice(0, max == 0 ? process.length : max);
    }

    function getSortedRAM(max: int): var {
        if (!clean_process || !Array.isArray(clean_process))
            return [];

        const getGpuPeak = p => Math.max(p.sm_pct || 0, p.mem_pct || 0, p.enc_pct || 0, p.dec_pct || 0);

        return clean_process.slice().sort((a, b) => {
            const ramDiff = (b.ram_mb || 0) - (a.ram_mb || 0);
            if (ramDiff !== 0)
                return ramDiff;

            const vramDiff = (b.vram_mb || 0) - (a.vram_mb || 0);
            if (vramDiff !== 0)
                return vramDiff;

            const cpuDiff = (b.cpu_pct || 0) - (a.cpu_pct || 0);
            if (Math.abs(cpuDiff) > 0.001)
                return cpuDiff;

            return getGpuPeak(b) - getGpuPeak(a);
        }).slice(0, max == 0 ? clean_process.length : max);
    }

    function getSortedVRAM(max: int): var {
        if (!clean_process || !Array.isArray(clean_process))
            return [];

        const getGpuPeak = p => Math.max(p.sm_pct || 0, p.mem_pct || 0, p.enc_pct || 0, p.dec_pct || 0);

        return clean_process.slice().sort((a, b) => {
            const vramDiff = (b.vram_mb || 0) - (a.vram_mb || 0);
            if (vramDiff !== 0)
                return vramDiff;

            const gpuDiff = getGpuPeak(b) - getGpuPeak(a);
            if (Math.abs(gpuDiff) > 0.001)
                return gpuDiff;

            const ramDiff = (b.ram_mb || 0) - (a.ram_mb || 0);
            if (ramDiff !== 0)
                return ramDiff;

            return (b.cpu_pct || 0) - (a.cpu_pct || 0);
        }).slice(0, max == 0 ? clean_process.length : max);
    }

    function getSortedSM(max: int): var {
        if (!clean_process || !Array.isArray(clean_process))
            return [];

        return clean_process.slice().sort((a, b) => {
            const smDiff = (b.sm_pct || 0) - (a.sm_pct || 0);
            if (Math.abs(smDiff) > 0.001)
                return smDiff;

            const vramDiff = (b.vram_mb || 0) - (a.vram_mb || 0);
            if (vramDiff !== 0)
                return vramDiff;

            const cpuDiff = (b.cpu_pct || 0) - (a.cpu_pct || 0);
            if (Math.abs(cpuDiff) > 0.001)
                return cpuDiff;

            return (b.ram_mb || 0) - (a.ram_mb || 0);
        }).slice(0, max == 0 ? clean_process.length : max);
    }

    function getSortedMEM(max: int): var {
        if (!clean_process || !Array.isArray(clean_process))
            return [];

        return clean_process.slice().sort((a, b) => {
            const memDiff = (b.mem_pct || 0) - (a.mem_pct || 0);
            if (Math.abs(memDiff) > 0.001)
                return memDiff;

            const vramDiff = (b.vram_mb || 0) - (a.vram_mb || 0);
            if (vramDiff !== 0)
                return vramDiff;

            const cpuDiff = (b.cpu_pct || 0) - (a.cpu_pct || 0);
            if (Math.abs(cpuDiff) > 0.001)
                return cpuDiff;

            return (b.ram_mb || 0) - (a.ram_mb || 0);
        }).slice(0, max == 0 ? clean_process.length : max);
    }

    function getSortedENC(max: int): var {
        if (!clean_process || !Array.isArray(clean_process))
            return [];

        return clean_process.slice().sort((a, b) => {
            const encDiff = (b.enc_pct || 0) - (a.enc_pct || 0);
            if (Math.abs(encDiff) > 0.001)
                return encDiff;

            const decDiff = (b.dec_pct || 0) - (a.dec_pct || 0);
            if (Math.abs(decDiff) > 0.001)
                return decDiff;

            const cpuDiff = (b.cpu_pct || 0) - (a.cpu_pct || 0);
            if (Math.abs(cpuDiff) > 0.001)
                return cpuDiff;

            return (b.vram_mb || 0) - (a.vram_mb || 0);
        }).slice(0, max == 0 ? clean_process.length : max);
    }

    function getSortedDEC(max: int): var {
        if (!clean_process || !Array.isArray(clean_process))
            return [];

        return clean_process.slice().sort((a, b) => {
            const decDiff = (b.dec_pct || 0) - (a.dec_pct || 0);
            if (Math.abs(decDiff) > 0.001)
                return decDiff;

            const encDiff = (b.enc_pct || 0) - (a.enc_pct || 0);
            if (Math.abs(encDiff) > 0.001)
                return encDiff;

            const cpuDiff = (b.cpu_pct || 0) - (a.cpu_pct || 0);
            if (Math.abs(cpuDiff) > 0.001)
                return cpuDiff;

            return (b.vram_mb || 0) - (a.vram_mb || 0);
        }).slice(0, max == 0 ? clean_process.length : max);
    }

    /*

    {
      "program": "ollama",
      "pid": 1204,
      "startTime": 300000,
      "milestone": 2,
      "metrics": {
        "cpu": 720.0,
        "mem": 88.5
      },
      "baseline": {
        "cpu_pct": 700.0,
        "ram_mb": 2048,
        ...
      },
      "current": {
        "cpu_pct": 720.0,
        "ram_mb": 2048,
        ...
      }
    }

    */
    function sustainedCheck() {
        let high_usage = {};
        const now = Date.now();
        const milestoneMs = high_usage_milestone * 1000; // Convert minutes to ms

        // Map metric keys to process property names
        const metricKeyMap = {
            cpu: 'cpu_pct',
            ram: 'ram_mb',
            vram: 'vram_mb',
            sm: 'sm_pct',
            mem: 'mem_pct',
            enc: 'enc_pct',
            dec: 'dec_pct'
        };

        for (const p of programs) {
            const current = name_process[p];
            if (!current)
                continue;

            let metric = {};
            let exceeded = false;

            // 1. Check process object against correct thresholds
            if ((current.cpu_pct || 0) > cpu_high_usage) {
                metric.cpu = current.cpu_pct;
                exceeded = true;
            }
            if ((current.ram_mb || 0) > ram_high_usage_mb) {
                metric.ram = current.ram_mb;
                exceeded = true;
            }
            if ((current.vram_mb || 0) > vram_high_usage_mb) {
                metric.vram = current.vram_mb;
                exceeded = true;
            }
            if ((current.sm_pct || 0) > sm_high_usage) {
                metric.sm = current.sm_pct;
                exceeded = true;
            }
            if ((current.mem_pct || 0) > mem_high_usage) {
                metric.mem = current.mem_pct;
                exceeded = true;
            }
            if ((current.enc_pct || 0) > enc_high_usage) {
                metric.enc = current.enc_pct;
                exceeded = true;
            }
            if ((current.dec_pct || 0) > dec_high_usage) {
                metric.dec = current.dec_pct;
                exceeded = true;
            }

            if (Object.keys(metric).length === 0) {
                metric = sustained_data[p]?.metrics ?? {};
            }

            if (sustained_data[p]) {
                high_usage[p] = sustained_data[p];

                high_usage[p].totals = high_usage[p].totals || {};
                high_usage[p].sample_counts = high_usage[p].sample_counts || {};
                high_usage[p].avg_metrics = {};

                // 2. Only compute running averages for active metric keys
                for (const key of Object.keys(metric)) {
                    const prop = metricKeyMap[key] || key;
                    const val = current[prop] || 0;

                    high_usage[p].totals[key] = (high_usage[p].totals[key] || 0) + val;
                    high_usage[p].sample_counts[key] = (high_usage[p].sample_counts[key] || 0) + 1;
                    high_usage[p].avg_metrics[key] = high_usage[p].totals[key] / high_usage[p].sample_counts[key];
                }

                // Milestone time division
                const elapsedMs = now - high_usage[p].startTime;
                const currentMilestone = Math.floor(elapsedMs / milestoneMs);

                high_usage[p].pid = current.pid;
                high_usage[p].metrics = metric;
                high_usage[p].current = copyMetrics(current);

                // Fire signal on new milestone
                if (currentMilestone > high_usage[p].milestone) {
                    high_usage[p].milestone = currentMilestone;

                    sustained(high_usage[p]);
                }

                // Tick cooldown buffer
                if (!exceeded) {
                    high_usage[p].cooldown -= 1;
                } else {
                    high_usage[p].cooldown = sustained_grace_ticks;
                }

                if (high_usage[p].cooldown <= 0) {
                    delete high_usage[p];
                }
            } else {
                if (exceeded) {
                    const initTotals = {};
                    const initCounts = {};
                    const initAvg = {};

                    // 3. Initialize metrics tracking only for active keys
                    for (const key of Object.keys(metric)) {
                        const prop = metricKeyMap[key] || key;
                        const val = current[prop] || 0;
                        initTotals[key] = val;
                        initCounts[key] = 1;
                        initAvg[key] = val;
                    }

                    high_usage[p] = {
                        program: p,
                        pid: current.pid,
                        startTime: now,
                        milestone: 0,
                        cooldown: sustained_grace_ticks,
                        metrics: metric,
                        totals: initTotals,
                        sample_counts: initCounts,
                        avg_metrics: initAvg,
                        baseline: copyMetrics(current),
                        current: copyMetrics(current)
                    };
                }
            }
        }

        let high_usage_keys = Object.keys(high_usage);
        for (const d of Object.keys(sustained_data)) {
            if (!high_usage_keys.includes(d) && DateTime.getDuration(sustained_data[d].startTime) / 1000 > sustained_high_usage_threshold) {
                // console.log(JSON.stringify(sustained_data, null, 2));
                root.sustainEnded(sustained_data[d]);
            }
        }

        sustained_data = high_usage;
    }

    /*

     {
        "program": "ollama",
        "pid": 1204,
        "startTime": 1775124745120,
        "severity": "warning",
        "peakSeverityScore": 6,
        "spikes": {
            "cpu": 150.0,
            "vram": 1024.0
            ...
        },
        "baseline": {
            "cpu_pct": 5.0,  "ram_mb": 512, "vram_mb": 1024,
            "sm_pct": 0.0,  "mem_pct": 0.0, "enc_pct": 0.0, "dec_pct": 0.0
            ...
        },
        "current": {
            "cpu_pct": 155.0, "ram_mb": 512, "vram_mb": 2048,
            "sm_pct": 0.0,   "mem_pct": 0.0, "enc_pct": 0.0, "dec_pct": 0.0
            ...
        }
    }

    */
    function spikeCheck() {
        for (const p of programs) {
            const current = name_process[p];
            if (!current)
                continue;

            // 1. First-tick skip: Seed initial state so we don't spike against zero
            if (!_prev_name_process[p]) {
                _prev_name_process[p] = copyMetrics(current);
                continue;
            }

            const prev = _prev_name_process[p];

            // 2. Evaluate deltas across all hardware metrics
            let severityScore = 0;
            let currentTickDeltas = {};
            let activeThisTick = new Set();

            const metrics = [
                {
                    key: "cpu",
                    threshold: cpu_spike_delta,
                    delta: (current.cpu_pct || 0) - prev.cpu_pct
                },
                {
                    key: "ram",
                    threshold: ram_spike_delta_mb,
                    delta: (current.ram_mb || 0) - prev.ram_mb
                },
                {
                    key: "vram",
                    threshold: vram_spike_delta_mb,
                    delta: (current.vram_mb || 0) - prev.vram_mb
                },
                {
                    key: "sm",
                    threshold: sm_spike_delta,
                    delta: (current.sm_pct || 0) - prev.sm_pct
                },
                {
                    key: "mem",
                    threshold: mem_spike_delta,
                    delta: (current.mem_pct || 0) - prev.mem_pct
                },
                {
                    key: "enc",
                    threshold: enc_spike_delta,
                    delta: (current.enc_pct || 0) - prev.enc_pct
                },
                {
                    key: "dec",
                    threshold: dec_spike_delta,
                    delta: (current.dec_pct || 0) - prev.dec_pct
                }
            ];

            for (const m of metrics) {
                if (m.delta > m.threshold) {
                    currentTickDeltas[m.key] = m.delta;
                    activeThisTick.add(m.key);
                    severityScore += 1;

                    const ratio = m.delta / m.threshold;
                    severityScore += Math.floor(ratio);
                }
            }

            // 3. Lifecycle Evaluation (Option C - Flush-on-Retrigger)
            if (severityScore > 1) {
                let tracking = _prev_spiked_data[p];

                // Check if any metric surging NOW previously cooled off in this same window
                let isRetriggered = false;
                if (tracking && tracking.cooledMetrics) {
                    for (const key of activeThisTick) {
                        if (tracking.cooledMetrics.has(key)) {
                            isRetriggered = true;
                            break;
                        }
                    }
                }

                // Flush Wave 1 immediately if a cooled metric re-triggered
                if (isRetriggered && tracking) {
                    tracking.duration_ms = Date.now() - tracking.startTime;
                    tracking.current = copyMetrics(prev);
                    spiked(tracking);

                    delete _prev_spiked_data[p];
                    tracking = null;
                }

                // Initialize tracking for a new surge wave
                if (!tracking) {
                    _prev_spiked_data[p] = {
                        program: p,
                        pid: current.pid,
                        startTime: Date.now(),
                        severity: "normal",
                        peakSeverityScore: 0,
                        baseline: copyMetrics(prev),
                        spikes: {},
                        historyMetrics: new Set(),
                        cooledMetrics: new Set()
                    };
                    tracking = _prev_spiked_data[p];
                }

                // Identify metrics that were active before but paused on this tick
                for (const key of tracking.historyMetrics) {
                    if (!activeThisTick.has(key)) {
                        tracking.cooledMetrics.add(key);
                    }
                }

                // Accumulate active deltas for this tick
                for (const key in currentTickDeltas) {
                    tracking.spikes[key] = (tracking.spikes[key] || 0) + currentTickDeltas[key];
                    tracking.historyMetrics.add(key);
                }

                // Update peak severity score reached during this wave
                if (severityScore > tracking.peakSeverityScore) {
                    tracking.peakSeverityScore = severityScore;
                    tracking.severity = severityScore > 8 ? "critical" : (severityScore > 4 ? "warning" : "normal");
                }
            } else {
                // 4. State B: All metrics settled below threshold
                if (_prev_spiked_data[p]) {
                    let finalReport = _prev_spiked_data[p];
                    finalReport.duration_ms = Date.now() - finalReport.startTime;
                    finalReport.current = copyMetrics(current);

                    spiked(finalReport);
                    delete _prev_spiked_data[p];
                }
            }

            // 5. Always seed state for the next tick comparison
            _prev_name_process[p] = copyMetrics(current);
        }
    }

    function logSustained(data, callback) {
        if (!data || !data.program) {
            if (callback)
                callback(null);
            return;
        }

        let avg = data.avg_metrics || {};
        let now = Date.now();
        let durationMs = data.startTime ? (now - data.startTime) : 0;
        let pidsJson = Array.isArray(data.pid) ? JSON.stringify(data.pid) : JSON.stringify([data.pid]);

        let stmt = DBInfo.sql`
        INSERT INTO sustained (
            start_time,
            duration,
            program,
            pid,
            milestone,
            avg_cpu,
            avg_ram,
            avg_vram,
            gpu_type,
            avg_sm,
            avg_mem,
            avg_enc,
            avg_dec
        ) VALUES (
            ${data.startTime || now},
            ${durationMs},
            ${data.program},
            ${pidsJson},
            ${data.milestone || 0},
            ${avg.cpu !== undefined ? avg.cpu : null},
            ${avg.ram !== undefined ? avg.ram : null},
            ${avg.vram !== undefined ? avg.vram : null},
            ${data.current?.gpu_type || 'N/A'},
            ${avg.sm !== undefined ? avg.sm : null},
            ${avg.mem !== undefined ? avg.mem : null},
            ${avg.enc !== undefined ? avg.enc : null},
            ${avg.dec !== undefined ? avg.dec : null}
        )
    `;

        DBInfo.exec(stmt, callback);
    }

    function logSpike(data, callback) {
        if (!data || !data.program) {
            if (callback)
                callback(null);
            return;
        }

        let s = data.spikes || {};
        let pidsJson = Array.isArray(data.pid) ? JSON.stringify(data.pid) : JSON.stringify([data.pid]);

        let stmt = DBInfo.sql`
        INSERT INTO spikes (
            start_time,
            program,
            pid,
            severity,
            severity_score,
            cpu_delta,
            ram_delta,
            vram_delta,
            gpu_type,
            sm_delta,
            mem_delta,
            enc_delta,
            dec_delta
        ) VALUES (
            ${data.startTime || Date.now()},
            ${data.program},
            ${pidsJson},
            ${data.severity || 'normal'},
            ${data.peakSeverityScore || 1},
            ${s.cpu !== undefined ? s.cpu : null},
            ${s.ram !== undefined ? s.ram : null},
            ${s.vram !== undefined ? s.vram : null},
            ${data.current?.gpu_type || 'N/A'},
            ${s.sm !== undefined ? s.sm : null},
            ${s.mem !== undefined ? s.mem : null},
            ${s.enc !== undefined ? s.enc : null},
            ${s.dec !== undefined ? s.dec : null}
        )
    `;

        DBInfo.exec(stmt, callback);
    }

    // Just logging no calculations until requested
    function logTick(callback) {
        if (!clean_process || clean_process.length === 0)
            return;

        let topCPU = getSortedCPU(5).map(p => p.program);
        let topGPU = getSortedSM(5).map(p => p.program);
        let topRAM = getSortedRAM(5).map(p => p.program);
        let topVRAM = getSortedVRAM(5).map(p => p.program);

        let topProcesses = new Set();

        topCPU.forEach(p => topProcesses.add(p));
        topGPU.forEach(p => topProcesses.add(p));
        topRAM.forEach(p => topProcesses.add(p));
        topVRAM.forEach(p => topProcesses.add(p));

        let now = Date.now();

        console.log(JSON.stringify(name_process[[...topProcesses][0]]));

        // 5. Convert to SQL statements
        let statements = [...topProcesses].map(p => DBInfo.sql`
            INSERT INTO uptime.process_ticks
            (timestamp, program, pid, cpu_pct, ram_mb, vram_mb, gpu_type, sm_pct, mem_pct, enc_pct, dec_pct)
            VALUES (
                ${now},
                ${name_process[p].name || name_process[p].program},
                ${JSON.stringify(name_process[p].pid)},
                ${name_process[p].cpu_pct || 0},
                ${name_process[p].ram_mb || 0},
                ${name_process[p].vram_mb || 0},
                ${name_process[p].gpu_type || ''},
                ${name_process[p].sm_pct || 0},
                ${name_process[p].mem_pct || 0},
                ${name_process[p].enc_pct || 0},
                ${name_process[p].dec_pct || 0}
            )
        `);

        // 6. Always include total system usage
        statements.push(DBInfo.sql`
            INSERT INTO uptime.system_ticks
            (timestamp, cpu_pct, ram_mb, vram_mb, sm_pct, mem_pct, enc_pct, dec_pct)
            VALUES (
                ${now},
                ${SystemInfo.cpuusage},
                ${SystemInfo.memused / 1024},
                ${SystemInfo.gpumemused / 1024},
                ${SystemInfo.gpusm},
                ${SystemInfo.gpumem},
                ${SystemInfo.gpuenc},
                ${SystemInfo.gpudec}
            )
        `);

        DBInfo.execMany(statements, callback);
    }

    function index() {
        let name = [];
        let ps = {};
        _prev_name_process = Object.assign({}, name_process);
        for (const p of process) {
            if (!ps[p.name]) {
                ps[p.name] = {
                    program: p.name,
                    pid: [p.pid],
                    cpu_pct: p.cpu_pct,
                    ram_mb: p.ram_mb,
                    vram_mb: p.vram_mb,
                    gpu_type: p.gpu_type,
                    gpu_pct: Math.max(p.sm_pct, p.mem_pct, p.enc_pct, p.dec_pct),
                    sm_pct: p.sm_pct,
                    mem_pct: p.mem_pct,
                    enc_pct: p.enc_pct,
                    dec_pct: p.dec_pct
                };
                name.push(p.name);
            } else {
                ps[p.name].pid.push(p.pid);
                ps[p.name].cpu_pct += p.cpu_pct;
                ps[p.name].ram_mb += p.ram_mb;
                ps[p.name].vram_mb += p.vram_mb;
                ps[p.name].sm_pct += p.sm_pct;
                ps[p.name].mem_pct += p.mem_pct;
                ps[p.name].enc_pct += p.enc_pct;
                ps[p.name].dec_pct += p.dec_pct;
            }
        }
        clean_process = Object.values(ps);
        name_process = ps;
        programs = name;
    }
}
