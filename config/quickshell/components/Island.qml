import QtQuick
import Quickshell.Widgets
import qs.config

// Pill-shaped container matching the Waybar island chrome.
WrapperRectangle {
    color: Appearance.colors.bgBar
    radius: Appearance.radius.island
    border.width: 1
    border.color: Appearance.colors.border
    leftMargin: Appearance.spacing.md
    rightMargin: Appearance.spacing.md
    implicitHeight: Appearance.bar.height
}
