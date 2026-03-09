import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: storageWindow
    required property var targetScreen
    required property var root
    property var anchorTarget 

    screen: targetScreen
    
    // Use Top to ensure it grabs input, but with a mask so it's "passthrough" elsewhere
    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.namespace: "storage_module"
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrLayershell.None
    
    // --- THE FIX: Precise Masking ---
    WlrLayershell.mask: Region {
        item: storageMainBox
    }

    // Dynamic margin logic from your second version
    Binding {
        target: storageWindow.WlrLayershell
        property: "margins.bottom"
        value: anchorTarget ? Math.floor(anchorTarget.WlrLayershell.margins.bottom + anchorTarget.implicitHeight + 15) : 20
    }
    WlrLayershell.margins.right: 20

    anchors { bottom: true; right: true }

    implicitWidth: 320 // Narrower to match the content
    implicitHeight: 800
    color: "transparent"

    Rectangle {
        id: storageMainBox
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        
        width: 300
        // Ensure height updates so the Region mask stays accurate
        height: Math.max(storageList.contentHeight + 20, 10)
        color: "transparent" 

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
                    id: driveBox
                    anchors.fill: parent
                    color: root ? root.glass : "#0a0a0a"
                    border.width: 1
                    border.color: (driveMouse.containsMouse || mounted) ? storageWindow.accent : "#333"
                    opacity: mounted ? 1.0 : 0.7

                    // Visual polish from your second version
                    RectangularGlow {
                        anchors.fill: parent
                        glowRadius: 5
                        spread: 0.2
                        color: storageWindow.accent
                        visible: mounted
                        opacity: 0.2
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10
                        
                        Column {
                            Layout.fillWidth: true
                            Text { 
                                text: "STORAGE // " + label.toUpperCase()
                                font.family: storageWindow.monoFont
                                font.pixelSize: 10 
                                color: (driveMouse.containsMouse || mounted) ? storageWindow.accent : "#888" 
                            }
                            Text { 
                                text: name + " [" + size + "]"
                                font.family: storageWindow.monoFont
                                font.pixelSize: 9 
                                color: driveMouse.containsMouse ? "#aaa" : "#555" 
                            }
                        }

                        Row {
                            spacing: 5
                            Button {
                                id: mntBtn
                                width: 45; height: 26; flat: true
                                z: 10 // Ensure button is high in stacking order
                                onClicked: {
                                    actionProc.command = mounted 
                                        ? ["udisksctl", "unmount", "-b", "/dev/" + name] 
                                        : ["udisksctl", "mount", "-b", "/dev/" + name];
                                    actionProc.running = true;
                                }
                                background: Rectangle { 
                                    color: mntBtn.hovered ? "#222" : "#111"
                                    border.color: mntBtn.pressed ? storageWindow.accent : (mntBtn.hovered ? "#666" : "#333")
                                    border.width: 1 
                                }
                                contentItem: Text { 
                                    text: mounted ? "UMNT" : "MNT"
                                    font.family: storageWindow.monoFont; font.pixelSize: 8 
                                    color: (mntBtn.hovered || mounted) ? storageWindow.accent : "#888"
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Button {
                                id: openBtn
                                width: 45; height: 26; visible: mounted; flat: true
                                z: 10
                                onClicked: {
                                    browserProc.command = ["xdg-open", path];
                                    browserProc.running = true;
                                }
                                background: Rectangle { 
                                    color: openBtn.hovered ? "#222" : "#111"
                                    border.color: openBtn.pressed ? storageWindow.accent : (openBtn.hovered ? "#666" : "#333")
                                    border.width: 1 
                                }
                                contentItem: Text { 
                                    text: "VIEW"
                                    font.family: storageWindow.monoFont; font.pixelSize: 8 
                                    color: storageWindow.accent
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: driveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        // This allows the hover effect to work WITHOUT stealing the click from the buttons
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }
    }

    // Backend processes (unchanged)
    Process { id: actionProc; onExited: lsblkProc.running = true }
    Process { id: browserProc }
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
            } catch (e) { console.log("Storage JSON Error: " + e); }
            lsblkProc.running = false;
        }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: if(!lsblkProc.running) lsblkProc.running = true }
}