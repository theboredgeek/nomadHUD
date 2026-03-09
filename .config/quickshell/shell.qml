//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./modules"
import QtQuick.Controls.Fusion

ShellRoot {
    id: mainShell
    
    readonly property var config: mainShell 
    property var gpuData: [] 
    property string cpuLoad: "00"
    property var cpuCores: [] 
    property string memLoad: "00"
    property string memUsedGB: "0.0"
    property string memTotalGB: "0.0"
    property string netDown: "0.0"
    property string netUp: "0.0"
    property string activeIface: "..."
    
    property real u_time: 0.0
    // Animation Timer: Set running to false to disable background movement and pulsing
    Timer { interval: 16; running: false; repeat: true; onTriggered: mainShell.u_time += 0.01 }

    // --- DATA COLLECTION ---
    Process {
        id: cpuProc
        command: ["/bin/sh", "-c", "grep '^cpu' /proc/stat > /tmp/stat1; sleep 0.1; grep '^cpu' /proc/stat > /tmp/stat2; awk 'NR==FNR {u[NR]=$2+$3+$4; t[NR]=$2+$3+$4+$5+$6+$7+$8; next} {u2=$2+$3+$4; t2=$2+$3+$4+$5+$6+$7+$8; diff_u=u2-u[FNR]; diff_t=t2-t[FNR]; printf \"%d|\", (diff_t==0 ? 0 : (diff_u/diff_t)*100)}' /tmp/stat1 /tmp/stat2"] 
        
        stdout: SplitParser {
            onRead: data => {
                let parts = data.split('|').filter(x => x.length > 0);
                if (parts.length > 0) {
                    mainShell.cpuLoad = parts[0].padStart(2, '0'); 
                    mainShell.cpuCores = parts.slice(1);           
                }
                cpuProc.running = false
            }
        }
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
                        color: Theme.bgDark
                        
                        // Static Gradient Background
                        Rectangle {
                            anchors.fill: parent
                            opacity: 0.15 // Removed pulsing math
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Theme.circuitBlue }
                                GradientStop { position: 1.0; color: "#001111" } 
                            }
                        }
                        
                        // Static Grid/Scanlines (Removed Y-offset animation)
                        Repeater {
                            model: 12
                            Rectangle {
                                width: parent.width; height: Theme.borderWidth; 
                                color: Theme.amber; 
                                opacity: 0.1
                                y: parent.height * (index / 12) 
                            }
                        }
                    }
                }

                // --- UI MODULES ---
                CpuModule      { targetScreen: screenScope.targetScreen; root: mainShell }
                NetworkModule  { targetScreen: screenScope.targetScreen; root: mainShell }
                MemoryModule   { id: localMem; targetScreen: screenScope.targetScreen; root: mainShell }
                GpuModule      { id: localGpu; targetScreen: screenScope.targetScreen; root: mainShell; anchorTarget: localMem }
                ClockModule    { targetScreen: screenScope.targetScreen; root: mainShell }
                MonitorManager { targetScreen: screenScope.targetScreen; root: mainShell }
                SystemTray     { targetScreen: screenScope.targetScreen; root: mainShell }
                StorageModule  { id: localStorage; targetScreen: screenScope.targetScreen; root: mainShell; anchorTarget: localGpu }
            }
        }
    }
}