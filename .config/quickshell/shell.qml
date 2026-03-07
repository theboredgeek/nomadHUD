import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root
    
    property int windowCount: 0
    readonly property bool isMultiTasking: windowCount >= 2

    // 1. STABLE WINDOW TRACKER (Property-based)
    Process {
        id: hyprWatcher
        // Start the process immediately
        running: true 
        command: ["/bin/sh", "-c", "hyprctl activeworkspace -j | jq '.windows'"]
        
        stdout: SplitParser {
            onRead: data => {
                let count = parseInt(data.trim());
                if (!isNaN(count)) root.windowCount = count;
                // Once data is read, stop the process so it can be restarted by the timer
                hyprWatcher.running = false;
            }
        }
    }

    // Refresh every 500ms by toggling the 'running' property
    Timer {
        interval: 500; running: true; repeat: true; 
        onTriggered: if (!hyprWatcher.running) hyprWatcher.running = true;
    }

    // 2. SOUND FX TRIGGER (Property-based)
    Process { 
        id: soundProc
        running: false
        // Ensure it stops running after play so it can be re-triggered
        onRunningChanged: if (!running) command = [] 
    }

    onIsMultiTaskingChanged: {
        let sound = isMultiTasking ? "dx_data_slide.wav" : "dx_menu_open.wav";
        soundProc.command = ["mpv", "--no-video", "/home/othei/.local/share/sounds/" + sound];
        soundProc.running = true;
    }

    // 3. VISUAL PULSE
    property real u_time: 0.0
    Timer { 
        interval: 16; running: true; repeat: true; 
        onTriggered: root.u_time += 0.01 
    }

    PanelWindow {
        id: mainPanel
        WlrLayershell.namespace: "nomadHUD"
        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.exclusiveZone: 40 
        WlrLayershell.keyboardFocus: WlrLayershell.None

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        // --- TOP SECTION ---
        Rectangle {
            id: sysBar
            width: root.isMultiTasking ? parent.width - 80 : 450
            height: root.isMultiTasking ? 40 : 120
            x: root.isMultiTasking ? 40 : (parent.width / 2 - width / 2)
            y: root.isMultiTasking ? 0 : (parent.height / 2 - 180)
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

        // --- BOTTOM SECTION ---
        Rectangle {
            id: taskBar
            width: root.isMultiTasking ? parent.width - 80 : 450
            height: root.isMultiTasking ? 40 : 80
            x: root.isMultiTasking ? 40 : (parent.width / 2 - width / 2)
            y: root.isMultiTasking ? (parent.height - height) : (parent.height / 2 + 100)
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
