import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root
    property bool isMultiTasking: false 

    PanelWindow {
        id: mainPanel
        WlrLayershell.namespace: "nomadHUD"
        WlrLayershell.layer: WlrLayershell.Overlay
        anchors { top: true; right: true }

        property real u_time: 0.0
        Timer { 
            interval: 16; running: true; repeat: true; 
            onTriggered: mainPanel.u_time += 0.01 
        }

        implicitWidth: isMultiTasking ? 250 : 500
        implicitHeight: isMultiTasking ? 60 : 350

        Behavior on implicitWidth { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
        Behavior on implicitHeight { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

        Rectangle {
            anchors.fill: parent
            color: "#E6000000"
            border.color: "#E1B12C"
            border.width: 2

            ShaderEffect {
                anchors.fill: parent
                anchors.margins: 2
                
                property real u_width: parent.width
                property real u_height: parent.height
                property real u_time: mainPanel.u_time

                // In Quickshell 0.2.x, the 'Shader' type is often actually 
                // just 'fragmentShader: "shaders/hexgrid.frag"' 
                // but it MUST be absolute or resolved via Qt.resolvedUrl
                fragmentShader: Qt.resolvedUrl("shaders/hexgrid.frag")
            }

            Text {
                anchors.centerIn: parent
                text: isMultiTasking ? "BAR" : "DXMD // AUGMENTED"
                color: "#E1B12C"
                font.bold: true
                font.pixelSize: isMultiTasking ? 14 : 24
            }
        }
    }
}
