import QtQuick 2.15
import org.kde.plasma.core 2.0 as PlasmaCore

Rectangle {
    width: 1920
    height: 1080
    color: "#0b0b0b"

    Image {
        anchors.centerIn: parent
        source: "logo.svg"
        width: 128
        height: 128
        smooth: true
    }

    PlasmaCore.BusyIndicator {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        anchors.topMargin: 96
        running: true
    }
}
