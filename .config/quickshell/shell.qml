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

    // Battery & Power Properties
    property string batPercent: "0"
    property bool isPlugged: false
    property string powerDrain: "0.0"
    property string activeProfile: "..."
    property string batTime: "0h 0m"
    property real smoothedWattage: 0.0
    property real smoothedEnergy: 0.0 
    property int timeUpdateCounter: 0 

    property real u_time: 0.0
    Timer { interval: 16; running: true; repeat: true; onTriggered: mainShell.u_time += 0.01 }

    // --- DATA COLLECTION ---
    
    // Power & Battery Process
    Process {
        id: powerDataProc
        command: ["/bin/sh", "-c", "
            CAP=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 0);
            STAT=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 0);
            POW=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null || echo 0);
            ENG=$(cat /sys/class/power_supply/BAT0/energy_now 2>/dev/null || cat /sys/class/power_supply/BAT0/charge_now 2>/dev/null || echo 0);
            PROF=$(powerprofilesctl get 2>/dev/null || echo 'unknown');
            echo \"$CAP|$STAT|$POW|$PROF|$ENG\"
        "]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|');
                if (parts.length === 5) {
                    mainShell.batPercent = parts[0];
                    mainShell.isPlugged = (parts[1] === "1");
                    mainShell.activeProfile = parts[3];

                    let rawMicrowatts = parseFloat(parts[2]);
                    let rawEnergy = parseFloat(parts[4]);

                    let currentWattage = rawMicrowatts / 1000000;
                    
                    if (mainShell.smoothedWattage === 0) {
                        mainShell.smoothedWattage = currentWattage;
                        mainShell.smoothedEnergy = rawEnergy;
                    } else {
                        mainShell.smoothedWattage = (currentWattage * 0.05) + (mainShell.smoothedWattage * 0.95);
                        mainShell.smoothedEnergy = (rawEnergy * 0.05) + (mainShell.smoothedEnergy * 0.95);
                    }
                    
                    mainShell.powerDrain = mainShell.smoothedWattage.toFixed(1);

                    mainShell.timeUpdateCounter++;
                    
                    if (mainShell.isPlugged) {
                        mainShell.batTime = "AC_SYNC";
                        mainShell.timeUpdateCounter = 0;
                    } else if (mainShell.timeUpdateCounter >= 15 || mainShell.batTime === "0h 0m") {
                        if (mainShell.smoothedWattage > 0.5) {
                            let hoursRemaining = (mainShell.smoothedEnergy / 1000000) / mainShell.smoothedWattage;
                            let h = Math.floor(hoursRemaining);
                            let m = Math.round((hoursRemaining - h) * 60);
                            if (h > 99) h = 99; 
                            mainShell.batTime = h + "h " + m + "m";
                        } else {
                            mainShell.batTime = "CALC...";
                        }
                        mainShell.timeUpdateCounter = 0; 
                    }
                }
                powerDataProc.running = false;
            }
        }
    }

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
        command: ["/bin/sh", "-c", "
            IFACE=$(ip route | grep default | awk '{print $5}' | head -n1);
            if [ -z \"$IFACE\" ]; then
                echo \"0.0|0.0|OFFLINE\"
            else
                R1=$(cat /proc/net/dev | grep \"$IFACE\" | awk '{print $2\"|\"$10}');
                sleep 1;
                R2=$(cat /proc/net/dev | grep \"$IFACE\" | awk '{print $2\"|\"$10}');
                echo \"$R1|$R2|$IFACE\" | awk -F'|' '{printf \"%.1f|%.1f|%s\", ($3-$1)/1024, ($4-$2)/1024, $5}'
            fi
        "]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|')
                if (parts.length === 3) { 
                    mainShell.netDown = parts[0]; 
                    mainShell.netUp = parts[1]; 
                    mainShell.activeIface = parts[2];
                }
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
            if (!powerDataProc.running) powerDataProc.running = true;
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Item {
                id: screenScope
                required property var modelData
                readonly property var targetScreen: modelData

                // --- UI MODULES ---
                CpuModule      { targetScreen: screenScope.targetScreen; root: mainShell }
                NetworkModule  { targetScreen: screenScope.targetScreen; root: mainShell }
                MemoryModule   { id: localMem; targetScreen: screenScope.targetScreen; root: mainShell }
                GpuModule      { id: localGpu; targetScreen: screenScope.targetScreen; root: mainShell; anchorTarget: localMem }
                ClockModule    { targetScreen: screenScope.targetScreen; root: mainShell }
                MonitorManager { targetScreen: screenScope.targetScreen; root: mainShell }
                SystemTray     { targetScreen: screenScope.targetScreen; root: mainShell }
                StorageModule  { id: localStorage; targetScreen: screenScope.targetScreen; root: mainShell; anchorTarget: localGpu }
                PowerModule    { targetScreen: screenScope.targetScreen; root: mainShell }
            }
        }
    }
}