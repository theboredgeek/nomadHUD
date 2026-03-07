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

    // --- LIVE CLOCK LOGIC ---
    property string currentTime: "00:00:00"
    Timer {
        interval: 1000; running: true; repeat: true;
        onTriggered: root.currentTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }

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

    // --- 1. TOP BAR (152px GAP) ---
    PanelWindow {
        WlrLayershell.namespace: "nomadTop"
        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.exclusiveZone: isMultiTasking ? 45 : 0 
        WlrLayershell.keyboardFocus: WlrLayershell.None
        
        anchors { top: true; left: true; right: true }
        height: isMultiTasking ? 45 : 152 
        color: "transparent"

        Rectangle {
            width: root.isMultiTasking ? parent.width - 100 : 400
            height: root.isMultiTasking ? 40 : 60 // Shrunk for 1080p fit
            x: root.isMultiTasking ? 50 : (parent.width / 2 - width / 2)
            y: root.isMultiTasking ? 2 : (parent.height - height - 5) // Clings 5px above

            color: "#E6000000"; border.color: "#E1B12C"; border.width: 2
            ShaderEffect {
                anchors.fill: parent; anchors.margins: 2
                property real u_width: parent.width; property real u_height: parent.height; property real u_time: root.u_time
                fragmentShader: "shaders/hexgrid.qsb"
            }
            Text { anchors.centerIn: parent; text: "SYS // " + root.currentTime; color: "#E1B12C"; font.bold: true; font.pixelSize: root.isMultiTasking ? 14 : 18 }

            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        }
    }

    // --- 2. BOTTOM BAR (52px GAP REMAINING) ---
    PanelWindow {
        WlrLayershell.namespace: "nomadBottom"
        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.exclusiveZone: isMultiTasking ? 45 : 0
        WlrLayershell.keyboardFocus: WlrLayershell.None
        
        anchors { bottom: true; left: true; right: true }
        height: isMultiTasking ? 45 : 52 // EXACT space left after 152+876
        color: "transparent"

        Rectangle {
            width: root.isMultiTasking ? parent.width - 100 : 400
            height: root.isMultiTasking ? 40 : 48 // Must be < 52 to be seen
            x: root.isMultiTasking ? 50 : (parent.width / 2 - width / 2)
            y: root.isMultiTasking ? (parent.height - height - 2) : 2 // Clings 2px below window

            color: "#E6000000"; border.color: "#E1B12C"; border.width: 2
            ShaderEffect {
                anchors.fill: parent; anchors.margins: 2
                property real u_width: parent.width; property real u_height: parent.height; property real u_time: root.u_time
                fragmentShader: "shaders/hexgrid.qsb"
            }
            Text { anchors.centerIn: parent; text: "TASK // INTERFACE"; color: "#E1B12C"; font.bold: true; font.pixelSize: root.isMultiTasking ? 14 : 16 }

            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        }
    }

    // --- 3. LEFT BAR (302px GAP) ---
    PanelWindow {
        WlrLayershell.namespace: "nomadLeft"
        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.exclusiveZone: isMultiTasking ? 45 : 0
        WlrLayershell.keyboardFocus: WlrLayershell.None
        
        anchors { left: true; top: true; bottom: true }
        width: isMultiTasking ? 45 : 302 
        color: "transparent"

        Rectangle {
            width: root.isMultiTasking ? 40 : 60
            height: root.isMultiTasking ? parent.height - 100 : 300
            x: root.isMultiTasking ? 2 : (parent.width - width - 5) // Clings 5px left
            y: root.isMultiTasking ? 50 : (parent.height / 2 - height / 2)

            color: "#E6000000"; border.color: "#E1B12C"; border.width: 2
            ShaderEffect {
                anchors.fill: parent; anchors.margins: 2
                property real u_width: parent.width; property real u_height: parent.height; property real u_time: root.u_time
                fragmentShader: "shaders/hexgrid.qsb"
            }
            Text { anchors.centerIn: parent; text: "AUD"; color: "#E1B12C"; font.bold: true; rotation: -90 }

            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        }
    }

    // --- 4. RIGHT BAR (302px GAP) ---
    PanelWindow {
        WlrLayershell.namespace: "nomadRight"
        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.exclusiveZone: isMultiTasking ? 45 : 0
        WlrLayershell.keyboardFocus: WlrLayershell.None
        
        anchors { right: true; top: true; bottom: true }
        width: isMultiTasking ? 45 : 302 // Matches left side gap for symmetry
        color: "transparent"

        Rectangle {
            width: root.isMultiTasking ? 40 : 60
            height: root.isMultiTasking ? parent.height - 100 : 300
            x: root.isMultiTasking ? (parent.width - width - 2) : 5 // Clings 5px right
            y: root.isMultiTasking ? 50 : (parent.height / 2 - height / 2)

            color: "#E6000000"; border.color: "#E1B12C"; border.width: 2
            ShaderEffect {
                anchors.fill: parent; anchors.margins: 2
                property real u_width: parent.width; property real u_height: parent.height; property real u_time: root.u_time
                fragmentShader: "shaders/hexgrid.qsb"
            }
            Text { anchors.centerIn: parent; text: "HW"; color: "#E1B12C"; font.bold: true; rotation: 90 }

            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        }
    }
}
