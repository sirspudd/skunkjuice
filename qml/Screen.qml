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

import QtQuick 2.5
import QtQuick.Window 2.2
import QtWayland.Compositor 1.0

WaylandOutput {
    id: output

    window: Window {
        visible:true

        Image {
          id: background
          //source: "qrc:/resources/heic0707a.png"
          Item {
              id: topItem

              property var zoomScale: 1

              function zoomOut() {
                  zoomScale = 0.75
                  zoomOutAnimation.start()
              }

              function zoomIn() {
                  zoomScale =  1.00
                  zoomInAnimation.start()
              }

              width: childrenRect.width
              height: childrenRect.height
              Component.onCompleted: uberItem = this

              Behavior on x {
                  SmoothedAnimation { duration: 150 }
              }

              SequentialAnimation {
                  id: zoomOutAnimation
                  ParallelAnimation {
                      NumberAnimation { target: scaleTransform; property: "yScale"; to: topItem.zoomScale; duration: 150 }
                      NumberAnimation { target: scaleTransform; property: "xScale"; to: topItem.zoomScale; duration: 150 }
                  }
              }

              SequentialAnimation {
                  id: zoomInAnimation
                  ParallelAnimation {
                      NumberAnimation { target: scaleTransform; property: "yScale"; to: topItem.zoomScale; duration: 150 }
                      NumberAnimation { target: scaleTransform; property: "xScale"; to: topItem.zoomScale; duration: 150 }
                  }
              }

              transform: [
                  Scale {
                      id:scaleTransform
                      origin.x: activeWindowIndex*waylandScreen.width + waylandScreen.width/2
                      origin.y: waylandScreen.height/2
                  }
              ]
          }
        }

        Shortcut {
            sequence: "Ctrl+Alt+Backspace"
            onActivated: Qt.quit()
        }

        Component.onCompleted: waylandScreen = this
    }
}
