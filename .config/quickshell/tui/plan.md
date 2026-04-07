**PROJECT STRUCTURE**
```
~/.config/quickshell/new/
├── shell.qml
├── config/
│   ├── Colors.qml
│   ├── FontMetrics.qml
│   └── Theme.qml
├── services/
│   ├── System.qml
│   ├── Audio.qml
│   ├── Workspaces.qml
│   ├── DateTime.qml
│   ├── Weather.qml
│   ├── Network.qml
│   ├── Bluetooth.qml
│   ├── Notifications.qml
│   └── AppLauncher.qml
├── components/
│   ├── bar/
│   │   ├── Bar.qml
│   │   ├── Workspaces.qml
│   │   ├── FocusedApp.qml
│   │   ├── SystemStats.qml
│   │   ├── Clock.qml
│   │   ├── MediaPlayer.qml
│   │   └── VolumeSlider.qml
│   └── popups/
│       ├── ControlPanel/
│       │   ├── ControlPanel.qml
│       │   ├── AudioTab.qml
│       │   └── NotificationsTab.qml
│       ├── Calendar/
│       │   ├── Calendar.qml
│       │   ├── TimeWeather.qml
│       │   ├── CalendarGrid.qml
│       │   └── Reminders.qml
│       ├── MediaPlayer/
│       │   └── MediaPopup.qml
│       ├── Stats/
│       │   └── StatsPopup.qml
│       └── Launcher/
│           ├── Launcher.qml
│           └── ResultsList.qml
├── modules/
│   ├── ProgressBar.qml
│   ├── Button.qml
│   ├── Checkbox.qml
│   ├── MarqueeText.qml
│   ├── Separator.qml
│   ├── Badge.qml
│   ├── ScrollableList.qml
│   ├── TextInput.qml
│   ├── Icon.qml
│   ├── Tooltip.qml
│   ├── KeyboardNavigable.qml
│   ├── ClickOutsideDismiss.qml
│   └── ContextMenu.qml
├── assets/
└── data/
    └── reminders.json
```

---

**CONFIG**

`Colors.qml` — 12 colors, Hu Tao palette
- Background: `bgBase #151214`, `bgSurface`, `bgOverlay`
- Foreground: `fgBase`, `fgDim`, `fgSubtle`
- Accent: `accentStrong #a32435`, `accentDim`
- Semantic: `success`, `warning`, `danger`
- Border: `borderActive`, `borderInactive`

`FontMetrics.qml` — character grid singleton
- `cellWidth`, `cellHeight`, `font`

`Theme.qml` — re-exports Colors and FontMetrics

---

**BAR**
```
[1][2][•][•][•] [|S|] [nvim — DEVLOG.md] | [CPU 45% RAM 60% GPU 30% VRAM 20%] | [16:42 ●] | [⏮][⏸][⏭] Lose Yourself | [████░ 80%] [⚙]
```
- Workspaces: numbers occupied, dots empty, accent active
- Special workspaces: hidden when empty, shows name when occupied
- Focused app: `appname — truncated title...`
- System stats: click → stats popup
- Clock: red dot when reminder due, click → calendar popup
- Media: hidden when inactive, controls + marquee title
- Volume: interactive progress bar always visible
- Control panel: click → control panel popup

---

**POPUPS**

**System Stats**
```
┌─── CPU ──────┬─── MEMORY ───┬─── NETWORK ──┐
│ AMD R5 7600  │ RAM 4.1/16G  │ Wifi         │
│ ⣀⣤⣶⣿ graph   │ ████░░ 28%   │ Local IP     │
│ Temp/Freq    │ SWAP         │ Receive/Send │
│ Cores/Thread │              │              │
├─── GPU ──────┤─── DISKS ────┤─── PHYS DISK─┤
│ RTX 5060 Ti  │ ROOT 75%     │ SSD 1        │
│ ⣀⣤⣶⣿ graph   │ Storage 88%  │ SSD 2        │
│ Temp/VRAM    │ DISKS IO     │              │
├─── MOBO ─────┤─── POWER ────┤─── OS INFO ──┤
│ B650M        │ CPU/GPU draw │ Arch Linux   │
│              │              │ Kernel/WM    │
└──────────────┴──────────────┴──────────────┘
```

**Calendar**
```
┌─── TIME ─────┬─── APRIL 2026┬─── REMINDERS──┐
│   16:42      │Mo Tu We Th Fr│ ▸ MAE101    ● │
│   Saturday   │          1  2│ ▸ Submit lab  │
│              │ 3  4· 5  6  7│               │
│   Hanoi      │ ...    [27]· │ + Add         │
│   28°C ⛅    │              │               │
└──────────────┴──────────────┴───────────────┘
```
- `[27]` today, `·` has reminder, multi-day events dot start and end
- Selecting a day filters reminders column
- Reminders stored in `reminders.json`
- Red dot on clock when something due today

**Media Player**
```
┌───────────────────────────┐
│ ┌──────┐  Lose Yourself   │
│ │      │  Eminem          │
│ │ ART  │  8 Mile OST      │
│ └──────┘                  │
│ 1:23 ████████░░░░░░░ 5:26 │
│  [⇄]  [⏮]  [⏸]  [⏭]  [↺]  │
└───────────────────────────┘
```
- Album art is the one intentional GUI cheat
- Shuffle and loop dimmed when off, accent when on

**Control Panel**
```
┌─────────────────────────────┐
│ WiFi  [ON ] home_network    │
│ BT    [OFF]                 │
│ [Sleep]  [Reboot]  [Off]    │
├─── [Audio] ── [Notifs] ─────┤
│ (tab content)               │
└─────────────────────────────┘
```
- WiFi/BT drill in place, back via `Esc` or back button
- Audio tab: per-app mixer, input/output dropdowns, master volume pinned at bottom
- Notifications tab: grouped by app, collapsible, `✕` per notification, dim on read, clear all
- Notifications appear as instant toast on arrival

**Launcher**
```
┌─────────────────────┐
│ > search...     = 4 │
├─────┬───┬───┬───┬───┤
│ App │ > │ / │ = │ ? │
├─────┴───┴───┴───┴───┤
│ ▸ result            │
│ ▸ result            │
└─────────────────────┘
```
- `Tab` switches tabs, arrows navigate, `Enter` selects, `Esc` closes/goes back
- Prefix auto-switches tab
- Apps: results on 2+ chars
- Settings: full tree on open, typing filters, drill in place
- Calculator: function hints in list, append on select, result inline right
- Web: history on open, URL detection, otherwise google search
- Python backend: single script, `{ "mode": "...", "query": "..." }` → `{ "results": [...] }`
- Result types: `action`, `submenu`, `append`, `url`

**Desktop Context Menu** — right-click desktop
```
┌─────────────────────┐
│ Change Wallpaper    │
│ Display Settings    │
│ ─────────────────── │
│ Terminal here       │
│ Files here          │
└─────────────────────┘
```

**Context Menu per element:**
- App in launcher → `Open`, `Add to favorites`, `Kill`
- Notification → `Dismiss`, `Open app`
- Workspace → `Close all`, `Move to monitor`
- Media player → `Copy title`, `Open in app`

---

**SERVICES**
- ✓ System, Audio, Workspaces, DateTime, Weather
- ✗ Network, Bluetooth, Notifications
- Launcher backend in Python, on demand via `Process`
- Different polling rates already handled
- Direct import pattern `Service.property`

---

**MODULES**
- `ProgressBar` — interactive + passive, gradient block chars
- `Button` — TUI styled
- `Checkbox` — toggle variant `[ON]/[OFF]`
- `MarqueeText` — scrolling for long titles
- `Separator` — `───` horizontal, `│` vertical
- `Badge` — `(3)` number indicator
- `ScrollableList` — snaps to whole rows
- `TextInput` — launcher and reminders
- `Icon` — nerd font icon wrapper
- `Tooltip` — hover info
- `KeyboardNavigable` — arrows, enter, esc for any list
- `ClickOutsideDismiss` — shield layer below bar above everything
- `ContextMenu` — reusable right-click menu, positions at cursor

---

**DESIGN RULES**
- Font: JetBrains Mono Nerd Font `11pt`
- Everything snaps to character grid via `FontMetrics` singleton
- `Math.round()` on all dimensions
- No border radius, `rounding = 0` in Hyprland
- Borders: `1px` accent active, dimmed inactive
- Gaps: `gaps_in = 2`, `gaps_out = 4`
- Hyprland scale: `1.0` for 1080p
- Braille chars `⣀⣤⣶⣿` for graphs
- Block chars `█ ▓ ▒ ░` for bars
- Box drawing chars `─ │ ┌ ┐ └ ┘` for borders and headers
- Section headers embedded in borders `─── CPU ───`
- Color thresholds: `success` → `warning` → `danger`
- Notifications: instant appear/disappear, no animation
- Album art: one intentional GUI cheat, constrained to cell multiples
- Nested rectangles for layout, no cell by cell design
- Popup layer order: Bar → Popup → Shield → Desktop

---

**BACKLOG**
- TUI themed file explorer with mouse + drag and drop
- Ayano integration as chat overlay
