!isEmpty(QBS_RESOURCES_BUILD_DIR) {
    destdirPrefix = $${QBS_RESOURCES_BUILD_DIR}
} else {
    greaterThan(QT_MAJOR_VERSION, 4): \
        destdirPrefix = $$shadowed($$PWD)/../..
    else: \
        destdirPrefix = ../../../.. # Note: Will break if pri file is included from some other place
}
DESTDIR = $${destdirPrefix}/plugins
TEMPLATE = lib

CONFIG += depend_includepath
unix: CONFIG += plugin

!isEmpty(QBS_RESOURCES_INSTALL_DIR): \
    installPrefix = $${QBS_RESOURCES_INSTALL_DIR}
else: \
    installPrefix = $${QBS_INSTALL_PREFIX}
target.path = $${installPrefix}/plugins
INSTALLS += target
