#pragma once

#include <QSortFilterProxyModel>

class DDEAppsModelProxy : public QSortFilterProxyModel
{
    Q_OBJECT
public:
    enum MappedRoles {
        // These roles are not necessary to match the value that the source model uses,
        // we are going to map them anyway.
        // NOTICE: we should ONLY use the public roles that the source model provided,
        //         which means names that can be queried by `roleNames()`
        DesktopIdRole,
        NameRole,
        IconNameRole,
        StartUpWMClassRole,
        NoDisplayRole,
        ActionsRole,
        DDECategoryRole,
        InstalledTimeRole,
        LastLaunchedTimeRole,
        LaunchedTimesRole,
        DockedRole,
        OnDesktopRole,
        AutoStartRole,
        AppTypeRole,
        // For debugging purpose
        UnknownRole
    };
    explicit DDEAppsModelProxy(QObject *parent = nullptr);

    void setSourceModel(QAbstractItemModel *sourceModel) override;
    QVariant data(const QModelIndex &index, int role) const override;
    MappedRoles mappedRole(int role) const;
    int sourceRole(MappedRoles role) const;

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    QHash<int, MappedRoles> m_rolesMap; // original role -> our mapped role
};