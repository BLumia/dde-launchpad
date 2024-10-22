#include "ddeappsmodelproxy.h"

DDEAppsModelProxy::DDEAppsModelProxy(QObject *parent)
    : QSortFilterProxyModel(parent)
{

}

DDEAppsModelProxy::MappedRoles mappedRoleFromByteArray(const QByteArray & ba)
{
    static QHash<QByteArray, DDEAppsModelProxy::MappedRoles> rolesmap {
        {QByteArrayLiteral("appType"), DDEAppsModelProxy::AppTypeRole},
        {QByteArrayLiteral("docked"), DDEAppsModelProxy::DockedRole},
        {QByteArrayLiteral("actions"), DDEAppsModelProxy::ActionsRole},
        {QByteArrayLiteral("noDisplay"), DDEAppsModelProxy::NoDisplayRole},
        {QByteArrayLiteral("launchedTimes"), DDEAppsModelProxy::LaunchedTimesRole},
        {QByteArrayLiteral("ddeCategory"), DDEAppsModelProxy::DDECategoryRole},
        {QByteArrayLiteral("iconName"), DDEAppsModelProxy::IconNameRole},
        {QByteArrayLiteral("name"), DDEAppsModelProxy::NameRole},
        {QByteArrayLiteral("desktopId"), DDEAppsModelProxy::DesktopIdRole},
        {QByteArrayLiteral("installedTime"), DDEAppsModelProxy::InstalledTimeRole},
        {QByteArrayLiteral("startupWMClass"), DDEAppsModelProxy::StartUpWMClassRole},
    };
    return rolesmap.value(ba, DDEAppsModelProxy::UnknownRole);
}

void DDEAppsModelProxy::setSourceModel(QAbstractItemModel *sourceModel)
{
    auto roles = sourceModel->roleNames();
    for (auto key : roles.keys()) {
        m_rolesMap[key] = mappedRoleFromByteArray(roles[key]);
    }
    QSortFilterProxyModel::setSourceModel(sourceModel);
}

DDEAppsModelProxy::MappedRoles DDEAppsModelProxy::mappedRole(int role) const
{
    return m_rolesMap[role];
}

int DDEAppsModelProxy::sourceRole(MappedRoles role) const
{
    return m_rolesMap.key(role, -1);
}

QVariant DDEAppsModelProxy::data(const QModelIndex &index, int role) const
{
    auto roles = sourceModel()->roleNames();
    switch (mappedRole(role)) {
    case DesktopIdRole:
        return QSortFilterProxyModel::data(index, role).toString() + QStringLiteral(".desktop");
    default:
        break;
    }
    return QSortFilterProxyModel::data(index, role);
}

bool DDEAppsModelProxy::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    QModelIndex modelIndex = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!modelIndex.isValid())
        return false;

    return !sourceModel()->data(modelIndex, sourceRole(NoDisplayRole)).toBool();
}