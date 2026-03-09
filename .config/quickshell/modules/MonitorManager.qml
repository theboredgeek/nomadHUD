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

    ListModel { id: monModel }
    property var rawResData: ({}) 
    property string activeMon: ""
    property bool hasChanges: false

    // --- REUSABLE THEMED COMPONENTS ---
    
    component ThemedButton : Button {
        id: control
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        
        contentItem: Text {
            text: control.text
            font: control.font
            color: control.hovered ? Theme.bgDark : Theme.amber
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            implicitHeight: 30
            color: control.down ? Theme.pressedTint : (control.hovered ? Theme.amber : "transparent")
            border.color: Theme.amber
            border.width: Theme.borderWidth
            radius: Theme.cornerRadius
        }
    }

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
        spacing: Theme.moduleSpacing

        // --- THE TRIGGER BUTTON ---
        Rectangle {
            id: hexTrigger
            Layout.alignment: Qt.AlignHCenter
            width: 70; height: 70
            color: layoutPopup.opened ? Theme.amber : Theme.bgDark
            border.color: Theme.amber
            border.width: Theme.borderWidth + 1
            rotation: 45
            opacity: 0.9

            Text {
                anchors.centerIn: parent
                text: "DISP"
                color: layoutPopup.opened ? "black" : Theme.amber
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                rotation: -45 
            }

            MouseArea {
                anchors.fill: parent
                onClicked: layoutPopup.opened = !layoutPopup.opened
            }
        }

        // --- POPUP INTERFACE ---
        Rectangle {
            id: layoutPopup
            property bool opened: false
            visible: opened
            Layout.alignment: Qt.AlignHCenter
            
            width: 500
            height: Math.min(monitorManager.screen.height * 0.8, 800)
            color: Theme.glass
            border.color: Theme.amber
            border.width: Theme.borderWidth
            radius: Theme.cornerRadius

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 20; spacing: 15

                Text { 
                    text: "TOPOLOGY_CALIBRATION_V34"
                    color: Theme.amber
                    font.bold: true
                    font.letterSpacing: Theme.fontLetterSpacing
                    font.family: Theme.fontFamily
                }

                // Visual Topology Map
                Rectangle {
                    Layout.fillWidth: true; height: 200; color: Theme.bgDark; border.color: Theme.panelBorder; clip: true
                    
                    Repeater {
                        model: monModel
                        Rectangle {
                            width: getLogicalWidth(index) / 40
                            height: getLogicalHeight(index) / 40
                            x: 50 + (model.x / 40); y: 40 + (model.y / 40)
                            color: activeMon === name ? Theme.amber : Theme.glassLight
                            border.color: "white"; border.width: activeMon === name ? 2 : 1
                            
                            Text { 
                                anchors.centerIn: parent
                                color: activeMon === name ? "black" : "white"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall; text: name
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

                // Controls
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    ComboBox {
                        id: rotCombo
                        Layout.fillWidth: true
                        model: ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"]
                        font.family: Theme.fontFamily
                        
                        // Custom styling for ComboBox
                        contentItem: Text {
                            leftPadding: 10
                            text: rotCombo.displayText
                            font: rotCombo.font
                            color: Theme.amber
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: Theme.bgDark
                            border.color: Theme.amber
                            border.width: Theme.borderWidth
                        }
                        popup: Popup {
                            y: rotCombo.height
                            width: rotCombo.width
                            implicitHeight: contentItem.implicitHeight
                            padding: 1
                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: rotCombo.popup.visible ? rotCombo.delegateModel : null
                                ScrollIndicator.vertical: ScrollIndicator { }
                            }
                            background: Rectangle {
                                color: Theme.bgDark
                                border.color: Theme.amber
                            }
                        }
                        delegate: ItemDelegate {
                            width: rotCombo.width
                            contentItem: Text {
                                text: modelData
                                color: highlighted ? Theme.bgDark : Theme.amber
                                font: rotCombo.font
                            }
                            background: Rectangle {
                                color: highlighted ? Theme.amber : "transparent"
                            }
                        }

                        onActivated: (idx) => {
                            for(let i=0; i<monModel.count; i++) {
                                if(monModel.get(i).name === activeMon) {
                                    monModel.setProperty(i, "rotationType", textAt(idx));
                                    hasChanges = true;
                                }
                            }
                        }
                    }

                    ThemedButton { 
                        text: "STITCH"
                        onClicked: autoStitchLogic() 
                    }
                }

                ThemedButton { 
                    text: "APPLY & PERSIST"
                    Layout.fillWidth: true
                    highlighted: hasChanges
                    onClicked: applyTopology() 
                }

                // Resolution List
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; color: Theme.bgDark; border.color: Theme.panelBorder
                    ScrollView {
                        anchors.fill: parent; clip: true
                        Column {
                            width: parent.width
                            Repeater {
                                model: (activeMon !== "" && rawResData[activeMon]) ? rawResData[activeMon] : []
                                ThemedButton {
                                    width: parent.width
                                    text: modelData
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

    // Logic remains functional
    function autoStitchLogic() { 
        let currentX = 0;
        for (let i = 0; i < monModel.count; i++) {
            monModel.setProperty(i, "x", currentX);
            monModel.setProperty(i, "y", 0);
            currentX += getLogicalWidth(i);
        }
        hasChanges = true;
    }

    function getLogicalWidth(idx) {
        let m = monModel.get(idx);
        return (m.rotationType.includes("90") || m.rotationType.includes("270")) ? m.h : m.w;
    }
    
    function getLogicalHeight(idx) {
        let m = monModel.get(idx);
        return (m.rotationType.includes("90") || m.rotationType.includes("270")) ? m.w : m.h;
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
        let saveFileCmd = `echo -e "# Autogenerated\n${hyprLines.join('\n')}" > ~/.config/hypr/monitors.conf`;
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
    Process { id: saver; onExited: (code) => { if (code === 0) console.log("Hyprland config updated."); } }
    Component.onCompleted: scanner.running = true;
}