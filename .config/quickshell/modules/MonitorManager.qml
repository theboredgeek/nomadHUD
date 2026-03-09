import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: monitorManager
    required property var targetScreen
    required property var root

    screen: targetScreen
    WlrLayershell.layer: WlrLayershell.Bottom
    WlrLayershell.exclusiveZone: 0 
    
    anchors { 
        top: true; bottom: true 
        left: true; right: true 
    }
    
    color: "transparent"

    // --- THEME DATA BINDING ---
    readonly property color accent: root ? root.amber : "#2c4de1"
    readonly property string monoFont: root ? root.fontFamily : "Monospace"

    ListModel { id: monModel }
    property var rawResData: ({}) 
    property string activeMon: ""
    property bool hasChanges: false

    function getHyprTransform(type) {
        const transforms = {
            "normal": 0, "90": 1, "180": 2, "270": 3,
            "flipped": 4, "flipped-90": 5, "flipped-180": 6, "flipped-270": 7
        };
        return transforms[type] || 0;
    }

    MouseArea {
        id: globalShield
        anchors.fill: parent
        enabled: layoutPopup.opened
        hoverEnabled: false
        onPressed: layoutPopup.opened = false
    }

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 500
        spacing: 10

        Rectangle {
            id: hexTrigger
            Layout.alignment: Qt.AlignHCenter
            width: 70; height: 70
            // Theme Reliance: root.amber
            color: layoutPopup.opened ? monitorManager.accent : "#0d0d0d"
            border.color: monitorManager.accent; border.width: 2
            rotation: 45; opacity: 0.9

            Text {
                anchors.centerIn: parent
                text: "DISP"
                color: layoutPopup.opened ? "black" : monitorManager.accent
                font.family: monitorManager.monoFont
                font.pixelSize: 12; font.bold: true
                rotation: -45 
            }

            MouseArea {
                anchors.fill: parent
                onClicked: layoutPopup.opened = !layoutPopup.opened
            }
        }

        Rectangle {
            id: layoutPopup
            property bool opened: false
            visible: opened
            Layout.alignment: Qt.AlignHCenter
            
            width: 500
            height: Math.min(monitorManager.screen.height * 0.8, 800)
            color: "#050505"; border.color: monitorManager.accent; border.width: 1; opacity: 0.95

            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => mouse.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 15

                Text { 
                    text: "TOPOLOGY_CALIBRATION_V34"
                    color: monitorManager.accent; font.bold: true
                    font.family: monitorManager.monoFont
                }

                Rectangle {
                    Layout.fillWidth: true; height: 200; color: "black"; border.color: "#222"; clip: true
                    
                    Repeater {
                        model: monModel
                        Rectangle {
                            width: getLogicalWidth(index) / 40
                            height: getLogicalHeight(index) / 40
                            x: 50 + (model.x / 40); y: 40 + (model.y / 40)
                            color: activeMon === name ? monitorManager.accent : "#1a1a1a"
                            border.color: "white"; border.width: activeMon === name ? 2 : 1
                            
                            Text { 
                                anchors.centerIn: parent
                                color: activeMon === name ? "black" : "white"
                                font.family: monitorManager.monoFont
                                font.pixelSize: 9; text: name
                            }

                            MouseArea {
                                anchors.fill: parent; drag.target: parent
                                onPressed: activeMon = name
                                onReleased: {
                                    let tx = Math.round((parent.x - 50) * 40);
                                    let ty = Math.round((parent.y - 40) * 40);
                                    monModel.setProperty(index, "x", tx);
                                    monModel.setProperty(index, "y", ty);
                                    hasChanges = true;
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    ComboBox {
                        Layout.fillWidth: true
                        model: ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"]
                        font.family: monitorManager.monoFont
                        onActivated: (idx) => {
                            for(let i=0; i<monModel.count; i++) {
                                if(monModel.get(i).name === activeMon) {
                                    monModel.setProperty(i, "rotationType", textAt(idx));
                                    hasChanges = true;
                                }
                            }
                        }
                    }
                    Button { 
                        text: "STITCH"
                        font.family: monitorManager.monoFont
                        onClicked: autoStitchLogic() 
                    }
                }

                Button { 
                    text: "APPLY & PERSIST"
                    Layout.fillWidth: true; highlighted: hasChanges
                    font.family: monitorManager.monoFont
                    onClicked: applyTopology() 
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; color: "#050505"; border.color: "#222"
                    ScrollView {
                        anchors.fill: parent; clip: true
                        Column {
                            width: parent.width
                            Repeater {
                                model: (activeMon !== "" && rawResData[activeMon]) ? rawResData[activeMon] : []
                                Button {
                                    width: parent.width; text: modelData; font.pixelSize: 9
                                    font.family: monitorManager.monoFont
                                    onClicked: {
                                        let res = modelData.split(/[\s,]+/)[0].replace("px", "");
                                        for(let i=0; i<monModel.count; i++) {
                                            if(monModel.get(i).name === activeMon) {
                                                monModel.setProperty(i, "currentRes", res);
                                                monModel.setProperty(i, "w", parseInt(res.split('x')[0]));
                                                monModel.setProperty(i, "h", parseInt(res.split('x')[1]));
                                                hasChanges = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function autoStitchLogic() {
        if (monModel.count < 2) return;
        let anchorIdx = 0; let minX = monModel.get(0).x;
        for(let i=1; i<monModel.count; i++) {
            if(monModel.get(i).x < minX) { minX = monModel.get(i).x; anchorIdx = i; }
        }
        let secondaryIdx = (anchorIdx === 0) ? 1 : 0;
        let anchorWidth = getLogicalWidth(anchorIdx);
        monModel.setProperty(secondaryIdx, "x", monModel.get(anchorIdx).x + anchorWidth);
        monModel.setProperty(secondaryIdx, "y", monModel.get(anchorIdx).y);
        hasChanges = true;
    }

    function getLogicalWidth(idx) {
        if (idx < 0 || idx >= monModel.count) return 0;
        let m = monModel.get(idx);
        let isPortrait = (m.rotationType.includes("90") || m.rotationType.includes("270"));
        return isPortrait ? m.h : m.w;
    }

    function getLogicalHeight(idx) {
        if (idx < 0 || idx >= monModel.count) return 0;
        let m = monModel.get(idx);
        let isPortrait = (m.rotationType.includes("90") || m.rotationType.includes("270"));
        return isPortrait ? m.w : m.h;
    }

    function applyTopology() {
        let randrCmds = [];
        let hyprLines = [];
        for (let i = 0; i < monModel.count; i++) {
            let m = monModel.get(i);
            randrCmds.push(`--output "${m.name}" --mode "${m.currentRes}" --pos "${m.x},${m.y}" --transform "${m.rotationType}"`);
            let transformID = getHyprTransform(m.rotationType);
            hyprLines.push(`monitor=${m.name},${m.currentRes},${m.x}x${m.y},1,transform,${transformID}`);
        }
        executor.command = ["/usr/bin/sh", "-c", "/usr/bin/wlr-randr " + randrCmds.join(" ")];
        executor.running = true;
        let saveFileCmd = `echo -e "# Autogenerated by MonitorManager\n${hyprLines.join('\n')}" > ~/.config/hypr/monitors.conf`;
        saver.command = ["/usr/bin/sh", "-c", saveFileCmd];
        saver.running = true;
    }

    Process {
        id: scanner; command: ["/usr/bin/wlr-randr"]
        stdout: SplitParser {
            onRead: (line) => {
                let t = line.trim();
                if (t.length > 0 && !line.startsWith(" ")) {
                    let name = t.split(' ')[0]; activeMon = name; rawResData[name] = [];
                    monModel.append({name: name, x: 0, y: 0, w: 1920, h: 1080, currentRes: "", rotationType: "normal"});
                } else if (activeMon !== "" && /^\d+x\d+/.test(t)) {
                    rawResData[activeMon].push(t);
                    for(let i=0; i<monModel.count; i++) {
                        let m = monModel.get(i);
                        if(m.name === activeMon && m.currentRes === "") {
                            let res = t.split(/[\s,]+/)[0].replace("px", "");
                            m.currentRes = res; m.w = parseInt(res.split('x')[0]); m.h = parseInt(res.split('x')[1]);
                        }
                    }
                }
            }
        }
    }
    Process { id: executor; onExited: (code) => { if(code === 0) hasChanges = false; } }
    Process { 
        id: saver 
        onExited: (code) => { if (code === 0) console.log("Hyprland config updated."); }
    }
    Component.onCompleted: scanner.running = true;
}