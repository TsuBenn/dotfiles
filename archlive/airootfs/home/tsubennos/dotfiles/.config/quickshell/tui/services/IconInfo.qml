pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

// ─────────────────────────────────────────────────────────────────
// IconInfo — icon lookup service with layered resolution.
//
// Loads icon_cache.json (written by launcher.py) and provides fetch()
// for the rest of the shell to look up icon paths by name.
//
// Cache file format (JSON):
//   {
//     "icons":   { "firefox": "/usr/.../firefox.png", ... },
//     "aliases": {
//       "binary": { "google-chrome-stable": "google-chrome", ... },
//       "app":    { "zen browser": "zen", ... }
//     }
//   }
//
// Also tolerates the old list format:
//   [{"name": "firefox", "icon": "/usr/.../firefox.png"}, ...]
//
// Lookup order in fetch():
//   1. Direct hit on icons (case-sensitive)
//   2. Case-insensitive hit on _index
//   3. Binary alias (binary name → icon name → icons)
//   4. App name alias (display name → icon name → icons)
//   5. Bidirectional substring (last resort, longest match wins)
//
// A negative cache (_missCache) records queries that hit nothing in
// layers 1-4, so subsequent calls for the same query skip straight to
// the substring fallback (or return "" if substring is disabled).
// ─────────────────────────────────────────────────────────────────

Singleton {

    id: root

    // ── Raw data from cache file ──
    // {icon_name: path} — every icon file on disk, keyed by stem.
    property var icons: ({})

    // {binary_name: icon_name} — from .desktop Exec fields.
    // Catches "google-chrome-stable" → "google-chrome" style mismatches.
    property var binaryAliases: ({})

    // {lowercased_app_name: icon_name} — from .desktop Name fields.
    // Catches "Zen Browser" → "zen" style display-name queries.
    property var appAliases: ({})

    // ── Indexes (built when raw data changes) ──
    // {lowercased_icon_name: path} — for O(1) case-insensitive lookup.
    property var _index: ({})

    // {lowercased_query: icon_name} — combined binary + app aliases,
    // lowercased for case-insensitive lookup.
    property var _aliasIndex: ({})

    // ── Negative cache ──
    // {lowercased_query: true} — queries that missed all layers 1-4.
    // Subsequent calls skip the lookups and go straight to substring
    // (or return "" if substring is disabled).
    property var _missCache: ({})
    readonly property int _missCacheMax: 256

    FileView {
        id: cache

        path: SystemInfo.configdir + "/scripts/icon_cache.json"

        onLoaded: {
            try {
                const data = JSON.parse(text())
                _loadFromData(data)
            } catch (e) {
                console.warn("IconInfo: failed to parse icon_cache.json: " + e)
                root.icons = {}
                root.binaryAliases = {}
                root.appAliases = {}
                root._rebuildIndex()
            }
        }
    }

    function _loadFromData(data) {
        // Old format: list of {name, icon} objects
        if (Array.isArray(data)) {
            const dict = {}
            for (const item of data) {
                if (item && item.name && item.icon) {
                    dict[item.name] = item.icon
                }
            }
            root.icons = dict
            root.binaryAliases = {}
            root.appAliases = {}
        }
        // New format: dict with icons + aliases
        else if (data && typeof data === "object") {
            const icons = data.icons
            if (Array.isArray(icons)) {
                // icons field is a list (shouldn't happen with new format,
                // but defensive) — convert to dict
                const dict = {}
                for (const item of icons) {
                    if (item && item.name && item.icon) {
                        dict[item.name] = item.icon
                    }
                }
                root.icons = dict
            } else {
                root.icons = icons || {}
            }
            const aliases = data.aliases || {}
            root.binaryAliases = aliases.binary || {}
            root.appAliases = aliases.app || {}
        } else {
            root.icons = {}
            root.binaryAliases = {}
            root.appAliases = {}
        }
        root._rebuildIndex()
    }

    function _rebuildIndex() {
        // Case-insensitive icon name index
        const idx = {}
        for (const name in root.icons) {
            idx[name.toLowerCase()] = root.icons[name]
        }
        root._index = idx

        // Combined alias index (binary + app), lowercased keys
        const aIdx = {}
        for (const k in root.binaryAliases) {
            aIdx[k.toLowerCase()] = root.binaryAliases[k]
        }
        for (const k in root.appAliases) {
            const kl = k.toLowerCase()
            if (!(kl in aIdx)) {  // don't overwrite binary aliases
                aIdx[kl] = root.appAliases[k]
            }
        }
        root._aliasIndex = aIdx

        // Invalidate the negative cache — old misses might now be hits
        // after a cache refresh.
        root._missCache = {}
    }

    function reload() {
        cache.reload()
    }

    // ── fetch(queries) ──
    // Accepts a single string or an array of strings. Returns the first
    // match's path, or "" if none found.
    //
    // For each query, we try the layered lookups. The first query that
    // produces a hit wins. If no query hits, we return "".
    //
    // Layered lookup per query:
    //   0. Negative cache check (skip if we already know it misses)
    //   1. Direct hit on icons[q]
    //   2. Case-insensitive hit on _index[q.toLowerCase()]
    //   3. Alias lookup: _aliasIndex[q.toLowerCase()] → icon name → icons
    //   4. Substring fallback (last resort, see _substringLookup)
    //
    // The substring fallback is bidirectional and uses "longest match
    // wins" to disambiguate. It's O(N) and can return wrong icons in
    // edge cases, but only fires when layers 1-3 all miss — rare for
    // well-named apps with .desktop files.
    function fetch(queries) {
        let qs
        if (Array.isArray(queries)) {
            qs = queries
        } else if (typeof queries === "string") {
            qs = [queries]
        } else {
            return ""
        }

        for (let q of qs) {
            if (!q) continue

            // Strip extension if present ("firefox.png" → "firefox")
            const dot = q.lastIndexOf('.')
            if (dot > 0) {
                q = q.substring(0, dot)
            }
            if (!q) continue

            const qLower = q.toLowerCase()

            // 0. Negative cache check
            if (root._missCache[qLower]) {
                continue
            }

            // 1. Direct case-sensitive hit
            if (root.icons[q]) {
                return root.icons[q]
            }

            // 2. Case-insensitive hit
            if (root._index[qLower]) {
                return root._index[qLower]
            }

            // 3. Alias lookup (binary or app name → icon name → path)
            const aliased = root._aliasIndex[qLower]
            if (aliased) {
                // Resolve the alias to an actual icon path
                if (root.icons[aliased]) {
                    return root.icons[aliased]
                }
                // The aliased name might itself need case-insensitive lookup
                const aliasedLower = aliased.toLowerCase()
                if (root._index[aliasedLower]) {
                    return root._index[aliasedLower]
                }
            }

            // 4. Substring fallback (last resort)
            const subMatch = _substringLookup(qLower)
            if (subMatch) {
                return subMatch
            }

            // Record the miss so future calls skip the lookups
            _missCacheAdd(qLower)
        }
        return ""
    }

    // Bidirectional substring lookup with "longest match wins".
    //
    // For a query q and icon name n (both lowercased):
    //   - If n.includes(q) → n contains the query (e.g., q="firefox",
    //     n="firefox-developer-edition")
    //   - If q.includes(n) → query contains n (e.g., q="google-chrome-stable",
    //     n="google-chrome")
    //
    // When multiple names match, the longest match wins. Rationale:
    // longer matches are more specific and more likely to be correct.
    // For "firefox-developer-edition" query, both "firefox" (7) and
    // "firefox-developer-edition" (25) match via q.includes(n) — the
    // longer one wins, which is the more specific icon.
    //
    // Returns the path for the best match, or "" if no match.
    function _substringLookup(qLower) {
        if (!qLower || qLower.length < 2) return ""

        let bestName = ""
        let bestLen = 0

        for (const name in root._index) {
            const nLower = name.toLowerCase()
            // Skip very short names — high false-positive rate
            if (nLower.length < 2) continue

            const matches = nLower.includes(qLower) || qLower.includes(nLower)
            if (!matches) continue

            // Prefer the longest matching name (more specific)
            if (nLower.length > bestLen) {
                bestLen = nLower.length
                bestName = name
            }
        }

        return bestName ? root._index[bestName] : ""
    }

    function _missCacheAdd(key) {
        if (Object.keys(root._missCache).length >= root._missCacheMax) {
            // Evict half (oldest first — dict preserves insertion order)
            const keys = Object.keys(root._missCache)
            const evictCount = Math.floor(keys.length / 2)
            for (let i = 0; i < evictCount; i++) {
                delete root._missCache[keys[i]]
            }
        }
        root._missCache[key] = true
    }

}

