// Soft ink-coloured shade tucked into one screen corner so white text stays
// legible where the artwork is light. `corner` is tl | tr | bl | br. The
// gradient reaches full transparency at the item's edges, so no box shows.
import QtQuick 2.15
import Qt5Compat.GraphicalEffects

RadialGradient {
    property string corner: "tr"
    property real strength: 0.4          // ink alpha at the very corner
    readonly property bool onRight:  corner.charAt(1) === "r"
    readonly property bool onBottom: corner.charAt(0) === "b"

    horizontalOffset: (onRight  ?  1 : -1) * width  / 2
    verticalOffset:   (onBottom ?  1 : -1) * height / 2
    horizontalRadius: width
    verticalRadius:   height
    gradient: Gradient {
        GradientStop { position: 0.0;  color: alpha(cInk, strength) }
        GradientStop { position: 0.35; color: alpha(cInk, strength * 0.6) }
        GradientStop { position: 0.7;  color: alpha(cInk, strength * 0.15) }
        GradientStop { position: 1.0;  color: alpha(cInk, 0) }
    }
}
