import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
// This tells Quickshell to look inside your modules folder:
import "./modules" 

ShellRoot {
    id: mainShell
    
    // Explicitly export the shell's data to the modules
    readonly property var config: mainShell

    // --- STYLING & GLOBAL DATA ---
    readonly property color amber: "#E1B12C"
    readonly property color warningRed: "#FF3333"
    readonly property color glass: "#E6000000"
    readonly property color circuitBlue: "#004466"
    
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

    function getAlertColor(load) {
        return parseInt(load) >= 90 ? warningRed : amber
    }

    // --- DATA COLLECTION PROCESSES ---
    Process {
        id: cpuProc
        command: ["/bin/sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}'"]
        stdout: SplitParser { onRead: data => { mainShell.cpuLoad = parseFloat(data).toFixed(0).padStart(2, '0'); cpuProc.running = false } }
    }

    Process {
        id: memProc
        command: ["/bin/sh", "-c", "awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {u=t-a; printf \"%.0f|%.1f|%.1f\", (u/t*100), u/1024/1024, t/1024/1024}' /proc/meminfo"]
        stdout: SplitParser {
            onRead: data => { 
                let parts = data.trim().split('|')
                if (parts.length === 3) { mainShell.memLoad = parts[0]; mainShell.memUsedGB = parts[1]; mainShell.memTotalGB = parts[2] }
                memProc.running = false
            }
        }
    }

    Process {
        id: netProc
        command: ["/bin/sh", "-c", "IFACE=$(awk 'NR>2 {if ($2>max && $1!=\"lo:\") {max=$2; iface=$1}} END {sub(\":\",\"\",iface); print iface}' /proc/net/dev); R1=$(cat /proc/net/dev | grep \"$IFACE\" | awk '{print $2\"|\"$10}'); sleep 1; R2=$(cat /proc/net/dev | grep \"$IFACE\" | awk '{print $2\"|\"$10}'); echo \"$R1|$R2|$IFACE\" | awk -F'|' '{printf \"%.1f|%.1f|%s\", ($3-$1)/1024, ($4-$2)/1024, $5}'"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split('|')
                if (parts.length === 3) { mainShell.netDown = parts[0]; mainShell.netUp = parts[1]; mainShell.activeIface = parts[2] }
                netProc.running = false
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

    Process {
        id: gpuProc
        // This version looks for the device vendor and name, then checks for load.
        // It uses a fallback to 0 if the busy_percent file doesn't exist.
        command: ["/bin/sh", "-c", "for dev in /sys/class/drm/card[0-9]; do \
            [ -e \"$dev/device/vendor\" ] || continue; \
            VEND=$(cat \"$dev/device/vendor\"); \
            NAME=$(echo \"$VEND\" | sed 's/0x1002/AMD/;s/0x10de/NVIDIA/;s/0x8086/INTEL/'); \
            BUSY=\"$dev/device/gpu_busy_percent\"; \
            LOAD=$( [ -f \"$BUSY\" ] && cat \"$BUSY\" || echo \"0\" ); \
            printf \"$NAME|$LOAD \"; \
        done"]
        stdout: SplitParser {
            onRead: data => {
                let items = data.trim().split(' ').filter(i => i.length > 0);
                mainShell.gpuData = items;
                gpuProc.running = false;
            }
        }
    }

    // --- DISPLAY LAYER ---
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Item {
                id: screenScope
                required property var modelData
                readonly property var targetScreen: modelData

                PanelWindow {
                    screen: targetScreen
                    WlrLayershell.layer: WlrLayershell.Background
                    
                    anchors {
                        top: true
                        bottom: true
                        left: true
                        right: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#080808"
                        Rectangle {
                            anchors.fill: parent
                            opacity: 0.15 + (Math.sin(mainShell.u_time) * 0.05)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: mainShell.circuitBlue }
                                GradientStop { position: 1.0; color: mainShell.circuitBlue }
                            }
                        }
                        Repeater {
                            model: 8
                            Rectangle {
                                width: parent.width; height: 2; color: mainShell.amber; opacity: 0.25 
                                y: (parent.height * (index / 8) + (mainShell.u_time * 80)) % parent.height
                            }
                        }
                    }
                }

                // Call the modules with the explicit config reference
                CpuModule     { targetScreen: screenScope.targetScreen; root: mainShell.config }
                NetworkModule { targetScreen: screenScope.targetScreen; root: mainShell.config }
                MemoryModule  { targetScreen: screenScope.targetScreen; root: mainShell.config }
                GpuModule     { targetScreen: screenScope.targetScreen; root: mainShell.config }
                ClockModule   { targetScreen: screenScope.targetScreen; root: mainShell.config }
                MonitorManager { targetScreen: screenScope.targetScreen; root: mainShell.config }
            }
        }
    }
}