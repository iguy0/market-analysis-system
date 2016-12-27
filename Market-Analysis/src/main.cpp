#include "include/mainwindow.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    QApplication::setOrganizationName("Terentew Aleksey");
    QApplication::setOrganizationDomain("https://github.com/terentjew-alexey");
    QApplication::setApplicationName("Market Analysis System");

    MainWindow w;
    w.show();

    return a.exec();
}