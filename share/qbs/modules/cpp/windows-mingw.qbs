import qbs.base 1.0
import qbs.fileinfo 1.0 as FileInfo
import '../utils.js' as ModUtils

GenericGCC {
    condition: qbs.targetOS == "windows" && qbs.toolchain == "mingw"
}

