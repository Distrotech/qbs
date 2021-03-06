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
#ifndef QBS_SETUP_ANDROID_COMMANDLINEPARSER_H
#define QBS_SETUP_ANDROID_COMMANDLINEPARSER_H

#include <QStringList>

class CommandLineParser
{
public:
    CommandLineParser();

    void parse(const QStringList &commandLine);

    bool helpRequested() const { return m_helpRequested; }

    QString sdkDir() const { return m_sdkDir; }
    QString ndkDir() const { return m_ndkDir; }
    QString profileName() const { return m_profileName; }
    QString settingsDir() const { return m_settingsDir; }

    QString usageString() const;

private:
    Q_NORETURN void throwError(const QString &message);
    void assignOptionArgument(const QString &option, QString &argument);
    Q_NORETURN void complainAboutExtraArguments();

    bool m_helpRequested;
    QString m_sdkDir;
    QString m_ndkDir;
    QString m_profileName;
    QString m_settingsDir;
    QStringList m_commandLine;
    QString m_command;
};

#endif // Include guard.
