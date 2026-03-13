pragma Singleton
import QtQuick

QtObject {
    // --- 1. CORE BRANDING ---
    readonly property color amber: "#e1c62c"
    readonly property color circuitBlue: "#004466"
    readonly property color cyberGrape: "#582fba"
    readonly property color matrixGreen: "#00FF41"
    
    // --- 2. SURFACES & CONTAINERS ---
    readonly property color bgDark: "#080808"
    readonly property color glass: "#E6000000"       // 90% Opacity
    readonly property color glassLight: "#4D000000"  // 30% Opacity
    readonly property color panelBorder: "#333333"
    
    // --- 3. DYNAMIC STATES ---
    readonly property color hoverTint: Qt.rgba(amber.r, amber.g, amber.b, 0.12)
    readonly property color pressedTint: Qt.rgba(amber.r, amber.g, amber.b, 0.25)
    readonly property color highlightBorder: amber
    readonly property real activeOpacity: 1.0
    readonly property real inactiveOpacity: 0.6
    
    // --- 4. STATUS COLORS ---
    readonly property color alert: "#FF3333"
    readonly property color warning: "#ffcc00"
    readonly property color success: "#00ff88"
    readonly property color inactive: "#555555"

    // --- 5. TYPOGRAPHY PALETTE ---
    readonly property color textMain: "#ffffff"
    readonly property color textSecondary: "#aaaaaa"
    readonly property color textDim: "#666666"

    // --- 6. GEOMETRY & SHAPES ---
    readonly property int cornerRadius: 0
    readonly property int borderWidth: 1
    readonly property int panelPadding: 10
    readonly property int moduleSpacing: 12
    readonly property int barHeight: 4
    
    // --- 7. TYPOGRAPHY SETTINGS ---
    readonly property string fontFamily: "Monospace"
    readonly property int fontSizeTiny: 8
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeMed: 12
    readonly property int fontSizeLarge: 14
    readonly property real fontLetterSpacing: 0.5
    
    // --- 8. EFFECTS & ANIMATION ---
    readonly property color mainGlow: Qt.rgba(amber.r, amber.g, amber.b, 0.3)
    readonly property int animSpeed: 200
    readonly property var defaultEasing: Easing.OutQuart
    
    // --- 9. GLOBAL LOGIC HELPERS ---
    function getLoadColor(load) {
        let val = parseInt(load);
        if (val >= 90) return alert;
        if (val >= 70) return warning;
        return amber;
    }

    function getStorageColor(percent) {
        let val = parseInt(percent.replace('%',''));
        return val > 90 ? alert : (val > 70 ? warning : amber);
    }

    // --- 10. BUTTON STYLES ---
    readonly property int btnWidth: 52
    readonly property int btnHeight: 20
    
    function getBtnBg(isHovered) { return isHovered ? amber : bgDark; }
    function getBtnText(isHovered) { return isHovered ? bgDark : amber; }
    function getBtnBorder(isHovered) { return amber; }

    // --- 11. TRIGGER BUTTON SPECIAL STYLES ---
    readonly property int triggerSize: 70
    readonly property int triggerRotation: 45
    readonly property int triggerTextRotation: -45
    readonly property real triggerOpacity: 0.9
    
    function getTriggerBg(isOpen) { return isOpen ? amber : bgDark; }
    function getTriggerText(isOpen) { return isOpen ? bgDark : amber; }
}