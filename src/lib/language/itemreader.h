/****************************************************************************
**
** Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the Qt Build Suite.
**
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Digia.  For licensing terms and
** conditions see http://qt.digia.com/licensing.  For further information
** use the contact form at http://qt.digia.com/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL included in the
** packaging of this file.  Please review the following information to
** ensure the GNU Lesser General Public License version 2.1 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** In addition, as a special exception, Digia gives you certain additional
** rights.  These rights are described in the Digia Qt LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
****************************************************************************/

#ifndef QBS_ITEMREADER_H
#define QBS_ITEMREADER_H

#include "forward_decls.h"
#include <logging/logger.h>

#include <QStringList>

namespace qbs {
namespace Internal {

class BuiltinDeclarations;

/*
 * Reads a qbs file and creates a tree of Item objects.
 *
 * In this stage the following steps are performed:
 *    - The QML/JS parser creates the AST.
 *    - The AST is converted to a tree of Item objects.
 *
 * This class is also responsible for the QMLish inheritance semantics.
 */
class ItemReader
{
public:
    ItemReader(BuiltinDeclarations *builtins, const Logger &logger);

    BuiltinDeclarations *builtins() const { return m_builtins; }
    const Logger *logger() const { return &m_logger; }

    void setSearchPaths(const QStringList &searchPaths);
    const QStringList &searchPaths() const { return m_searchPaths; }

    ItemPtr readFile(const QString &filePath, bool inRecursion = false);

private:
    BuiltinDeclarations *m_builtins;
    Logger m_logger;
    QStringList m_searchPaths;
};

} // namespace Internal
} // namespace qbs

#endif // QBS_ITEMREADER_H