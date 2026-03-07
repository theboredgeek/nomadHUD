import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root
    
    readonly property color amber: "#E1B12C"
    readonly property color glass: "#E6000000"
    readonly property color circuitBlue: "#004466"
    
    // --- SYSTEM METRICS DATA ---
    property string cpuLoad: "00"
    property string memLoad: "00"
    property string memUsedGB: "0.0"
    property string memTotalGB: "0.0"
    
    property real u_time: 0.0
    Timer { interval: 16; running: true; repeat: true; onTriggered: root.u_time += 0.01 }

    // --- 1. CPU MONITOR ---
    Process {
        id: cpuProc
        command: ["/bin/sh", "-c", "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}'"]
        stdout: SplitParser {
            onRead: data => { 
                let val = parseFloat(data.trim()).toFixed(0);
                root.cpuLoad = val.padStart(2, '0');
                cpuProc.running = false;
            }
        }
    }

    // --- 2. MEMORY MONITOR (Returns: % | UsedGB | TotalGB) ---
    Process {
        id: memProc
        command: ["/bin/sh", "-c", "awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {u=t-a; printf \"%.0f|%.1f|%.1f\", (u/t*100), u/1024/1024, t/1024/1024}' /proc/meminfo"]
        stdout: SplitParser {
            onRead: data => { 
                let parts = data.trim().split('|');
                if (parts.length === 3) {
                    root.memLoad = parts[0].padStart(2, '0');
                    root.memUsedGB = parts[1];
                    root.memTotalGB = parts[2];
                }
                memProc.running = false;
            }
        }
    }

    Timer {
        interval: 2000; running: true; repeat: true;
        onTriggered: {
            if (!cpuProc.running) cpuProc.running = true;
            if (!memProc.running) memProc.running = true;
        }
    }

    // --- 0. BACKGROUND LAYER ---
    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Background
        anchors { top: true; bottom: true; left: true; right: true }
        Rectangle {
            anchors.fill: parent; color: "#080808"
            Rectangle {
                anchors.fill: parent; opacity: 0.15 + (Math.sin(root.u_time) * 0.05)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.circuitBlue }
                    GradientStop { position: 0.5; color: "transparent" }
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

    // --- 1. CENTRAL UNDERLAY ---
    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Bottom
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        Rectangle {
            width: Math.floor(screen.width * 0.6); height: Math.floor(screen.height * 0.5)
            anchors.centerIn: parent; color: root.glass; border.color: root.amber; border.width: 1; opacity: 0.2
            ShaderEffect {
                anchors.fill: parent; anchors.margins: 2
                property real u_time: root.u_time; property real u_width: width; property real u_height: height
                fragmentShader: "shaders/hexgrid.qsb"
            }
        }
    }

    // --- 2. TOP-LEFT DIAGNOSTIC (CPU + Animated Bar) ---
    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Bottom
        anchors { top: true; left: true }
        width: 450; height: 180; color: "transparent"
        
        Item {
            anchors.fill: parent; anchors.margins: 40
            
            // Corner L-Bracket
            Rectangle { width: 2; height: 80; color: root.amber; anchors.left: parent.left; anchors.top: parent.top }
            Rectangle { width: 80; height: 2; color: root.amber; anchors.left: parent.left; anchors.top: parent.top }

            Column {
                x: 15; y: 15
                spacing: 6
                
                Text {
                    text: "NOMAD_OS // CPU_LOAD: " + root.cpuLoad + "%"
                    font.family: "Monospace"; font.pixelSize: 14; color: root.amber
                }

                // CPU Progress Bar
                Rectangle {
                    width: 200; height: 4; color: "#22E1B12C"
                    Rectangle {
                        height: parent.height
                        width: parent.width * (parseInt(root.cpuLoad) / 100)
                        color: root.amber
                        Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
                    }
                }
                
                Text {
                    text: "STATUS: STABLE"
                    font.family: "Monospace"; font.pixelSize: 10; color: root.amber; opacity: 0.6
                }
            }
        }
    }

    // --- 3. BOTTOM-RIGHT STATUS (Memory + Visual GB Metrics) ---
    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Bottom
        anchors { bottom: true; right: true }
        width: 500; height: 140; color: "transparent"
        
        Rectangle {
            width: 380; height: 80; anchors.centerIn: parent
            color: root.glass; border.color: root.amber; border.width: 1
            
            Column {
                anchors.centerIn: parent
                spacing: 10
                
                // Detailed GB readout
                Text {
                    text: "MEM_POOL // " + root.memUsedGB + "GB / " + root.memTotalGB + "GB"
                    font.family: "Monospace"; font.bold: true; font.pixelSize: 12; color: root.amber
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // Visual Progress Bar
                Rectangle {
                    width: 300; height: 6; color: "#22E1B12C"
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Rectangle {
                        height: parent.height
                        width: parent.width * (parseInt(root.memLoad) / 100)
                        color: root.amber
                        Behavior on width { NumberAnimation { duration: 1500; easing.type: Easing.OutElastic } }
                    }
                }

                Text {
                    text: "USAGE_INDEX: " + root.memLoad + "%"
                    font.family: "Monospace"; font.pixelSize: 10; color: root.amber; opacity: 0.7
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}