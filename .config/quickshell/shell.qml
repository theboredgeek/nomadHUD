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
    property real u_time: 0.0
    Timer { interval: 16; running: true; repeat: true; onTriggered: root.u_time += 0.01 }

    // --- 1. CPU MONITOR (Top/Stat parser) ---
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

    // --- 2. MEMORY MONITOR (Free parser) ---
    Process {
        id: memProc
        command: ["/bin/sh", "-c", "free | grep Mem | awk '{print $3/$2 * 100}'"]
        stdout: SplitParser {
            onRead: data => { 
                let val = parseFloat(data.trim()).toFixed(0);
                root.memLoad = val.padStart(2, '0');
                memProc.running = false;
            }
        }
    }

    // Update hardware every 2 seconds
    Timer {
        interval: 2000; running: true; repeat: true;
        onTriggered: {
            if (!cpuProc.running) cpuProc.running = true;
            if (!memProc.running) memProc.running = true;
        }
    }

    // --- 0. BACKGROUND LAYER (The Animated Wallpaper) ---
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

    // --- 2. TOP-LEFT DIAGNOSTIC (Clock + State) ---
    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Bottom
        anchors { top: true; left: true }
        width: 400; height: 150; color: "transparent"
        Item {
            anchors.fill: parent; anchors.margins: 40
            Rectangle { width: 2; height: 60; color: root.amber; anchors.left: parent.left; anchors.top: parent.top }
            Rectangle { width: 60; height: 2; color: root.amber; anchors.left: parent.left; anchors.top: parent.top }
            Text {
                text: "NOMAD_OS // CPU: " + root.cpuLoad + "%"
                font.family: "Monospace"; font.pixelSize: 14; color: root.amber
                anchors.left: parent.left; anchors.top: parent.top; anchors.leftMargin: 15; anchors.topMargin: 15
            }
        }
    }

    // --- 3. BOTTOM-RIGHT STATUS (Memory + Node) ---
    PanelWindow {
        WlrLayershell.layer: WlrLayershell.Bottom
        anchors { bottom: true; right: true }
        width: 400; height: 100; color: "transparent"
        Rectangle {
            width: 320; height: 50; anchors.centerIn: parent
            color: root.glass; border.color: root.amber; border.width: 1
            Text {
                anchors.centerIn: parent
                text: "MEM_USED // " + root.memLoad + "% // NODE_" + screen.name.toUpperCase()
                font.family: "Monospace"; font.bold: true; font.pixelSize: 12; color: root.amber
            }
        }
    }
}