import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root
    property bool isMultiTasking: false 

    // THE TIMER (Internal pulse for the shaders)
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
                property real u_width: parent.width
                property real u_height: parent.height
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
                property real u_width: parent.width
                property real u_height: parent.height
                property real u_time: root.u_time
                fragmentShader: "shaders/hexgrid.qsb"
            }

            Text { anchors.centerIn: parent; text: "TASK // INTERFACE"; color: "#E1B12C"; font.bold: true }

            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        }

        // KEEP THE CLICKER FOR NOW (To confirm visuals work)
        MouseArea {
            anchors.fill: parent
            onClicked: root.isMultiTasking = !root.isMultiTasking
        }
    }
}
