/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing
**
** This file is part of the Qt Build Suite.
**
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms and
** conditions see http://www.qt.io/terms-conditions. For further information
** use the contact form at http://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 or version 3 as published by the Free
** Software Foundation and appearing in the file LICENSE.LGPLv21 and
** LICENSE.LGPLv3 included in the packaging of this file.  Please review the
** following information to ensure the GNU Lesser General Public License
** requirements will be met: https://www.gnu.org/licenses/lgpl.html and
** http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, The Qt Company gives you certain additional
** rights.  These rights are described in The Qt Company LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
****************************************************************************/

import qbs
import qbs.File
import qbs.FileInfo
import qbs.ModUtils
import qbs.TextFile

import "utils.js" as NdkUtils

Module {
    Depends { name: "cpp" }

    property string abi // Corresponds to the subdir under "lib/" in the apk file.

    property string appStl: "system"
    PropertyOptions {
        name: "stlType"
        description: "Corresponds to the 'APP_STL' variable in an Android.mk file."
        allowedValues: [
            "system", "gabi++_static", "gabi++_shared", "stlport_static", "stlport_shared",
            "gnustl_static", "gnustl_shared", "c++_static", "c++_shared"
        ]
    }

    property string buildProfile // E.g. "armeabi-v7a-hard"
    property bool enableExceptions: appStl !== "system"
    property bool enableRtti: appStl !== "system"
    property string ndkDir
    property string platform: "android-9"

    // Internal properties.
    property stringList compilerFlagsDebug: []
    property stringList compilerFlagsRelease: []
    property stringList defines: ["ANDROID"]
    property bool hardFp
    property string cxxStlBaseDir: FileInfo.joinPaths(ndkDir, "sources/cxx-stl")
    property string gabiBaseDir: FileInfo.joinPaths(cxxStlBaseDir, "gabi++")
    property string stlPortBaseDir: FileInfo.joinPaths(cxxStlBaseDir, "stlport")
    property string gnuStlBaseDir: FileInfo.joinPaths(cxxStlBaseDir, "gnu-libstdc++/4.9")
    property string llvmStlBaseDir: FileInfo.joinPaths(cxxStlBaseDir, "llvm-libc++")
    property string stlBaseDir: {
        if (appStl.startsWith("gabi++_"))
            return gabiBaseDir;
        else if (appStl.startsWith("stlport_"))
            return stlPortBaseDir;
        else if (appStl.startsWith("gnustl_"))
            return gnuStlBaseDir;
        else if (appStl.startsWith("c++_"))
            return llvmStlBaseDir;
        return undefined;
    }
    property string stlLibsDir: {
        if (stlBaseDir) {
            var infix = buildProfile;
            if (armMode === "thumb")
                infix = FileInfo.joinPaths(infix, "thumb");
            return FileInfo.joinPaths(stlBaseDir, "libs", infix);
        }
        return undefined;
    }

    property string sharedStlFilePath: (stlLibsDir && appStl.endsWith("_shared"))
        ? FileInfo.joinPaths(stlLibsDir, cpp.dynamicLibraryPrefix + appStl + cpp.dynamicLibrarySuffix)
        : undefined
    property string staticStlFilePath: (stlLibsDir && appStl.endsWith("_static"))
        ? FileInfo.joinPaths(stlLibsDir, cpp.staticLibraryPrefix + appStl + cpp.staticLibrarySuffix)
        : undefined

    property string gdbserverFileName: "gdbserver"

    property string armMode: abi.startsWith("armeabi")
            ? (qbs.buildVariant === "debug" ? "arm" : "thumb")
            : undefined;
    PropertyOptions {
        name: "armModeType"
        description: "Determines the instruction set for armeabi configurations."
        allowedValues: ["arm", "thumb"]
    }

    cpp.commonCompilerFlags: {
        var flags = qbs.buildVariant === "debug"
                ? compilerFlagsDebug : compilerFlagsRelease;
        if (armMode)
            flags.push("-m" + armMode);
        return flags;
    }

    cpp.cxxFlags: {
        var flags = [];
        if (enableExceptions)
            flags.push("-fexceptions");
        else
            flags.push("-fno-exceptions");
        if (enableRtti)
            flags.push("-frtti");
        else
            flags.push("-fno-rtti");
        return flags;
    }

    cpp.libraryPaths: {
        var prefix = FileInfo.joinPaths(cpp.sysroot, "usr");
        var paths = [];
        if (buildProfile === "mips64" || buildProfile === "x86_64") // no lib64 for arm64-v8a
            paths.push(FileInfo.joinPaths(prefix, "lib64"));
        paths.push(FileInfo.joinPaths(prefix, "lib"));
        return paths;
    }

    cpp.dynamicLibraries: {
        var libs = ["c"];
        if (!hardFp)
            libs.push("m");
        if (sharedStlFilePath)
            libs.push(sharedStlFilePath);
        return libs;
    }
    cpp.staticLibraries: {
        var libs = ["gcc"];
        if (hardFp)
            libs.push("m_hard");
        if (staticStlFilePath)
            libs.push(staticStlFilePath);
        return libs;
    }
    cpp.systemIncludePaths: {
        var includes = [];
        if (appStl === "system") {
            includes.push(FileInfo.joinPaths(cxxStlBaseDir, "system", "include"));
        } else if (appStl.startsWith("gabi++")) {
            includes.push(FileInfo.joinPaths(gabiBaseDir, "include"));
        } else if (appStl.startsWith("stlport")) {
            includes.push(FileInfo.joinPaths(stlPortBaseDir, "stlport"));
        } else if (appStl.startsWith("gnustl")) {
            includes.push(FileInfo.joinPaths(gnuStlBaseDir, "include"));
            includes.push(FileInfo.joinPaths(gnuStlBaseDir, "libs", buildProfile, "include"));
            includes.push(FileInfo.joinPaths(gnuStlBaseDir, "include", "backward"));
        } else if (appStl.startsWith("c++_")) {
            includes.push(FileInfo.joinPaths(llvmStlBaseDir, "libcxx", "include"));
            includes.push(FileInfo.joinPaths(llvmStlBaseDir + "abi", "libcxxabi", "include"));
        }
        return includes;
    }
    cpp.defines: {
        var list = defines;
        if (hardFp)
            list.push("_NDK_MATH_NO_SOFTFP=1");
        return list;
    }
    cpp.sysroot: FileInfo.joinPaths(ndkDir, "platforms", platform,
                                    "arch-" + NdkUtils.abiNameToDirName(abi))

    Rule {
        inputs: ["dynamiclibrary"]
        outputFileTags: ["android.nativelibrary", "android.gdbserver-info", "android.stl-info"]
        outputArtifacts: {
            var artifacts = [{
                    filePath: FileInfo.joinPaths("stripped-libs",
                                                 inputs["dynamiclibrary"][0].fileName),
                    fileTags: ["android.nativelibrary"]
            }];
            if (product.moduleProperty("qbs", "buildVariant") === "debug") {
                artifacts.push({
                        filePath: "android.gdbserver-info.txt",
                        fileTags: ["android.gdbserver-info"]
                });
            }
            var stlFilePath = ModUtils.moduleProperty(product, "sharedStlFilePath");
            if (stlFilePath)
                artifacts.push({filePath: "android.stl-info.txt", fileTags: ["android.stl-info"]});
            return artifacts;
        }

        prepare: {
            var stlFilePath = ModUtils.moduleProperty(product, "sharedStlFilePath");
            var copyCmd = new JavaScriptCommand();
            copyCmd.silent = true;
            copyCmd.stlFilePath = stlFilePath;
            copyCmd.sourceCode = function() {
                File.copy(inputs["dynamiclibrary"][0].filePath,
                          outputs["android.nativelibrary"][0].filePath);
                var destDir = FileInfo.joinPaths("lib", ModUtils.moduleProperty(product, "abi"));
                if (product.moduleProperty("qbs", "buildVariant") === "debug") {
                    var arch = ModUtils.moduleProperty(product, "abi");
                    arch = NdkUtils.abiNameToDirName(arch);
                    var srcPath = FileInfo.joinPaths(ModUtils.moduleProperty(product, "ndkDir"),
                            "prebuilt/android-" + arch, "gdbserver/gdbserver");
                    var targetPath = FileInfo.joinPaths(destDir, ModUtils.moduleProperty(product,
                            "gdbserverFileName"));
                    var infoFile = new TextFile(outputs["android.gdbserver-info"][0].filePath,
                                                TextFile.WriteOnly);
                    infoFile.writeLine(srcPath);
                    infoFile.writeLine(targetPath);
                    infoFile.close();
                }
                if (stlFilePath) {
                    var srcPath = stlFilePath;
                    var targetPath = FileInfo.joinPaths(destDir, FileInfo.fileName(srcPath));
                    var infoFile = new TextFile(outputs["android.stl-info"][0].filePath,
                                                TextFile.WriteOnly);
                    infoFile.writeLine(srcPath);
                    infoFile.writeLine(targetPath);
                    infoFile.close();
                }
            }
            var stripBinary = product.moduleProperty("cpp", "toolchainPathPrefix") + "strip";
            var stripArgs = ["--strip-unneeded", outputs["android.nativelibrary"][0].filePath];
            if (stlFilePath)
                stripArgs.push(stlFilePath);
            var stripCmd = new Command(stripBinary, stripArgs);
            stripCmd.description = "Stripping unneeded symbols from "
                    + outputs["android.nativelibrary"][0].fileName;
            return [copyCmd, stripCmd];
        }
    }
}
