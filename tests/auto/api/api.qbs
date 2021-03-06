import qbs

QbsAutotest {
    testName: "api"
    files: ["../shared.h", "tst_api.h", "tst_api.cpp"]
    cpp.defines: base.concat([
        'SRCDIR="' + path + '"',
        'QBS_RELATIVE_SEARCH_PATH="' + project.relativeSearchPath + '"',
        'QBS_RELATIVE_PLUGINS_PATH="' + project.relativePluginsPath + '"'
    ]).concat(project.enableProjectFileUpdates ? ["QBS_ENABLE_PROJECT_FILE_UPDATES"] : [])
}
