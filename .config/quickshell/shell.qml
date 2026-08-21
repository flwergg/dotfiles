import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "./components"

ShellRoot {
    id: root

    property string configPath: Quickshell.env("HOME") + "/.config/quickshell"
    property string homePath: Quickshell.env("HOME")
    property string wallpaperPath: homePath + "/Pictures/Fonditos"
    property string cachePath: homePath + "/.cache"

    property bool musicVisible: false
    property bool launcherVisible: false
    property bool wifiVisible: false
    property bool btVisible: false
    property bool calendarVisible: false
    property bool clipboardVisible: false
    property bool emojiVisible: false
    property bool osdVisible: false
    property string searchTerm: ""
    property var appList: []
    property var appUsage: ({})
    property var filteredApps: {
        var source = appList
        var usage = appUsage
        if (searchTerm !== "") {
            var result = []
            for (var i = 0; i < source.length; i++) {
                var entry = source[i]
                if (entry.name.toLowerCase().includes(searchTerm) || entry.exec.toLowerCase().includes(searchTerm)) {
                    result.push(entry)
                }
            }
            source = result
        }
        var sorted = source.slice().sort(function(a, b) {
            var countA = usage[a.name] || 0
            var countB = usage[b.name] || 0
            if (countB !== countA) return countB - countA
            return a.name.localeCompare(b.name)
        })
        return sorted
    }
    property int selectedIndex: 0
    property int activeTab: 0
    property string wallSearchTerm: ""
    property var wallpaperList: []
    property var filteredWallpapers: {
        if (wallSearchTerm === "") return wallpaperList
        var result = []
        for (var i = 0; i < wallpaperList.length; i++) {
            if (wallpaperList[i].name.toLowerCase().includes(wallSearchTerm)) {
                result.push(wallpaperList[i])
            }
        }
        return result
    }
    property int wallSelectedIndex: 0
    property string currentWallpaper: ""
    property bool wallsLoaded: false
    property bool thumbsReady: false
    property bool walApplying: false
    property var wallpaperHashes: ({})

    property bool wifiEnabled: true
    property string wifiCurrentSSID: ""
    property int wifiSignal: 0
    property var wifiNetworks: []
    property bool wifiScanning: false
    property string wifiPasswordSSID: ""
    property bool wifiConnecting: false

    property bool btEnabled: true
    property var btPairedDevices: []
    property var btAvailableDevices: []
    property bool btScanning: false         
    property string btConnectingMAC: ""
    property string osdType: "volume"

    property color walBackground: "#1e1e2e"
    property color walForeground: "#cdd6f4"
    property color walColor1: "#f38ba8"
    property color walColor2: "#a6e3a1"
    property color walColor4: "#f9e2af"
    property color walColor5: "#89b4fa"
    property color walColor8: "#6c7086"
    property color walColor13: "#f5c2e7"

    property string mediaStatus: "Stopped"
    property string mediaTitle: ""
    property string mediaArtist: ""
    property real mediaPosition: 0
    property real mediaLength: 0

    function mediaPlayPause() { if (!mediaPlayPauseProc.running) mediaPlayPauseProc.running = true }
    function mediaNext() { if (!mediaNextProc.running) mediaNextProc.running = true }
    function mediaPrevious() { if (!mediaPrevProc.running) mediaPrevProc.running = true }

    function toggleLauncher() { launcherVisible = !launcherVisible }

    function toggleCalendar() { calendarVisible = !calendarVisible }

    function toggleClipboard() { clipboardVisible = !clipboardVisible }

    function toggleEmoji() { emojiVisible = !emojiVisible }

    function toggleMusic() { musicVisible = !musicVisible }

    function toggleWifi() {
        wifiVisible = !wifiVisible
        if (wifiVisible) { btVisible = false; refreshWifi() }
    }

    function toggleBluetooth() {
        btVisible = !btVisible
        if (btVisible) { wifiVisible = false; refreshBluetooth() }
    }

    function refreshBluetooth() {
        root.btAvailableDevices = []  // solo limpiar disponibles
        root.btScanning = false
        root.btConnectingMAC = ""
        // solo re-escanear paired si está vacío
        if (root.btPairedDevices.length === 0) {
            if (!btDevicesProc.running) btDevicesProc.running = true
        }
        if (!btStatusProc.running) btStatusProc.running = true
    }

    function connectBt(mac) {
        root.btConnectingMAC = mac
        btActionProc.command = ["bash", "-c", "(echo 'trust " + mac + "'; echo 'connect " + mac + "'; sleep 2; echo 'quit') | bluetoothctl 2>/dev/null"]
        btActionProc.running = true
    }

    function disconnectBt(mac) {
        btActionProc.command = ["bash", "-c", "echo -e 'disconnect " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
        btActionProc.running = true
    }

    function pairBt(mac) {
        root.btConnectingMAC = mac
        btActionProc.command = ["bash", "-c", "echo -e 'pair " + mac + "\\nquit' | bluetoothctl 2>/dev/null; sleep 2; echo -e 'trust " + mac + "\\nquit' | bluetoothctl 2>/dev/null; sleep 1; echo -e 'connect " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
        btActionProc.running = true
    }

    function forgetBt(mac) {
        btActionProc.command = ["bash", "-c", "echo -e 'remove " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
        btActionProc.running = true
    }

    function refreshWifi() {
        root.wifiNetworks = []
        root.wifiScanning = true
        if (!wifiStatusProc.running) wifiStatusProc.running = true
        if (!wifiCurrentProc.running) wifiCurrentProc.running = true
        if (!wifiScanProc.running) wifiScanProc.running = true
    }

    Component.onCompleted: {
        walColorsProc.running = true
        appListProc.running = true
        loadUsageProc.running = true
        currentWallProc.running = true
        thumbDirProc.running = true
    }

    function launchApp(app) {
        launchProc.command = ["bash", "-c", "systemd-run --user -E WAYLAND_DISPLAY -E DISPLAY -E DBUS_SESSION_BUS_ADDRESS " + app.exec]
        launchProc.running = true
        var usage = appUsage
        var updated = {}
        for (var key in usage) updated[key] = usage[key]
        updated[app.name] = (updated[app.name] || 0) + 1
        appUsage = updated
        saveUsageProc.command = ["bash", "-c", "echo '" + JSON.stringify(updated) + "' > '" + root.configPath + "/app_usage.json'"]
        saveUsageProc.running = true
        root.launcherVisible = false
    }

    function applyWallpaper(wallpaper) {
        root.currentWallpaper = wallpaper.path
        root.walApplying = true
        applyWallProc.command = ["bash", "-c",
            "ln -sf '" + wallpaper.path + "' '" + root.wallpaperPath + "/current' && " +
            "awww img '" + wallpaper.path + "' --transition-type none & " +
            "wal -i '" + wallpaper.path + "' -n -q && " +
            "sleep 0.3"
        ]
        applyWallProc.running = true
    }

    function loadWallpapers() {
        root.wallpaperList = []
        root.wallsLoaded = false
        root.thumbsReady = false
        if (!wallpaperScanProc.running) wallpaperScanProc.running = true
    }

    Process {
        id: thumbDirProc
        command: ["mkdir", "-p", root.cachePath + "/wallpaper-thumbs"]
        onExited: root.loadWallpapers()
    }

    Process {
        id: wallpaperScanProc
        command: ["bash", "-c",
            "THUMB_DIR='" + root.cachePath + "/wallpaper-thumbs' && " +
            "WALL_DIR='" + root.wallpaperPath + "' && " +
            "find \"$WALL_DIR\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' 2>/dev/null | sort | " +
            "while IFS= read -r f; do " +
            "  hash=$(printf '%s' \"$f\" | md5sum | cut -d' ' -f1); " +
            "  printf '%s|%s\\n' \"$f\" \"$hash\"; " +
            "  thumb=\"$THUMB_DIR/${hash}.jpg\"; " +
            "  if [ ! -f \"$thumb\" ] || [ \"$f\" -nt \"$thumb\" ]; then " +
            "    if command -v vipsthumbnail >/dev/null 2>&1; then " +
            "      case \"$f\" in " +
            "        *.gif) convert \"${f}[0]\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
            "        *) vipsthumbnail \"$f\" -s 180x120 -o \"$thumb\" 2>/dev/null || convert \"$f\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
            "      esac; " +
            "    else " +
            "      case \"$f\" in " +
            "        *.gif) convert \"${f}[0]\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
            "        *) convert \"$f\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
            "      esac; " +
            "    fi; " +
            "  fi; " +
            "done"
        ]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var sep = line.lastIndexOf("|")
                if (sep === -1) return
                var path = line.substring(0, sep)
                var hash = line.substring(sep + 1)
                var parts = path.split("/")
                var name = parts[parts.length - 1]
                var list = root.wallpaperList.slice()
                list.push({ name: name, path: path })
                root.wallpaperList = list
                var hashes = root.wallpaperHashes
                hashes[path] = hash
                root.wallpaperHashes = hashes
                root.wallpaperHashesChanged()
            }
        }
        onExited: {
            root.wallsLoaded = true
            root.thumbsReady = true
        }
    }

    Process {
        id: applyWallProc
        onExited: {
            if (!walColorsProc.running) walColorsProc.running = true
        }
    }

    Process {
        id: walColorsProc
        command: ["bash", "-c", "cat '" + root.cachePath + "/wal/colors.json' 2>/dev/null"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    var json = JSON.parse(data)
                    if (json.special) {
                        root.walBackground = json.special.background || root.walBackground
                        root.walForeground = json.special.foreground || root.walForeground
                    }
                    if (json.colors) {
                        root.walColor1 = json.colors.color1 || root.walColor1
                        root.walColor2 = json.colors.color2 || root.walColor2
                        root.walColor4 = json.colors.color4 || root.walColor4
                        root.walColor5 = json.colors.color5 || root.walColor5
                        root.walColor8 = json.colors.color8 || root.walColor8
                        root.walColor13 = json.colors.color13 || root.walColor13
                    }
                } catch(e) {}
            }
        }
        onExited: {
            if (root.walApplying) {
                if (!walStepSwaync.running) walStepSwaync.running = true
            }
        }
    }

    Process {
        id: walStepSwaync
        command: ["bash", "-c", "cp '" + root.cachePath + "/wal/colors-swaync.css' '" + root.configPath + "/../swaync/style.css' 2>/dev/null; pkill -SIGUSR1 swaync 2>/dev/null"]
        onExited: root.walApplying = false
    }

    Process {
        id: currentWallProc
        command: ["bash", "-c", "readlink -f '" + root.wallpaperPath + "/current' 2>/dev/null || echo ''"]
        stdout: SplitParser { onRead: data => root.currentWallpaper = data.trim() }
    }

    Process {
        id: loadUsageProc
        command: ["bash", "-c", "cat '" + root.configPath + "/app_usage.json' 2>/dev/null || echo '{}'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try { root.appUsage = JSON.parse(data.trim()) } catch(e) { root.appUsage = {} }
            }
        }
    }

    Process { id: saveUsageProc }
    Process { id: launchProc }

    Process {
        id: appListProc
        command: ["bash", "-c",
            "for f in /usr/share/applications/*.desktop '" + root.homePath + "/.local/share/applications'/*.desktop /var/lib/flatpak/exports/share/applications/*.desktop '" + root.homePath + "/.local/share/flatpak/exports/share/applications'/*.desktop; do " +
            "  [ -f \"$f\" ] || continue; " +
            "  grep -qi '^NoDisplay=true' \"$f\" && continue; " +
            "  grep -qi '^Hidden=true' \"$f\" && continue; " +
            "  name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
            "  exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2- | sed 's/ %[fFuUdDnNickvm]//g'); " +
            "  icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-); " +
            "  [ -z \"$name\" ] && continue; " +
            "  [ -z \"$exec\" ] && continue; " +
            "  printf '%s\\t%s\\t%s\\n' \"$name\" \"$exec\" \"$icon\"; " +
            "done | sort -f -t$'\\t' -k1,1 | awk -F'\\t' '!seen[$1]++'"
        ]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split("\t")
                if (parts.length < 2) return
                var current = root.appList.slice()
                current.push({ name: parts[0], exec: parts[1], icon: parts.length > 2 ? parts[2] : "" })
                root.appList = current
            }
        }
    }

    Process {
        id: wifiStatusProc
        command: ["bash", "-c", "nmcli radio wifi 2>/dev/null || echo 'disabled'"]
        stdout: SplitParser { onRead: data => root.wifiEnabled = data.trim() === "enabled" }
    }

    Process {
        id: wifiCurrentProc
        command: ["bash", "-c", "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(":")
                if (parts.length >= 3) {
                    root.wifiCurrentSSID = parts[1]
                    root.wifiSignal = parseInt(parts[2]) || 0
                } else {
                    root.wifiCurrentSSID = ""
                    root.wifiSignal = 0
                }
            }
        }
    }

    Process {
        id: wifiScanProc
        command: ["bash", "-c", "nmcli -t -f ssid,signal,security dev wifi list --rescan auto 2>/dev/null | head -20"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split(":")
                if (parts.length < 2) return
                var ssid = parts[0]
                if (ssid === "" || ssid === root.wifiCurrentSSID) return
                var signal = parseInt(parts[1]) || 0
                var security = parts.length >= 3 ? parts[2] : ""
                var current = root.wifiNetworks.slice()
                for (var i = 0; i < current.length; i++) {
                    if (current[i].ssid === ssid) return
                }
                current.push({ ssid: ssid, signal: signal, security: security })
                root.wifiNetworks = current
            }
        }
        onExited: root.wifiScanning = false
    }

    Process {
        id: wifiToggleProc
        command: ["bash", "-c", root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"]
        onExited: {
            if (!wifiStatusProc.running) wifiStatusProc.running = true
            if (!root.wifiEnabled) wifiScanDelayTimer.start()
        }
    }

    Timer {
        id: wifiScanDelayTimer
        interval: 2000
        repeat: false
        onTriggered: refreshWifi()
    }

    Process {
        id: wifiConnectProc
        property string ssid: ""
        property string password: ""
        command: {
            if (password !== "")
                return ["nmcli", "dev", "wifi", "connect", ssid, "password", password]
            else
                return ["nmcli", "dev", "wifi", "connect", ssid]
        }
        onExited: {
            root.wifiConnecting = false
            root.wifiPasswordSSID = ""
            if (!wifiCurrentProc.running) wifiCurrentProc.running = true
        }
    }

    Process {
        id: wifiDisconnectProc
        command: ["bash", "-c", "nmcli dev disconnect wlan0 2>/dev/null; nmcli dev disconnect wlp0s20f3 2>/dev/null; nmcli dev disconnect $(nmcli -t -f device,type dev | grep ':wifi$' | cut -d: -f1 | head -1) 2>/dev/null"]
        onExited: {
            root.wifiCurrentSSID = ""
            root.wifiSignal = 0
        }
    }

    Process {
        id: btStatusProc
        command: ["bash", "-c", "echo -e 'show\\nquit' | bluetoothctl 2>/dev/null | grep -q 'Powered: yes' && echo 'true' || echo 'false'"]
        stdout: SplitParser {
            onRead: data => root.btEnabled = data.trim() === "true"
        }
        onExited: {
            if (root.btEnabled && !btDevicesProc.running) btDevicesProc.running = true
        }
    }

    Process {
        id: btToggleOnProc
        command: ["bash", "-c", "echo -e 'power on\\nquit' | bluetoothctl 2>/dev/null"]
        onExited: btToggleDelayTimer.start()
    }

    Timer {
        id: btToggleDelayTimer
        interval: 1000
        repeat: false
        onTriggered: refreshBluetooth()
    }

    Process {
        id: btToggleOffProc
        command: ["bash", "-c", "echo -e 'power off\\nquit' | bluetoothctl 2>/dev/null"]
        onExited: {
            root.btEnabled = false
            root.btPairedDevices = []
            root.btAvailableDevices = []
        }
    }

    Process {
        id: btDevicesProc
        command: ["bash", "-c", "connected=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}'); bluetoothctl devices Paired 2>/dev/null | awk '{print $2\" \"substr($0, index($0,$3))}' | while read -r mac name; do if printf '%s\\n' \"$connected\" | grep -qx \"$mac\"; then c=yes; else c=no; fi; echo \"${mac}|${name}|${c}\"; done"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split("|")
                if (parts.length < 3) return
                var mac = parts[0]
                var name = parts[1]
                var connected = parts[2] === "yes"
                var current = root.btPairedDevices.slice()
                for (var i = 0; i < current.length; i++) {
                    if (current[i].mac === mac) return
                }
                current.push({ mac: mac, name: name, connected: connected })
                root.btPairedDevices = current
            }
        }
    }

    Process {
        id: btScanProc
        command: ["bash", "-c", "echo -e 'scan on\\nquit' | bluetoothctl 2>/dev/null; sleep 5; echo -e 'scan off\\nquit' | bluetoothctl 2>/dev/null; sleep 1; paired=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}'); bluetoothctl devices 2>/dev/null | grep '^Device' | while read -r line; do mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); if ! printf '%s\\n' \"$paired\" | grep -qx \"$mac\" && [ -n \"$name\" ] && [ \"$name\" != \"$mac\" ]; then echo \"${mac}|${name}\"; fi; done"]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.length === 0) return
                var parts = line.split("|")
                if (parts.length < 2) return
                var mac = parts[0]
                var name = parts[1]
                if (mac.length !== 17) return
                var current = root.btAvailableDevices.slice()
                for (var j = 0; j < current.length; j++) {
                    if (current[j].mac === mac) return
                }
                current.push({ mac: mac, name: name })
                root.btAvailableDevices = current
            }
        }
        onExited: root.btScanning = false
    }

    Process {
        id: btActionProc
        onExited: {
            root.btConnectingMAC = ""
            btActionDelayTimer.start()
        }
    }

    Timer {
        id: btActionDelayTimer
        interval: 1500
        repeat: false
        onTriggered: refreshBluetooth()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!mediaProc.running) mediaProc.running = true }
    }

    Process {
        id: mediaProc
        command: ["bash", "-c",
            "status=$(playerctl --player=%any status 2>/dev/null); " +
            "title=$(playerctl --player=%any metadata title 2>/dev/null); " +
            "artist=$(playerctl --player=%any metadata artist 2>/dev/null); " +
            "pos=$(playerctl --player=%any position 2>/dev/null | cut -d. -f1); " +
            "len=$(playerctl --player=%any metadata mpris:length 2>/dev/null); " +
            "len=$((len / 1000000)); " +
            "[ -z \"$status\" ] && status=Stopped; " +
            "printf '%s\\t%s\\t%s\\t%s\\t%s\\n' \"$status\" \"$title\" \"$artist\" \"${pos:-0}\" \"${len:-0}\""
        ]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("\t")
                if (parts.length < 5) return
                root.mediaStatus = parts[0]
                root.mediaTitle = parts[1]
                root.mediaArtist = parts[2]
                root.mediaPosition = parseInt(parts[3]) || 0
                root.mediaLength = parseInt(parts[4]) || 0
            }
        }
    }

    Timer {
        interval: 1000
        running: root.mediaStatus === "Playing"
        repeat: true
        onTriggered: {
            if (root.mediaPosition < root.mediaLength) root.mediaPosition += 1
        }
    }

    Process {
        id: mediaPlayPauseProc
        command: ["playerctl", "play-pause"]
        onExited: { if (!mediaProc.running) mediaProc.running = true }
    }

    Process {
        id: mediaNextProc
        command: ["playerctl", "next"]
        onExited: { if (!mediaProc.running) mediaProc.running = true }
    }

    Process {
        id: mediaPrevProc
        command: ["playerctl", "previous"]
        onExited: { if (!mediaProc.running) mediaProc.running = true }
    }

    Bar {}
    MusicPanel {}
    WifiPanel {}
    BluetoothPanel {}
    LauncherPanel {}
    CalendarPanel {}
    ClipboardPanel {}
    EmojiPanel {}
    OsdPanel {}

    IpcHandler {
        target: "launcher"
        function toggle() {
            root.activeTab = 0
            root.toggleLauncher()
        }
    }
    IpcHandler {
        target: "music"
        function toggle() { root.toggleMusic() }
    }
    IpcHandler {
        target: "wallpaper"
        function toggle() {
            if (!root.launcherVisible) {
                root.activeTab = 1
                root.toggleLauncher()
            } else if (root.activeTab === 1) {
                root.toggleLauncher()
            } else {
                root.activeTab = 1
                if (!root.wallsLoaded) root.loadWallpapers()
            }
        }
    }
    IpcHandler {
        target: "randomwallpaper"
        function apply(path: string) {
            root.applyWallpaper({ path: path, name: path.split("/").pop() })
        }
    }
    IpcHandler {
        target: "wifi"
        function toggle() { root.toggleWifi() }
    }
    IpcHandler { 
        target: "bluetooth"
        function toggle() { root.toggleBluetooth() }
    }
    IpcHandler {
        target: "clipboard"
        function toggle() { root.toggleClipboard() }
    }
    IpcHandler {
        target: "emoji"
        function toggle() { root.toggleEmoji() }
    }
}
