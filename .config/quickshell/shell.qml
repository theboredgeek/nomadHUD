//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./modules"
import QtQuick.Controls.Fusion

ShellRoot {
    id: mainShell
    
    // --- 1. THE MASTER THEME CONTROL ---
    // Modules will access these via root.amber, root.glass, etc.
    readonly property var config: mainShell
    readonly property color amber: "#e1a82c"
    readonly property color warningRed: "#ff3333"
    readonly property color glass: "#e6000000"
    readonly property color circuitBlue: "#004466"
    readonly property string fontFamily: "Monospace"

    // --- 2. GLOBAL DATA STATE ---
    property var gpuData: [] 
    property string cpuLoad: "00"
    property string memLoad: "00"
    property string memUsedGB: "0.0"
    property string memTotalGB: "0.0"
    property string netDown: "0.0"
    property string netUp: "0.0"
    property string activeIface: "..."
    
    property real u_time: 0.0
    Timer { interval: 16; running: true; repeat: true; onTriggered: mainShell.u_time += 0.01 }

    // --- 3. MASTER LOGIC HELPERS ---
    function getAlertColor(load) {
        return parseInt(load) >= 90 ? warningRed : amber
    }

    // --- 4. DATA COLLECTION PROCESSES ---
    Process {
        id: cpuProc
        command: ["/bin/sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'"] 
        stdout: SplitParser { onRead: data => { mainShell.cpuLoad = Math.round(parseFloat(data)).toString().padStart(2, '0'); cpuProc.running = false } }
    }

    Process {
        id: memProc
        command: ["/bin/sh", "-c", "awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {u=t-a; printf \"%.0f|%.1f|%.1f\", (u/t*100), u/1024/1024, t/1024/1024}' /proc/meminfo"]
        stdout: SplitParser {
            onRead: data => { 
                let parts = data.trim().split('|')
                if (parts.length === 3) { 
                    mainShell.memLoad = parts[0]; 
                    mainShell.memUsedGB = parts[1]; 
                    mainShell.memTotalGB = parts[2] 
                }
                memProc.running = false
            }
        }
    }

    Process {
        id: netProc
        command: ["/bin/sh", "-c", "IFACE=$(ip route | grep default | awk '{print $5}' | head -n1); [ -z \"$IFACE\" ] && IFACE=$(awk 'NR>2 {print $1; exit}' /proc/net/dev | tr -d ':'); R1=$(cat /proc/net/dev | grep \"$IFACE\" | awk '{print $2\"|\"$10}'); sleep 1; R2=$(cat /proc/net/dev | grep \"$IFACE\" | awk '{print $2\"|\"$10}'); echo \"$R1|$R2|$IFACE\" | awk -F'|' '{printf \"%.1f|%.1f|%s\", ($3-$1)/1024, ($4-$2)/1024, $5}'"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|')
                if (parts.length === 3) { mainShell.netDown = parts[0]; mainShell.netUp = parts[1]; mainShell.activeIface = parts[2] }
                netProc.running = false
            }
        }
    }

    Process {
        id: gpuProc
        command: ["/bin/sh", "-c", "for dev in /sys/class/drm/card[0-9]; do [ -e \"$dev/device/vendor\" ] || continue; VEND=$(cat \"$dev/device/vendor\"); NAME=$(echo \"$VEND\" | sed 's/0x1002/AMD/;s/0x10de/NVIDIA/;s/0x8086/INTEL/'); L=0; VU=\"0.0\"; VT=\"0.0\"; if [ \"$NAME\" = \"NVIDIA\" ] && command -v nvidia-smi >/dev/null 2>&1; then DATA=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits | sed 's/, /,/g'); L=$(echo \"$DATA\" | cut -d',' -f1); U_MB=$(echo \"$DATA\" | cut -d',' -f2); T_MB=$(echo \"$DATA\" | cut -d',' -f3); VU=$(awk -v u=\"$U_MB\" 'BEGIN {printf \"%.2f\", u/1024}'); VT=$(awk -v t=\"$T_MB\" 'BEGIN {printf \"%.1f\", t/1024}'); elif [ -f \"$dev/device/gpu_busy_percent\" ]; then L=$(cat \"$dev/device/gpu_busy_percent\" 2>/dev/null || echo 0); U_BYTES=$(cat \"$dev/device/mem_info_vram_used\" 2>/dev/null || echo 0); T_BYTES=$(cat \"$dev/device/mem_info_vram_total\" 2>/dev/null || echo 1); VU=$(awk -v u=\"$U_BYTES\" 'BEGIN {printf \"%.2f\", u/1073741824}'); VT=$(awk -v t=\"$T_BYTES\" 'BEGIN {printf \"%.1f\", t/1073741824}'); fi; printf \"%s|%s|%s|%s \" \"$NAME\" \"$L\" \"$VU\" \"$VT\"; done"]
        stdout: SplitParser {
            onRead: data => {
                let cleanData = data.trim();
                if (cleanData.length > 0) {
                    mainShell.gpuData = cleanData.split(' ').filter(item => item.includes('|'));
                }
                gpuProc.running = false;
            }
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: { 
            if (!cpuProc.running) cpuProc.running = true; 
            if (!memProc.running) memProc.running = true;
            if (!netProc.running) netProc.running = true;
            if (!gpuProc.running) gpuProc.running = true;
        }
    }

    // --- 5. DISPLAY LAYER ---
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Item {
                id: screenScope
                required property var modelData
                readonly property var targetScreen: modelData

                PanelWindow {
                    id: backgroundWindow
                    screen: targetScreen
                    WlrLayershell.layer: WlrLayershell.Background
                    implicitWidth: screen.width
                    implicitHeight: screen.height

                    Rectangle {
                        anchors.fill: parent
                        color: "#080808"
                        
                        Rectangle {
                            anchors.fill: parent
                            opacity: 0.15 + (Math.sin(mainShell.u_time) * 0.05)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: mainShell.circuitBlue }
                                GradientStop { position: 1.0; color: "#002206" }
                            }
                        }
                        
                        Repeater {
                            model: 8
                            Rectangle {
                                width: parent.width; height: 1; color: mainShell.amber; opacity: 0.15 
                                y: (parent.height * (index / 8) + (mainShell.u_time * 60)) % parent.height
                            }
                        }
                    }
                }

                // --- UI MODULES (ORDERED BOTTOM-TO-TOP) ---
                // Passing 'root' ensures modules can access theme colors and data
                CpuModule      { targetScreen: screenScope.targetScreen; root: mainShell.config }
                NetworkModule  { targetScreen: screenScope.targetScreen; root: mainShell.config }
                MemoryModule   { id: localMem; targetScreen: screenScope.targetScreen; root: mainShell.config }
                GpuModule      { id: localGpu; targetScreen: screenScope.targetScreen; root: mainShell.config; anchorTarget: localMem }
                ClockModule    { targetScreen: screenScope.targetScreen; root: mainShell.config }
                MonitorManager { targetScreen: screenScope.targetScreen; root: mainShell.config }
                SystemTray     { targetScreen: screenScope.targetScreen; root: mainShell.config }
                StorageModule  { id: localStorage; targetScreen: screenScope.targetScreen; root: mainShell.config; anchorTarget: localGpu }
            }
        }
    }
}