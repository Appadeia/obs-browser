#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QString>
#include <QDesktopServices>
#include <QUrl>
#include <QScreen>

class SysInfo : public QObject
{
    Q_OBJECT

public:
    explicit SysInfo(QObject *parent = nullptr);

    Q_INVOKABLE QString getOS();
    Q_INVOKABLE QString getArch();
    Q_INVOKABLE void openFile(QString file);

signals:
    void userNameChanged();

};

#endif // BACKEND_H
