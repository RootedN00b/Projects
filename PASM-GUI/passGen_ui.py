from PySide6.QtCore import (QCoreApplication, QDate, QDateTime, QLocale,
    QMetaObject, QObject, QPoint, QRect,
    QSize, QTime, QUrl, Qt)
from PySide6.QtGui import (QBrush, QColor, QConicalGradient, QCursor,
    QFont, QFontDatabase, QGradient, QIcon,
    QImage, QKeySequence, QLinearGradient, QPainter,
    QPalette, QPixmap, QRadialGradient, QTransform)
from PySide6.QtWidgets import (QApplication, QCheckBox, QFrame, QGridLayout,
    QHBoxLayout, QLabel, QLineEdit, QMainWindow,
    QPushButton, QSizePolicy, QSlider, QVBoxLayout,
    QWidget)

class Ui_PassGen(object):
    def setupUi(self, MainWindow):
        if not MainWindow.objectName():
            MainWindow.setObjectName(u"MainWindow")
        MainWindow.resize(432, 200)
        MainWindow.setMinimumSize(QSize(430, 200))
        MainWindow.setMaximumSize(QSize(432, 200))
        font = QFont()
        font.setPointSize(12)
        MainWindow.setFont(font)
        self.centralwidget = QWidget(MainWindow)
        self.centralwidget.setObjectName(u"centralwidget")
        self.verticalLayout = QVBoxLayout(self.centralwidget)
        self.verticalLayout.setObjectName(u"verticalLayout")
        self.frame = QFrame(self.centralwidget)
        self.frame.setObjectName(u"frame")
        self.frame.setFrameShape(QFrame.StyledPanel)
        self.frame.setFrameShadow(QFrame.Raised)
        self.gridLayout = QGridLayout(self.frame)
        self.gridLayout.setObjectName(u"gridLayout")
        self.sym = QCheckBox(self.frame)
        self.sym.setObjectName(u"sym")

        self.gridLayout.addWidget(self.sym, 2, 2, 1, 1)

        self.min = QCheckBox(self.frame)
        self.min.setObjectName(u"min")
        self.min.setChecked(False)

        self.gridLayout.addWidget(self.min, 0, 0, 1, 1)

        self.max = QCheckBox(self.frame)
        self.max.setObjectName(u"max")
        self.max.setChecked(False)

        self.gridLayout.addWidget(self.max, 0, 2, 1, 1)

        self.chiffre = QCheckBox(self.frame)
        self.chiffre.setObjectName(u"chiffre")

        self.gridLayout.addWidget(self.chiffre, 2, 0, 1, 1)

        self.label = QLabel(self.frame)
        self.label.setObjectName(u"label")
        font1 = QFont()
        font1.setPointSize(10)
        font1.setBold(True)
        self.label.setFont(font1)

        self.gridLayout.addWidget(self.label, 0, 1, 1, 1)

        self.lineEdit = QLineEdit(self.frame)
        self.lineEdit.setObjectName(u"lineEdit")
        self.lineEdit.setAlignment(Qt.AlignCenter)
        self.lineEdit.setReadOnly(True)

        self.gridLayout.addWidget(self.lineEdit, 3, 0, 1, 3)

        self.slider = QSlider(self.frame)
        self.slider.setObjectName(u"slider")
        self.slider.setMinimum(8)
        self.slider.setMaximum(30)
        self.slider.setValue(8)
        self.slider.setOrientation(Qt.Horizontal)
        self.slider.setTickPosition(QSlider.TicksBelow)
        self.slider.setTickInterval(1)

        self.gridLayout.addWidget(self.slider, 2, 1, 1, 1)


        self.verticalLayout.addWidget(self.frame)

        self.frame_2 = QFrame(self.centralwidget)
        self.frame_2.setObjectName(u"frame_2")
        self.frame_2.setFrameShape(QFrame.StyledPanel)
        self.frame_2.setFrameShadow(QFrame.Raised)
        self.horizontalLayout = QHBoxLayout(self.frame_2)
        self.horizontalLayout.setObjectName(u"horizontalLayout")
        self.btnCopy = QPushButton(self.frame_2)
        self.btnCopy.setObjectName(u"btnCopy")

        self.horizontalLayout.addWidget(self.btnCopy)

        self.btnGenerate = QPushButton(self.frame_2)
        self.btnGenerate.setObjectName(u"btnGenerate")

        self.horizontalLayout.addWidget(self.btnGenerate)

        self.btnQuit = QPushButton(self.frame_2)
        self.btnQuit.setObjectName(u"btnQuit")

        self.horizontalLayout.addWidget(self.btnQuit)


        self.verticalLayout.addWidget(self.frame_2)

        MainWindow.setCentralWidget(self.centralwidget)

        self.retranslateUi(MainWindow)

        QMetaObject.connectSlotsByName(MainWindow)
    # setupUi

    def retranslateUi(self, MainWindow):
        MainWindow.setWindowTitle(QCoreApplication.translate("MainWindow", u"Password Generator", None))
        self.sym.setText(QCoreApplication.translate("MainWindow", u"Symboles", None))
        self.min.setText(QCoreApplication.translate("MainWindow", u"Minuscules", None))
        self.max.setText(QCoreApplication.translate("MainWindow", u"Majuscules", None))
        self.chiffre.setText(QCoreApplication.translate("MainWindow", u"Chiffres", None))
        self.label.setText(QCoreApplication.translate("MainWindow", u"Taille de votre mot de passe", None))
        self.btnCopy.setText(QCoreApplication.translate("MainWindow", u"Copier", None))
        self.btnGenerate.setText(QCoreApplication.translate("MainWindow", u"Generer", None))
        self.btnQuit.setText(QCoreApplication.translate("MainWindow", u"Quitter", None))
    # retranslateUi

