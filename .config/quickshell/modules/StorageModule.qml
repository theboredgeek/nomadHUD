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
    WlrLayershell.margins { right: 20 }

    // This handles the stacking logic
    Binding {
        target: storageWindow.WlrLayershell
        property: "margins.bottom"
        value: anchorTarget ? Math.floor(anchorTarget.WlrLayershell.margins.bottom + anchorTarget.implicitHeight + 15) : 250
    }

    anchors { bottom: true; right: true }

    implicitWidth: 300
    implicitHeight: storageList.contentHeight + 20
    color: "transparent"

    // Data collection process
    Process {
        id: lsblkProc
        command: ["lsblk", "-J", "-o", "NAME,SIZE,MOUNTPOINTS,FSTYPE,LABEL"]
        running: true
        
        // We use a property to accumulate the JSON chunks
        property string buffer: ""

        // SplitParser is the standard Quickshell way to handle incoming data stream
        stdout: SplitParser {
            onRead: data => {
                lsblkProc.buffer += data;
            }
        }
        
        onExited: (exitCode) => {
            let cleanData = lsblkProc.buffer.trim();
            lsblkProc.buffer = ""; 
            
            if (!cleanData.startsWith("{")) {
                lsblkProc.running = false;
                return;
            }

            try {
                const json = JSON.parse(cleanData);
                storageModel.clear();
                
                if (json.blockdevices) {
                    const processDev = (d) => {
                        let mnt = "";
                        if (Array.isArray(d.mountpoints)) {
                            mnt = d.mountpoints.find(p => p !== null) || "";
                        }

                        // Filter out empty entries/swap, focus on your NTFS/BTRFS drives
                        if (d.fstype && d.fstype !== "swap" && !d.name.includes("loop")) {
                            storageModel.append({
                                name: d.name,
                                label: d.label || d.name,
                                size: d.size,
                                mounted: mnt !== "",
                                path: mnt
                            });
                        }
                        if (d.children) d.children.forEach(processDev);
                    };
                    json.blockdevices.forEach(processDev);
                }
            } catch (e) { 
                console.log("Storage JSON Error: " + e); 
            }
            lsblkProc.running = false;
        }
    }

    
    Timer { 
        interval: 5000; running: true; repeat: true; 
        onTriggered: if(!lsblkProc.running) lsblkProc.running = true 
    }

    ListView {
        id: storageList
        width: 280
        height: contentHeight
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.bottom: parent.bottom
        spacing: 10
        interactive: false
        model: ListModel { id: storageModel }

        delegate: Rectangle {
            width: 280; height: 60
            color: root ? root.glass : "black"
            border.width: 1
            border.color: mounted ? root.amber : "#333"

            RowLayout {
                anchors.fill: parent; anchors.margins: 10
                Column {
                    Layout.fillWidth: true
                    Text { 
                        text: "DRIVE // " + label.toUpperCase()
                        font.family: "Monospace"; font.pixelSize: 10; color: mounted ? root.amber : "#888" 
                    }
                    Text { 
                        text: name + " [" + size + "]"
                        font.family: "Monospace"; font.pixelSize: 9; color: "#555" 
                    }
                }

                Row {
                    spacing: 5
                    Button {
                        id: mntBtn
                        width: 45; height: 26
                        flat: true
                        onClicked: {
                            actionProc.command = mounted 
                                ? ["udisksctl", "unmount", "-b", "/dev/" + name] 
                                : ["udisksctl", "mount", "-b", "/dev/" + name];
                            actionProc.running = true;
                        }
                        background: Rectangle { color: "#111"; border.color: mntBtn.pressed ? root.amber : "#333"; border.width: 1 }
                        contentItem: Text { 
                            text: mounted ? "UMNT" : "MNT"
                            font.family: "Monospace"; font.pixelSize: 8; color: mounted ? root.amber : "#888"
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                    }
                    Button {
                        id: openBtn
                        width: 45; height: 26; visible: mounted
                        flat: true
                        onClicked: {
                            browserProc.command = ["xdg-open", path];
                            browserProc.running = true;
                        }
                        background: Rectangle { color: "#111"; border.color: openBtn.pressed ? root.amber : "#333"; border.width: 1 }
                        contentItem: Text { 
                            text: "VIEW"
                            font.family: "Monospace"; font.pixelSize: 8; color: root.amber
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    Process { id: actionProc; onExited: lsblkProc.running = true }
    Process { id: browserProc }
}