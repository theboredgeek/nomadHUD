import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "."

ShellRoot {
    id: bgRoot
    
    property real u_time: 0.0
    Timer { interval: 16; running: true; repeat: true; onTriggered: bgRoot.u_time += 0.01 }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            Item {
                id: screenScope
                required property var modelData

                PanelWindow {
                    id: bgWindow
                    screen: screenScope.modelData 
                    WlrLayershell.layer: WlrLayershell.Background
                    
                    implicitWidth: screen.width
                    implicitHeight: screen.height

                    // Root background container
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.bgDark
                        
                        // Animated Gradient Layer
                        Rectangle {
                            anchors.fill: parent
                            opacity: 0.15 + (Math.sin(bgRoot.u_time) * 0.05)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Theme.circuitBlue }
                                GradientStop { position: 1.0; color: "#001111" } 
                            }
                        }
                        
                        // Animated Amber Lines
                        Repeater {
                            model: 12
                            delegate: Rectangle {
                                width: parent.width
                                height: Theme.borderWidth
                                color: Theme.amber
                                opacity: 0.1
                                y: (parent.height * (index / 12) + (bgRoot.u_time * 80)) % parent.height
                            }
                        }
                    }
                }
            }
        }
    }
}