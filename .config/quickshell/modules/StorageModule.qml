import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: storageWindow
    required property var targetScreen
    required property var root
    property var anchorTarget

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.namespace: "storage_module"
    WlrLayershell.keyboardFocus: WlrLayershell.None
    
    anchors { bottom: true; right: true }
    
    implicitWidth: storageMainBox.width
    implicitHeight: storageMainBox.height

    property color accent: (root && root.amber !== undefined) ? root.amber : "#e1a82c"
    property string monoFont: (root && root.fontFamily !== undefined) ? root.fontFamily : "Monospace"

    Binding {
        target: storageWindow.WlrLayershell
        property: "margins.bottom"
        value: anchorTarget ? Math.floor(anchorTarget.WlrLayershell.margins.bottom + anchorTarget.implicitHeight + 15) : 20
    }
    WlrLayershell.margins.right: 20

    Rectangle {
        id: storageMainBox
        width: 300
        height: Math.max(storageList.contentHeight + 20, 60)
        color: (root && root.glass !== undefined) ? root.glass : "#E6000000"
        border.color: "#333"
        border.width: 1

        ListView {
            id: storageList
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12
            interactive: false 
            model: ListModel { id: storageModel }

            delegate: Item {
                width: 280; height: 75 // Increased height for the bar
                
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: (driveHover.containsMouse || mounted) ? storageWindow.accent : "#333"

                    MouseArea {
                        id: driveHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Column {
                                Layout.fillWidth: true
                                Text { 
                                    text: "STORAGE // " + (model.label ? model.label.toUpperCase() : "DRIVE")
                                    font.family: storageWindow.monoFont
                                    font.pixelSize: 10; color: (driveHover.containsMouse || mounted) ? storageWindow.accent : "#888" 
                                }
                                Text { 
                                    text: (model.name || "dev") + " [" + (model.size || "--") + "]"
                                    font.family: storageWindow.monoFont
                                    font.pixelSize: 9; color: driveHover.containsMouse ? "#aaa" : "#555" 
                                }
                            }
                            Button {
                                width: 45; height: 24
                                text: mounted ? "UMNT" : "MNT"
                                onClicked: {
                                    actionProc.command = mounted 
                                        ? ["udisksctl", "unmount", "-b", "/dev/" + name] 
                                        : ["udisksctl", "mount", "-b", "/dev/" + name];
                                    actionProc.running = true;
                                }
                            }
                        }

                        // CAPACITY BAR SECTION
                        ColumnLayout {
                            Layout.fillWidth: true
                            visible: mounted
                            spacing: 2

                            // Metrics Text
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: model.avail + " FREE"
                                    font.family: storageWindow.monoFont
                                    font.pixelSize: 8; color: "#666"
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: model.usePerc
                                    font.family: storageWindow.monoFont
                                    font.pixelSize: 8; color: storageWindow.accent
                                }
                            }

                            // The Bar
                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                color: "#222"
                                Rectangle {
                                    width: parent.width * (parseInt(model.usePerc) / 100)
                                    height: parent.height
                                    color: storageWindow.accent
                                    opacity: 0.8
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Process { id: actionProc; onExited: lsblkProc.running = true }
    
    Process {
        id: lsblkProc
        // Added FSAVAIL and FSUSE% to the columns
        command: ["lsblk", "-J", "-o", "NAME,SIZE,MOUNTPOINTS,FSTYPE,LABEL,FSAVAIL,FSUSE%"]
        running: true
        property string buffer: ""
        stdout: SplitParser { onRead: data => { lsblkProc.buffer += data; } }
        onExited: (exitCode) => {
            let cleanData = lsblkProc.buffer.trim();
            lsblkProc.buffer = ""; 
            if (!cleanData.startsWith("{")) { lsblkProc.running = false; return; }
            try {
                const json = JSON.parse(cleanData);
                storageModel.clear();
                if (json.blockdevices) {
                    const processDev = (d) => {
                        let mnt = "";
                        if (Array.isArray(d.mountpoints)) { mnt = d.mountpoints.find(p => p !== null) || ""; }
                        if (d.fstype && d.fstype !== "swap" && !d.name.includes("loop")) {
                            storageModel.append({
                                name: d.name, 
                                label: d.label || d.name,
                                size: d.size, 
                                mounted: mnt !== "", 
                                path: mnt,
                                avail: d.fsavail || "0B",
                                usePerc: d["fsuse%"] || "0%"
                            });
                        }
                        if (d.children) d.children.forEach(processDev);
                    };
                    json.blockdevices.forEach(processDev);
                }
            } catch (e) { console.log(e); }
            lsblkProc.running = false;
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: if(!lsblkProc.running) lsblkProc.running = true }
}