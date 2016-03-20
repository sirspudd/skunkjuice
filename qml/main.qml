/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt-project.org/legal
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
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

import QtQuick 2.0
import QtWayland.Compositor 1.0

WaylandCompositor {
    id: comp

    property var windows: []
    property int activeWindowIndex: -1
    property var surfaceMap

    function relayoutWindows() {
        windows.forEach(function(w,i) { w.x = (i-activeWindowIndex)*w.width; } )
        windows[activeWindowIndex].takeFocus()
    }

    function addWindow(item) {
        windows.push(item)
        activeWindowIndex = windows.length - 1
        relayoutWindows();
    }

    function removeWindow(item) {
        var index = windows.indexOf(item)
        if (index != -1)
        {
            windows.splice(index, 1);
            if (activeWindowIndex == index) activeWindowIndex = 0
            relayoutWindows();
        }
    }

    function moveLeft() {
        activeWindowIndex = Math.max(activeWindowIndex - 1, 0);
        relayoutWindows()
    }

    function moveRight() {
        activeWindowIndex = Math.min(activeWindowIndex + 1, windows.length - 1);
        relayoutWindows()
    }

    Item {
        id: keyhandler
        Keys.onPressed: {
            if (event.key == Qt.Key_Left) {
                moveLeft()
                event.accepted = true;
            } else if (event.key == Qt.Key_Right) {
                moveRight()
                event.accepted = true;
            }
        }
    }

    Screen {
        compositor: comp
    }

    Component {
        id: chromeComponent
        Chrome {
        }
    }

    Component {
        id: surfaceComponent
        WaylandSurface {
        }
    }

    extensions: [
        Shell {
            id: defaultShell

            onCreateShellSurface: {
                var item = chromeComponent.createObject(defaultOutput.surfaceArea, { "surface": surface } );
                item.shellSurface.initialize(defaultShell, surface, resource);
                item.visibleChanged.connect(function() { item.visible ? addWindow(item) : removeWindow(item) } )
                item.surfaceDestroyed.connect(function() { removeWindow(item) })
            }

            Component.onCompleted: {
                initialize();
            }
        }
    ]

    onCreateSurface: {
        var surface = surfaceComponent.createObject(comp, { } );
        surface.initialize(comp, client, id, version);
    }
}
