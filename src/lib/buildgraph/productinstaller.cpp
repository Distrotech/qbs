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
#include "productinstaller.h"

#include "artifact.h"
#include "buildproduct.h"
#include "buildproject.h"
#include "rulesevaluationcontext.h"
#include <language/language.h>
#include <logging/logger.h>
#include <logging/translator.h>
#include <tools/error.h>
#include <tools/fileinfo.h>
#include <tools/progressobserver.h>

#include <QDir>
#include <QFileInfo>

namespace qbs {
namespace Internal {

ProductInstaller::ProductInstaller(const QList<BuildProductPtr> &products,
                                   const InstallOptions &options, ProgressObserver *observer)
    : m_products(products), m_options(options), m_observer(observer)
{
    if (!m_options.installRoot.isEmpty()) {
        if (m_options.removeFirst) {
            const QString cfp = QFileInfo(m_options.installRoot).canonicalFilePath();
            if (cfp == QFileInfo(QDir::rootPath()).canonicalFilePath())
                throw Error(Tr::tr("Refusing to remove root directory."));
            if (cfp == QFileInfo(QDir::homePath()).canonicalFilePath())
                throw Error(Tr::tr("Refusing to remove home directory."));
        }
        return;
    }

    if (m_products.isEmpty())
        throw Error(Tr::tr("Cannot deduce install root, because there are no products."));

    const BuildProductConstPtr &product = m_products.first();
    m_options.installRoot = product->rProduct->properties
            ->qbsPropertyValue(QLatin1String("sysroot")).toString();
    if (m_options.installRoot.isEmpty()) {
        m_options.installRoot = product->project->resolvedProject()->buildDirectory
                + QLatin1Char('/') + InstallOptions::defaultInstallRoot();
    } else if (m_options.removeFirst) {
        throw Error(Tr::tr("Refusing to remove sysroot."));
    }
}

void ProductInstaller::install()
{
    if (m_options.removeFirst)
        removeInstallRoot();

    QList<const Artifact *> artifactsToInstall;
    foreach (const BuildProductConstPtr &product, m_products) {
        foreach (const Artifact *artifact, product->artifacts) {
            if (artifact->properties->qbsPropertyValue(QLatin1String("install")).toBool())
                artifactsToInstall += artifact;
        }
    }
    m_observer->initialize(Tr::tr("Installing"), artifactsToInstall.count());

    foreach (const Artifact * const a, artifactsToInstall) {
        copyFile(a);
        m_observer->incrementProgressValue();
    }
}

void ProductInstaller::removeInstallRoot()
{
    if (m_options.dryRun) {
        qbsInfo() << Tr::tr("Would remove install root '%1'.").arg(m_options.installRoot);
        return;
    }
    QString errorMessage;
    if (!removeDirectoryWithContents(m_options.installRoot, &errorMessage)) {
        const QString fullErrorMessage = Tr::tr("Cannot remove install root '%1': %2")
                .arg(QDir::toNativeSeparators(m_options.installRoot), errorMessage);
        handleError(fullErrorMessage);
    }
}

void ProductInstaller::copyFile(const Artifact *artifact)
{
    if (m_observer->canceled())
        throw Error(Tr::tr("Installation canceled due to user request."));
    const QString relativeInstallDir
            = artifact->properties->qbsPropertyValue(QLatin1String("installDir")).toString();
    QString targetDir = m_options.installRoot;
    targetDir.append(QLatin1Char('/')).append(relativeInstallDir);
    if (m_options.dryRun) {
        qbsInfo() << Tr::tr("Would copy file '%1' into target directory '%2'.")
                     .arg(QDir::toNativeSeparators(artifact->filePath()), targetDir);
        return;
    }

    if (!QDir::root().mkpath(targetDir)) {
        handleError(Tr::tr("Directory '%1' could not be created.")
                    .arg(QDir::toNativeSeparators(targetDir)));
        return;
    }
    const QString targetFilePath
            = targetDir + QLatin1Char('/') + FileInfo::fileName(artifact->filePath());
    QString errorMessage;
    if (!copyFileRecursion(artifact->filePath(), targetFilePath, &errorMessage))
        handleError(Tr::tr("Installation error: %1").arg(errorMessage));
}

void ProductInstaller::handleError(const QString &message)
{
    if (!m_options.keepGoing)
        throw Error(message);
    qbsWarning() << message;
}

} // namespace Internal
} // namespace qbs