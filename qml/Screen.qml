/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: http://www.qt-project.org/legal
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.5
import QtQuick.Window 2.2
import QtWayland.Compositor 1.0

WaylandOutput {
    id: output

    sizeFollowsWindow: true
    window: Window {
        id: screen

        color: "black"
        visibility: Window.FullScreen

        Item {
            id: clock
            anchors.fill: parent
            visible: !animatedBackground.visible

            property string timeString

            function timeChanged() {
                var date = new Date;
                clock.timeString = Qt.formatDateTime(date, "hh:mm:ss")
            }

            Text {
                anchors.centerIn: parent
                font.pixelSize: screen.height/4
                font.bold: true
                color: "white"
                text: clock.timeString
            }

            Timer {
                interval: 1000; running: true; repeat: true;
                onTriggered: clock.timeChanged()
            }
        }

        Item {
            id: animatedBackground
            anchors.fill: parent

            visible: settings.animatedBackground

            BackgroundSwirls {
                anchors.fill: parent
                opacity: 1.0 - parlourTrickCurtain.opacity
                visible: opacity > 0.2
            }

            Rectangle {
                id: parlourTrickCurtain
                anchors.fill: parent
                color: "black"
                opacity: topItem.width < compositorWindow.width ? 0.0 : 1.0
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
        }

        WaylandMouseTracker {
            id: mouseTracker
            anchors.fill: parent
            windowSystemCursorEnabled: true

            Item {
                id: topItem

                QtObject {
                    id: d
                    property var windows: []
                    property int activeWindowIndex: -1

                    property bool zoomed: false

                    function viewportX() {
                        return d.activeWindowIndex*compositorWindow.width;
                    }
                }

                function updateIndex() {
                    indexChangedAnimation.start()
                    d.windows.length ? d.windows[d.activeWindowIndex].takeFocus() : 0;
                }

                function toggleZoom() {
                    d.zoomed = !d.zoomed
                }

                function relayoutWindows() {
                    d.windows.forEach(function(w,i) {
                        w.y = (compositorWindow.height - w.height)/2;
                        w.x = i*compositorWindow.width + (compositorWindow.width - w.width)/2;
                    } )
                    updateIndex();
                }

                function addWindow(item) {
                    d.windows.push(item)
                    d.activeWindowIndex = d.windows.length - 1
                    relayoutWindows();
                    d.zoomed = false
                    item.widthChanged.connect(function() { relayoutWindows() })
                }

                function removeWindow(item) {
                    var index = d.windows.indexOf(item)
                    if (index != -1) {
                        d.windows.splice(index, 1);
                        if (d.activeWindowIndex == index) d.activeWindowIndex = 0
                        relayoutWindows();
                    }
                }

                function moveLeft() {
                    if (settings.wrapAroundNavigation) {
                        d.activeWindowIndex = d.activeWindowIndex == 0 ? d.windows.length - 1 : d.activeWindowIndex - 1
                    } else {
                        d.activeWindowIndex = Math.max(d.activeWindowIndex - 1, 0);
                    }
                    updateIndex()
                }

                function moveRight() {
                    if (settings.wrapAroundNavigation) {
                        d.activeWindowIndex = (d.activeWindowIndex + 1)%d.windows.length
                    } else {
                        d.activeWindowIndex = Math.min(d.activeWindowIndex + 1, d.windows.length - 1);
                    }
                    updateIndex()
                }

                width: childrenRect.width
                height: childrenRect.height
                Component.onCompleted: uberItem = this

                ParallelAnimation {
                    id: indexChangedAnimation
                    SmoothedAnimation {
                        target: scaleTransform;
                        property: "origin.x";
                        to: d.viewportX() + compositorWindow.width/2;
                        duration: 150 }
                    SmoothedAnimation {
                        target: topItem;
                        property: "x";
                        to: -d.viewportX();
                        duration: 150 }
                }

                states: State {
                    name: "zoomed"; when: d.zoomed
                    PropertyChanges { target: scaleTransform; xScale: 0.75; yScale: 0.75 }
                }

                transitions: Transition {
                    ParallelAnimation {
                        NumberAnimation { target: scaleTransform; property: "yScale"; duration: 150 }
                        NumberAnimation { target: scaleTransform; property: "xScale"; duration: 150 }
                    }
                }

                transform: [
                    Scale {
                        id:scaleTransform
                        origin.y: compositorWindow.height/2
                    }
                ]

                Keys.onPressed: {
                    // console.log('Received key press:' + event.key)
                    if (event.key == Qt.Key_Escape) {
                        toggleZoom()
                        event.accepted = true;
                    } else if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.AltModifier)) {
                        if (event.key == Qt.Key_Left) {
                            moveLeft()
                        } else if (event.key == Qt.Key_Right) {
                            moveRight()
                        } else if (event.key == Qt.Key_Up) {
                            d.windows[d.activeWindowIndex].surface.client.kill()
                        } else if (event.key == Qt.Key_Backspace) {
                            Qt.quit()
                        }
                    }

                    if(d.zoomed) {
                        if (event.key == Qt.Key_Left) {
                            moveLeft()
                        } else if (event.key == Qt.Key_Right) {
                            moveRight()
                        } else if (event.key == Qt.Key_Return
                                   || event.key == Qt.Key_Down) {
                            toggleZoom()
                        } else if (event.key == Qt.Key_Up) {
                            d.windows[d.activeWindowIndex].surface.client.kill()
                        } else if (event.key == Qt.Key_PageUp) {
                            d.windows[d.activeWindowIndex].opacity *= 1.10
                        } else if (event.key == Qt.Key_PageDown) {
                            d.windows[d.activeWindowIndex].opacity *= 0.90
                        }
                        event.accepted = true;
                    }
                }
            }
            Loader {
                anchors.fill: parent
                source: "Keyboard.qml"
            }
            WaylandCursorItem {
                id: cursor
                inputEventsEnabled: false
                x: mouseTracker.mouseX
                y: mouseTracker.mouseY

                seat: output.compositor.defaultSeat
            }
        }

        Component.onCompleted: compositorWindow = this
    }
}
