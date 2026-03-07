import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root
    
    // --- SHARED LOGIC ---
    property int windowCount: 0
    readonly property bool isMultiTasking: windowCount >= 2
    property real u_time: 0.0
    Timer { interval: 16; running: true; repeat: true; onTriggered: root.u_time += 0.01 }

    // --- STABLE WINDOW TRACKER ---
    Process {
        id: hyprWatcher
        running: true 
        command: ["/bin/sh", "-c", "hyprctl activeworkspace -j | jq '.windows'"]
        stdout: SplitParser {
            onRead: data => {
                let count = parseInt(data.trim());
                if (!isNaN(count)) root.windowCount = count;
                hyprWatcher.running = false;
            }
        }
    }
    Timer {
        interval: 500; running: true; repeat: true; 
        onTriggered: if (!hyprWatcher.running) hyprWatcher.running = true;
    }

    // --- 1. TOP BAR WINDOW ---
    PanelWindow {
        WlrLayershell.namespace: "nomadTop"
        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.exclusiveZone: isMultiTasking ? 45 : 0 // Only reserve space in Bar mode
        
        anchors { top: true; left: true; right: true }
        height: isMultiTasking ? 45 : Screen.height // Expand to center for HUD
        color: "transparent"

        Rectangle {
            width: root.isMultiTasking ? parent.width - 80 : 450
            height: root.isMultiTasking ? 40 : 120
            x: root.isMultiTasking ? 40 : (parent.width / 2 - width / 2)
            y: root.isMultiTasking ? 2 : (parent.height / 2 - 180)
            color: "#E6000000"; border.color: "#E1B12C"; border.width: 2
            
            ShaderEffect {
                anchors.fill: parent; anchors.margins: 2
                property real u_width: parent.width; property real u_height: parent.height
                property real u_time: root.u_time
                fragmentShader: "shaders/hexgrid.qsb"
            }
            Text { anchors.centerIn: parent; text: "SYS // STATUS"; color: "#E1B12C"; font.bold: true }

            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        }
    }

    // --- 2. BOTTOM BAR WINDOW ---
    PanelWindow {
        WlrLayershell.namespace: "nomadBottom"
        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.exclusiveZone: isMultiTasking ? 45 : 0
        
        anchors { bottom: true; left: true; right: true }
        height: isMultiTasking ? 45 : Screen.height
        color: "transparent"

        Rectangle {
            width: root.isMultiTasking ? parent.width - 80 : 450
            height: root.isMultiTasking ? 40 : 80
            x: root.isMultiTasking ? 40 : (parent.width / 2 - width / 2)
            y: root.isMultiTasking ? 2 : (-(parent.height / 2) + 100) // Offset from bottom

            color: "#E6000000"; border.color: "#E1B12C"; border.width: 2
            
            ShaderEffect {
                anchors.fill: parent; anchors.margins: 2
                property real u_width: parent.width; property real u_height: parent.height
                property real u_time: root.u_time
                fragmentShader: "shaders/hexgrid.qsb"
            }
            Text { anchors.centerIn: parent; text: "TASK // INTERFACE"; color: "#E1B12C"; font.bold: true }

            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        }
    }
}
