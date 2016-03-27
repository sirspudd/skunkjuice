TARGET = pi-compositor

QT += gui qml

SOURCES += \
    src/main.cpp

RESOURCES += pi-compositor.qrc

target.path = /tmp
INSTALLS += target
