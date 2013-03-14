import "../autotest.qbs" as AutoTest

AutoTest {
    testName: "cmdlineparser"
    files: ["tst_cmdlineparser.cpp", "../../../src/app/qbs/qbstool.cpp"]
    cpp.defines: base.concat(['SRCDIR="' + path + '"', "QBS_VERSION=\"" + project.version + "\""])

    // TODO: Make parser a static library?
    Group {
        name: "parser"
        prefix: "../../../src/app/qbs/parser/"
        files: [
            "command.cpp",
            "command.h",
            "commandlineoption.cpp",
            "commandlineoption.h",
            "commandlineoptionpool.cpp",
            "commandlineoptionpool.h",
            "commandlineparser.cpp",
            "commandlineparser.h",
            "commandpool.cpp",
            "commandpool.h",
            "commandtype.h",
        ]
    }
}