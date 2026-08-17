// Frosted-glass panel: the wallpaper behind this item, blurred, tinted and
// clipped to a rounded rectangle. `backdrop` is the wallpaper item; this item
// may sit up to two levels below it (frame → hud → Glass).
import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: glass
    property Item backdrop
    property real radius: 16
    property color tint: "#40ffffff"
    property real blur: 48
    property color borderColor: "#66ffffff"
    property int borderWidth: 1
    property bool highlight: true          // faint light edge along the top

    // position in backdrop coordinates; depends on our own and our parent's x/y so it
    // follows animations (the shake) and layout changes
    readonly property point origin: {
        var dep = x + y + (parent ? parent.x + parent.y : 0)
        return backdrop ? mapToItem(backdrop, 0, 0) : Qt.point(0, 0)
    }

    ShaderEffectSource {
        id: src
        sourceItem: glass.backdrop
        sourceRect: Qt.rect(glass.origin.x, glass.origin.y, glass.width, glass.height)
        visible: false
        smooth: true
    }
    FastBlur { id: blurred; anchors.fill: parent; source: src; radius: glass.blur; visible: false }
    Rectangle { id: mask; anchors.fill: parent; radius: glass.radius; visible: false }
    OpacityMask { anchors.fill: parent; source: blurred; maskSource: mask; visible: glass.backdrop !== null && glass.blur > 0 }
    Rectangle {
        anchors.fill: parent
        radius: glass.radius
        color: glass.tint
        border.width: glass.borderWidth
        border.color: glass.borderColor
        Behavior on color { ColorAnimation { duration: 160 } }
    }
    Rectangle {   // top highlight
        visible: glass.highlight
        anchors { top: parent.top; topMargin: 1; horizontalCenter: parent.horizontalCenter }
        width: parent.width - 2 * glass.radius; height: 1
        color: "#55ffffff"
    }
}
