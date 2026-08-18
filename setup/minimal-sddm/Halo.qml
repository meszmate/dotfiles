// Dark halo for white text: a tight, dense ink shadow that outlines the glyphs
// so they read on light backdrops without touching the text colour itself.
// Use as `layer.effect: Halo {}`; `size` scales it for big type.
import QtQuick 2.15
import Qt5Compat.GraphicalEffects

DropShadow {
    property real size: 1
    transparentBorder: true
    radius:  Math.round(8 * size)
    samples: 2 * radius + 1
    spread:  0.35
    color:   alpha(cInk, textHalo)
    verticalOffset: Math.round(1 * size)
}
