#include "sysinfo.h"

SysInfo::SysInfo(QObject *parent) :
    QObject(parent)
{
}

QString SysInfo::getOS()
{
    return QSysInfo::prettyProductName();
}

QString SysInfo::getArch()
{
    return QSysInfo::currentCpuArchitecture();
}
void SysInfo::openFile(QString file)
{
    QDesktopServices::openUrl(QUrl(file));
}
