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
    
    // We remove the mask entirely. 
    // The window will only be as large as the content.
    WlrLayershell.keyboardFocus: WlrLayershell.None
    
    anchors { bottom: true; right: true }
    
    // The window size now tracks the box size exactly
    implicitWidth: storageMainBox.width
    implicitHeight: storageMainBox.height

    property color accent: (root && root.accent !== undefined) ? root.accent : "#00ffff"
    property string monoFont: (root && root.monoFont !== undefined) ? root.monoFont : "Monospace"

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
            spacing: 10
            interactive: false 
            model: ListModel { id: storageModel }

            delegate: Item {
                width: 280; height: 60
                
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

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10
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
                        Row {
                            spacing: 5
                            Button {
                                width: 45; height: 26
                                text: mounted ? "UMNT" : "MNT"
                                onClicked: {
                                    actionProc.command = mounted 
                                        ? ["udisksctl", "unmount", "-b", "/dev/" + name] 
                                        : ["udisksctl", "mount", "-b", "/dev/" + name];
                                    actionProc.running = true;
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
        command: ["lsblk", "-J", "-o", "NAME,SIZE,MOUNTPOINTS,FSTYPE,LABEL"]
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
                                name: d.name, label: d.label || d.name,
                                size: d.size, mounted: mnt !== "", path: mnt
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