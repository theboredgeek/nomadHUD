import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root
    
    // --- SHARED STYLING ---
    readonly property color amber: "#E1B12C"
    readonly property color warningRed: "#FF3333"
    readonly property color glass: "#E6000000"
    readonly property color circuitBlue: "#004466"
    
    // --- SHARED DATA ---
    property string cpuLoad: "00"
    property string memLoad: "00"
    property string memUsedGB: "0.0"
    property string memTotalGB: "0.0"
    property string netDown: "0.0"
    property string netUp: "0.0"
    property string activeIface: "..."
    property real u_time: 0.0

    Timer { interval: 16; running: true; repeat: true; onTriggered: root.u_time += 0.01 }
    function getAlertColor(load) { return parseInt(load) >= 90 ? warningRed : amber }

    // --- SYSTEM PROCESSES (Data Fetching) ---
    Process {
        id: cpuProc
        command: ["/bin/sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}'"]
        stdout: SplitParser { onRead: data => { root.cpuLoad = parseFloat(data).toFixed(0).padStart(2, '0'); cpuProc.running = false } }
    }

    Process {
        id: memProc
        command: ["/bin/sh", "-c", "awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {u=t-a; printf \"%.0f|%.1f|%.1f\", (u/t*100), u/1024/1024, t/1024/1024}' /proc/meminfo"]
        stdout: SplitParser {
            onRead: data => { 
                let parts = data.trim().split('|')
                if (parts.length === 3) { root.memLoad = parts[0]; root.memUsedGB = parts[1]; root.memTotalGB = parts[2] }
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
                if (parts.length === 3) { root.netDown = parts[0]; root.netUp = parts[1]; root.activeIface = parts[2] }
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
        }
    }

    // --- SCREEN DELEGATION ---
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Item {
                id: screenScope
                required property var modelData
                readonly property var targetScreen: modelData

                // --- 0. BACKGROUND LAYER (Hardcoded in ShellRoot for stability) ---
                PanelWindow {
                    screen: targetScreen
                    WlrLayershell.layer: WlrLayershell.Background
                    anchors { fill: parent }
                    Rectangle {
                        anchors.fill: parent; color: "#080808"
                        Rectangle {
                            anchors.fill: parent
                            opacity: 0.15 + (Math.sin(root.u_time) * 0.05)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: root.circuitBlue }
                                GradientStop { position: 1.0; color: root.circuitBlue }
                            }
                        }
                        Repeater {
                            model: 8
                            Rectangle {
                                width: parent.width; height: 2; color: root.amber; opacity: 0.25 
                                y: (parent.height * (index / 8) + (root.u_time * 80)) % parent.height
                            }
                        }
                    }
                }

                // --- MODULE LOADING ---
                CpuModule { targetScreen: screenScope.targetScreen; root: root }
                NetworkModule { targetScreen: screenScope.targetScreen; root: root }
                MemoryModule { targetScreen: screenScope.targetScreen; root: root }
            }
        }
    }
}