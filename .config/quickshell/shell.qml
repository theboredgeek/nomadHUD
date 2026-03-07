import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root
    
    readonly property color amber: "#E1B12C"
    readonly property color glass: "#E6000000"
    readonly property color circuitBlue: "#004466"
    
    property string cpuLoad: "00"
    property string memLoad: "00"
    property string memUsedGB: "0.0"
    property string memTotalGB: "0.0"
    
    // --- NETWORK DATA ---
    property string netDown: "0.0"
    property string netUp: "0.0"
    property string activeIface: "..."
    
    property real u_time: 0.0
    Timer { interval: 16; running: true; repeat: true; onTriggered: root.u_time += 0.01 }

    // --- 1. CPU MONITOR ---
    Process {
        id: cpuProc
        command: ["/bin/sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}'"]
        stdout: SplitParser { onRead: data => { root.cpuLoad = parseFloat(data).toFixed(0).padStart(2, '0'); cpuProc.running = false } }
    }

    // --- 2. MEMORY MONITOR ---
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

    // --- 3. NETWORK MONITOR (RX | TX | IFACE) ---
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

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Item {
                required property var modelData
                readonly property var targetScreen: modelData

                // --- 0. BACKGROUND LAYER ---
                PanelWindow {
                    screen: targetScreen
                    WlrLayershell.layer: WlrLayershell.Background
                    anchors { top: true; bottom: true; left: true; right: true }
                    Rectangle {
                        anchors.fill: parent; color: "#080808"
                        Rectangle {
                            anchors.fill: parent; opacity: 0.15 + (Math.sin(root.u_time) * 0.05)
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

                // --- 1. TOP-LEFT CPU ---
                PanelWindow {
                    screen: targetScreen
                    WlrLayershell.layer: WlrLayershell.Bottom
                    anchors { top: true; left: true }
                    implicitWidth: 450; implicitHeight: 180; color: "transparent"
                    Item {
                        anchors.fill: parent; anchors.margins: 40
                        Rectangle { width: 2; height: 80; color: root.amber; anchors.left: parent.left; anchors.top: parent.top }
                        Rectangle { width: 80; height: 2; color: root.amber; anchors.left: parent.left; anchors.top: parent.top }
                        Column {
                            x: 15; y: 15; spacing: 6
                            Text { text: "NOMAD_OS // CPU_LOAD: " + root.cpuLoad + "%"; font.family: "Monospace"; font.pixelSize: 14; color: root.amber }
                            Rectangle {
                                width: 200; height: 4; color: "#22E1B12C"
                                Rectangle {
                                    height: parent.height; width: parent.width * (parseInt(root.cpuLoad) / 100)
                                    color: root.amber
                                    Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
                                }
                            }
                        }
                    }
                }

                // --- 2. BOTTOM-LEFT NETWORK MATRIX ---
                PanelWindow {
                    screen: targetScreen
                    WlrLayershell.layer: WlrLayershell.Bottom
                    anchors { bottom: true; left: true }
                    implicitWidth: 450; implicitHeight: 220; color: "transparent"
                    
                    Item {
                        anchors.fill: parent; anchors.margins: 40
                        // Corner L-Bracket
                        Rectangle { width: 2; height: 100; color: root.amber; anchors.left: parent.left; anchors.bottom: parent.bottom }
                        Rectangle { width: 100; height: 2; color: root.amber; anchors.left: parent.left; anchors.bottom: parent.bottom }
                        
                        Column {
                            anchors.left: parent.left; anchors.bottom: parent.bottom
                            anchors.margins: 15; spacing: 8
                            
                            Text { 
                                text: "LINK: " + root.activeIface.toUpperCase()
                                font.family: "Monospace"; font.pixelSize: 10; color: root.amber; opacity: 0.5 
                            }
                            
                            // Matrix Readout
                            Column {
                                spacing: 2
                                Row {
                                    spacing: 10
                                    Text { text: "RX >"; font.family: "Monospace"; font.pixelSize: 16; color: root.amber; width: 40 }
                                    Text { text: root.netDown + " KB/s"; font.family: "Monospace"; font.pixelSize: 16; color: root.amber; font.bold: true }
                                }
                                Row {
                                    spacing: 10
                                    Text { text: "TX >"; font.family: "Monospace"; font.pixelSize: 12; color: root.amber; width: 40; opacity: 0.7 }
                                    Text { text: root.netUp + " KB/s"; font.family: "Monospace"; font.pixelSize: 12; color: root.amber; opacity: 0.7 }
                                }
                            }

                            // Activity Pulse
                            Rectangle {
                                width: 120; height: 2; color: "#11E1B12C"
                                Rectangle {
                                    height: parent.height; width: Math.min(parent.width, parseFloat(root.netDown) / 10)
                                    color: root.amber
                                    opacity: 0.4 + (Math.random() * 0.6) // Flicker effect
                                }
                            }
                        }
                    }
                }

                // --- 3. BOTTOM-RIGHT MEMORY ---
                PanelWindow {
                    screen: targetScreen
                    WlrLayershell.layer: WlrLayershell.Bottom
                    anchors { bottom: true; right: true }
                    implicitWidth: 500; implicitHeight: 140; color: "transparent"
                    
                    Rectangle {
                        width: 380; height: 80; anchors.centerIn: parent
                        color: root.glass; border.color: root.amber; border.width: 1
                        
                        Column {
                            anchors.centerIn: parent; spacing: 10
                            
                            // Updated text to show Used / Total GB
                            Text { 
                                text: "MEM_POOL // " + root.memUsedGB + "GB / " + root.memTotalGB + "GB"; 
                                font.family: "Monospace"; font.pixelSize: 12; color: root.amber 
                            }
                            
                            Rectangle {
                                width: 300; height: 6; color: "#22E1B12C"
                                Rectangle {
                                    height: parent.height; 
                                    // Progress bar correctly maps used percentage
                                    width: parent.width * (parseInt(root.memLoad) / 100)
                                    color: root.amber
                                    Behavior on width { NumberAnimation { duration: 1500; easing.type: Easing.OutElastic } }
                                }
                            }
            
                            // Added a small percentage indicator for flavor
                            Text {
                                text: root.memLoad + "% CAPACITY_UTILIZED";
                                font.family: "Monospace"; font.pixelSize: 8; color: root.amber; opacity: 0.6;
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}