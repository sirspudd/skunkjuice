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

#include <unistd.h>

#include <QtCore/QUrl>
#include <QtCore/QDebug>

#include <QtGui/QGuiApplication>

#include <QtQml/QQmlApplicationEngine>

#include <QQmlContext>

#include <QSurfaceFormat>

#include <QTimer>
#include <QNetworkInterface>
#include <QHostAddress>

class NativeUtil : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString ipAddress MEMBER ipAddress NOTIFY ipAddressChanged)

public:
    NativeUtil()
        : QObject()
    {
        establishIpAddress();
    }

Q_SIGNALS:
    void ipAddressChanged();

public Q_SLOTS:
    void establishIpAddress()
    {
        bool ifUp = false;
        bool validIP = false;

        foreach (const QNetworkInterface &interface, QNetworkInterface::allInterfaces()) {
            if ((interface.flags() & QNetworkInterface::IsUp)
                    && (interface.flags() & QNetworkInterface::IsRunning)
                    && !(interface.flags() & QNetworkInterface::IsLoopBack)) {
                ifUp = true;
                qDebug() << "Established network interface" << interface.name() << "is up and ready to be queried";
            }
        }

        if (ifUp) {
            foreach (const QHostAddress &address, QNetworkInterface::allAddresses()) {
                if (address.protocol() == QAbstractSocket::IPv4Protocol && address != QHostAddress(QHostAddress::LocalHost)) {
                    validIP = true;
                    ipAddress = address.toString();
                    emit ipAddressChanged();
                    continue;
                }
            }
        }

        if (!validIP) {
            QTimer::singleShot(1000, this, &NativeUtil::establishIpAddress);
            return;
        }
    }

private:
    QString ipAddress;
};

int main(int argc, char *argv[])
{
    QSurfaceFormat format = QSurfaceFormat::defaultFormat();
    format.setAlphaBufferSize(0);
    format.setRedBufferSize(8);
    format.setGreenBufferSize(8);
    format.setBlueBufferSize(8);
    format.setSwapBehavior(QSurfaceFormat::TripleBuffer);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);
    app.setOrganizationName("Chaos Reins");

    NativeUtil nativeUtils;

    QQmlApplicationEngine appEngine;
    appEngine.rootContext()->setContextProperty("nativeUtils", &nativeUtils);
    appEngine.addImportPath("qrc:///qml");
    appEngine.load(QUrl("qrc:///qml/main.qml"));

    return app.exec();
}

#include "main.moc"
