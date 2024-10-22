// SPDX-FileCopyrightText: 2023 UnionTech Software Technology Co., Ltd.
//
// SPDX-License-Identifier: GPL-3.0-or-later

#include "launcheritem.h"
#include "pluginfactory.h"
#include "../launchercontroller.h"
#include <blurhashimageprovider.h>

#include <QQueue>

#include <DDBusSender>

#include <applet.h>
#include <containment.h>
#include <appletbridge.h>
#include <pluginloader.h>
#include <dsglobal.h>
#include <qmlengine.h>

DS_USE_NAMESPACE

namespace dock {

LauncherItem::LauncherItem(QObject *parent)
    : DApplet(parent)
    , m_iconName("deepin-launcher")
    , m_appsModel(new DDEAppsModelProxy(this))
{

}

bool LauncherItem::init()
{
    DApplet::init();

    DQmlEngine().engine()->addImageProvider(QLatin1String("blurhash"), new BlurhashImageProvider);

    QDBusConnection connection = QDBusConnection::sessionBus();
    if (!connection.registerService(QStringLiteral("org.deepin.dde.Launcher1")) ||
        !connection.registerObject(QStringLiteral("/org/deepin/dde/Launcher1"), &LauncherController::instance())) {
        qWarning() << "register dbus service failed";
    }

    DAppletBridge bridge("org.deepin.ds.dde-apps");
    DAppletProxy * amAppsProxy = bridge.applet();

    if (amAppsProxy) {
        QAbstractItemModel * model = amAppsProxy->property("appModel").value<QAbstractItemModel *>();
        qDebug() << "appModel role names" << model->roleNames();
        m_appsModel->setSourceModel(model);
    } else {
        qWarning() << "Applet `org.deepin.ds.dde-apps` not found.";
        qWarning() << "You probably forget the `-p org.deepin.ds.dde-apps` argument for dde-shell";
    }

    return true;
}

D_APPLET_CLASS(LauncherItem)
}


#include "launcheritem.moc"
