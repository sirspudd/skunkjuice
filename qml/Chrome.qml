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

ShellSurfaceItem {
    id: rootChrome

    signal destructionComplete;

    visible: false

    function appear() {
        creationAnimation.start()
    }

    function vanish() {
        bufferLocked = true;
        visible ? destroyAnimation.start() : 0
    }

    onVisibleChanged: visible ? appear() : vanish()

    onWidthChanged: {
        if (width == -1) {
            visible = false
        } else {
            rootChrome.shellSurface.sendConfigure(globalUtil.clientSize(), 0)
            width = compositorWindow.width
            height = compositorWindow.height
            visible = true
        }
    }

    onSurfaceDestroyed: {
        vanish();
    }

    Connections {
        target: shellSurface

        // some signals are not available on wl_shell, so let's ignore them
        ignoreUnknownSignals: true

        onActivatedChanged: { // xdg_shell only
            if (shellSurface.activated) {
                receivedFocusAnimation.start();
            }
        }
    }

    /* divide by zero!
    Behavior on x {
        SpringAnimation { spring: 2; damping: 0.2; duration: 150 }
    }*/

    Behavior on x {
        SmoothedAnimation { duration: 150 }
    }

    SequentialAnimation {
        id: creationAnimation

        PropertyAction { target: scaleTransform; property: "xScale"; value: 0.0 }
        PropertyAction { target: scaleTransform; property: "yScale"; value: 2/height }
        NumberAnimation { target: scaleTransform; property: "xScale"; to: 0.4; duration: 150 }
        ParallelAnimation {
            NumberAnimation { target: scaleTransform; property: "yScale"; to: 1; duration: 150 }
            NumberAnimation { target: scaleTransform; property: "xScale"; to: 1; duration: 150 }
        }
    }

    SequentialAnimation {
        id: destroyAnimation
        ParallelAnimation {
            NumberAnimation { target: scaleTransform; property: "yScale"; to: 2/height; duration: 150 }
            NumberAnimation { target: scaleTransform; property: "xScale"; to: 0.4; duration: 150 }
        }
        NumberAnimation { target: scaleTransform; property: "xScale"; to: 0; duration: 150 }
        ScriptAction { script: { destructionComplete(); rootChrome.destroy(); } }
    }

    transform: [
        Scale {
            id:scaleTransform
            origin.x: rootChrome.width / 2
            origin.y: rootChrome.height / 2
        }
    ]

    Keys.forwardTo: uberItem
}
