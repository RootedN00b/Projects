
from PySide6.QtCore import (QCoreApplication, QDate, QDateTime, QLocale,
    QMetaObject, QObject, QPoint, QRect,
    QSize, QTime, QUrl, Qt)
from PySide6.QtGui import (QBrush, QColor, QConicalGradient, QCursor,
    QFont, QFontDatabase, QGradient, QIcon,
    QImage, QKeySequence, QLinearGradient, QPainter,
    QPalette, QPixmap, QRadialGradient, QTransform)
from PySide6.QtWidgets import (QAbstractItemView, QApplication, QFormLayout, QFrame,
    QGridLayout, QHBoxLayout, QHeaderView, QLabel,
    QLineEdit, QMainWindow, QPushButton, QSizePolicy,
    QStackedWidget, QTableWidget, QTableWidgetItem, QVBoxLayout,
    QWidget)
import ressources_rc


class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        if not MainWindow.objectName():
            MainWindow.setObjectName(u"MainWindow")
        MainWindow.resize(1020, 580)
        MainWindow.setStyleSheet(u".QPushButton{\n"
"	background-color: rgb(5, 105, 182);\n"
"font-family: consolas;\n"
"font-size:16px;\n"
"border-radius:5px;\n"
"	color: rgb(255, 255, 255);\n"
"padding:5px;\n"
"width:100px;\n"
"}\n"
".QPushButton:hover{\n"
"	background-color: rgb(255, 255, 255);\n"
"	color: rgb(0, 0, 113);\n"
"}\n"
".QLabel{\n"
"font-size:16px;\n"
"}\n"
"#lbl_welcome{\n"
"font-size:50px;\n"
"}\n"
"\n"
".QLineEdit{\n"
"background-color:rgba(250,250,250,1);\n"
"border:2px solid  rgba(46,82,100, 1);\n"
"border-bottom-color:rgba(50,96,220,1);\n"
"border-top-color:rgba(50,96,220,0);\n"
"border-left-color:rgba(50,96,220,0);\n"
"border-right-color:rgba(50,96,220,0);\n"
"border-radius:5px;\n"
"font-size:16px;\n"
"}")
        self.centralwidget = QWidget(MainWindow)
        self.centralwidget.setObjectName(u"centralwidget")
        self.horizontalLayout = QHBoxLayout(self.centralwidget)
        self.horizontalLayout.setSpacing(0)
        self.horizontalLayout.setObjectName(u"horizontalLayout")
        self.horizontalLayout.setContentsMargins(0, 0, 0, 0)
        self.frame_left = QFrame(self.centralwidget)
        self.frame_left.setObjectName(u"frame_left")
        self.frame_left.setMinimumSize(QSize(250, 0))
        self.frame_left.setMaximumSize(QSize(250, 16777215))
        self.frame_left.setFrameShape(QFrame.NoFrame)
        self.frame_left.setFrameShadow(QFrame.Raised)
        self.verticalLayout = QVBoxLayout(self.frame_left)
        self.verticalLayout.setObjectName(u"verticalLayout")
        self.frame_11 = QFrame(self.frame_left)
        self.frame_11.setObjectName(u"frame_11")
        self.frame_11.setStyleSheet(u"")
        self.frame_11.setFrameShape(QFrame.NoFrame)
        self.frame_11.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_9 = QHBoxLayout(self.frame_11)
        self.horizontalLayout_9.setSpacing(0)
        self.horizontalLayout_9.setObjectName(u"horizontalLayout_9")
        self.horizontalLayout_9.setContentsMargins(0, 0, 0, 0)
        self.label_10 = QLabel(self.frame_11)
        self.label_10.setObjectName(u"label_10")
        self.label_10.setStyleSheet(u"image: url(:/images/psm_logo.jpeg);")
        self.label_10.setAlignment(Qt.AlignCenter)

        self.horizontalLayout_9.addWidget(self.label_10)


        self.verticalLayout.addWidget(self.frame_11)

        self.frame_buttons = QFrame(self.frame_left)
        self.frame_buttons.setObjectName(u"frame_buttons")
        self.frame_buttons.setFrameShape(QFrame.NoFrame)
        self.frame_buttons.setFrameShadow(QFrame.Raised)
        self.formLayout = QFormLayout(self.frame_buttons)
        self.formLayout.setObjectName(u"formLayout")
        self.formLayout.setHorizontalSpacing(0)
        self.formLayout.setContentsMargins(0, 0, 0, 0)
        self.btn_create = QPushButton(self.frame_buttons)
        self.btn_create.setObjectName(u"btn_create")

        self.formLayout.setWidget(0, QFormLayout.FieldRole, self.btn_create)

        self.btn_exist_db = QPushButton(self.frame_buttons)
        self.btn_exist_db.setObjectName(u"btn_exist_db")

        self.formLayout.setWidget(1, QFormLayout.FieldRole, self.btn_exist_db)

        self.btn_store_password = QPushButton(self.frame_buttons)
        self.btn_store_password.setObjectName(u"btn_store_password")

        self.formLayout.setWidget(2, QFormLayout.FieldRole, self.btn_store_password)

        self.btn_retrieve = QPushButton(self.frame_buttons)
        self.btn_retrieve.setObjectName(u"btn_retrieve")

        self.formLayout.setWidget(3, QFormLayout.FieldRole, self.btn_retrieve)

        self.btn_delete = QPushButton(self.frame_buttons)
        self.btn_delete.setObjectName(u"btn_delete")

        self.formLayout.setWidget(4, QFormLayout.FieldRole, self.btn_delete)

        self.btn_analyse = QPushButton(self.frame_buttons)
        self.btn_analyse.setObjectName(u"btn_analyse")

        self.formLayout.setWidget(5, QFormLayout.FieldRole, self.btn_analyse)

        self.btn_logout = QPushButton(self.frame_buttons)
        self.btn_logout.setObjectName(u"btn_logout")

        self.formLayout.setWidget(6, QFormLayout.FieldRole, self.btn_logout)


        self.verticalLayout.addWidget(self.frame_buttons, 0, Qt.AlignBottom)


        self.horizontalLayout.addWidget(self.frame_left)

        self.frame_right = QFrame(self.centralwidget)
        self.frame_right.setObjectName(u"frame_right")
        self.frame_right.setFrameShape(QFrame.NoFrame)
        self.frame_right.setFrameShadow(QFrame.Raised)
        self.verticalLayout_2 = QVBoxLayout(self.frame_right)
        self.verticalLayout_2.setObjectName(u"verticalLayout_2")
        self.frame_title = QFrame(self.frame_right)
        self.frame_title.setObjectName(u"frame_title")
        self.frame_title.setStyleSheet(u"")
        self.frame_title.setFrameShape(QFrame.NoFrame)
        self.frame_title.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_2 = QHBoxLayout(self.frame_title)
        self.horizontalLayout_2.setSpacing(0)
        self.horizontalLayout_2.setObjectName(u"horizontalLayout_2")
        self.horizontalLayout_2.setContentsMargins(0, 0, 0, 0)
        self.lbl_welcome = QLabel(self.frame_title)
        self.lbl_welcome.setObjectName(u"lbl_welcome")
        font = QFont()
        font.setFamilies([u"Consolas"])
        font.setBold(True)
        self.lbl_welcome.setFont(font)

        self.horizontalLayout_2.addWidget(self.lbl_welcome)


        self.verticalLayout_2.addWidget(self.frame_title, 0, Qt.AlignTop)

        self.frame_stacks = QFrame(self.frame_right)
        self.frame_stacks.setObjectName(u"frame_stacks")
        sizePolicy = QSizePolicy(QSizePolicy.Preferred, QSizePolicy.Expanding)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.frame_stacks.sizePolicy().hasHeightForWidth())
        self.frame_stacks.setSizePolicy(sizePolicy)
        self.frame_stacks.setStyleSheet(u"")
        self.frame_stacks.setFrameShape(QFrame.NoFrame)
        self.frame_stacks.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_3 = QHBoxLayout(self.frame_stacks)
        self.horizontalLayout_3.setObjectName(u"horizontalLayout_3")
        self.stackedWidget = QStackedWidget(self.frame_stacks)
        self.stackedWidget.setObjectName(u"stackedWidget")
        self.stackedWidget.setStyleSheet(u"")
        self.stackedWidget.setFrameShadow(QFrame.Sunken)
        self.page_welcome = QWidget()
        self.page_welcome.setObjectName(u"page_welcome")
        self.horizontalLayout_11 = QHBoxLayout(self.page_welcome)
        self.horizontalLayout_11.setSpacing(0)
        self.horizontalLayout_11.setObjectName(u"horizontalLayout_11")
        self.horizontalLayout_11.setContentsMargins(0, 0, 0, 0)
        self.frame_12 = QFrame(self.page_welcome)
        self.frame_12.setObjectName(u"frame_12")
        self.frame_12.setFrameShape(QFrame.NoFrame)
        self.frame_12.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_12 = QHBoxLayout(self.frame_12)
        self.horizontalLayout_12.setObjectName(u"horizontalLayout_12")
        self.label_11 = QLabel(self.frame_12)
        self.label_11.setObjectName(u"label_11")

        self.horizontalLayout_12.addWidget(self.label_11)


        self.horizontalLayout_11.addWidget(self.frame_12)

        self.stackedWidget.addWidget(self.page_welcome)
        self.page_create_db = QWidget()
        self.page_create_db.setObjectName(u"page_create_db")
        self.verticalLayout_3 = QVBoxLayout(self.page_create_db)
        self.verticalLayout_3.setObjectName(u"verticalLayout_3")
        self.frame = QFrame(self.page_create_db)
        self.frame.setObjectName(u"frame")
        self.frame.setStyleSheet(u"#frame{\n"
"padding: 50px;\n"
"}")
        self.frame.setFrameShape(QFrame.NoFrame)
        self.frame.setFrameShadow(QFrame.Raised)
        self.formLayout_2 = QFormLayout(self.frame)
        self.formLayout_2.setObjectName(u"formLayout_2")
        self.lbl_db_name = QLabel(self.frame)
        self.lbl_db_name.setObjectName(u"lbl_db_name")

        self.formLayout_2.setWidget(0, QFormLayout.LabelRole, self.lbl_db_name)

        self.entry_db_name = QLineEdit(self.frame)
        self.entry_db_name.setObjectName(u"entry_db_name")

        self.formLayout_2.setWidget(0, QFormLayout.FieldRole, self.entry_db_name)

        self.lbl_masterpass = QLabel(self.frame)
        self.lbl_masterpass.setObjectName(u"lbl_masterpass")

        self.formLayout_2.setWidget(1, QFormLayout.LabelRole, self.lbl_masterpass)

        self.entry_masterpass = QLineEdit(self.frame)
        self.entry_masterpass.setObjectName(u"entry_masterpass")

        self.formLayout_2.setWidget(1, QFormLayout.FieldRole, self.entry_masterpass)

        self.lbl_materpass_conf = QLabel(self.frame)
        self.lbl_materpass_conf.setObjectName(u"lbl_materpass_conf")

        self.formLayout_2.setWidget(2, QFormLayout.LabelRole, self.lbl_materpass_conf)

        self.entry_masterpass_conf = QLineEdit(self.frame)
        self.entry_masterpass_conf.setObjectName(u"entry_masterpass_conf")

        self.formLayout_2.setWidget(2, QFormLayout.FieldRole, self.entry_masterpass_conf)


        self.verticalLayout_3.addWidget(self.frame)

        self.frame_2 = QFrame(self.page_create_db)
        self.frame_2.setObjectName(u"frame_2")
        self.frame_2.setFrameShape(QFrame.NoFrame)
        self.frame_2.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_4 = QHBoxLayout(self.frame_2)
        self.horizontalLayout_4.setObjectName(u"horizontalLayout_4")
        self.btn_delete_fields = QPushButton(self.frame_2)
        self.btn_delete_fields.setObjectName(u"btn_delete_fields")

        self.horizontalLayout_4.addWidget(self.btn_delete_fields)

        self.btn_confirm = QPushButton(self.frame_2)
        self.btn_confirm.setObjectName(u"btn_confirm")

        self.horizontalLayout_4.addWidget(self.btn_confirm)


        self.verticalLayout_3.addWidget(self.frame_2)

        self.stackedWidget.addWidget(self.page_create_db)
        self.page_exist_db = QWidget()
        self.page_exist_db.setObjectName(u"page_exist_db")
        self.page_exist_db.setStyleSheet(u"#frame_3{\n"
"padding:50px;\n"
"}")
        self.verticalLayout_4 = QVBoxLayout(self.page_exist_db)
        self.verticalLayout_4.setObjectName(u"verticalLayout_4")
        self.frame_3 = QFrame(self.page_exist_db)
        self.frame_3.setObjectName(u"frame_3")
        self.frame_3.setFrameShape(QFrame.NoFrame)
        self.frame_3.setFrameShadow(QFrame.Raised)
        self.gridLayout_2 = QGridLayout(self.frame_3)
        self.gridLayout_2.setObjectName(u"gridLayout_2")
        self.entry_select_db = QLineEdit(self.frame_3)
        self.entry_select_db.setObjectName(u"entry_select_db")

        self.gridLayout_2.addWidget(self.entry_select_db, 0, 1, 1, 1)

        self.lbl_select_db = QLabel(self.frame_3)
        self.lbl_select_db.setObjectName(u"lbl_select_db")

        self.gridLayout_2.addWidget(self.lbl_select_db, 0, 0, 1, 1)

        self.lbl_masterpassword = QLabel(self.frame_3)
        self.lbl_masterpassword.setObjectName(u"lbl_masterpassword")

        self.gridLayout_2.addWidget(self.lbl_masterpassword, 1, 0, 1, 1)

        self.entry_masterpassword = QLineEdit(self.frame_3)
        self.entry_masterpassword.setObjectName(u"entry_masterpassword")

        self.gridLayout_2.addWidget(self.entry_masterpassword, 1, 1, 1, 1)

        self.btn_browse = QPushButton(self.frame_3)
        self.btn_browse.setObjectName(u"btn_browse")

        self.gridLayout_2.addWidget(self.btn_browse, 0, 2, 1, 1)


        self.verticalLayout_4.addWidget(self.frame_3)

        self.frame_4 = QFrame(self.page_exist_db)
        self.frame_4.setObjectName(u"frame_4")
        self.frame_4.setFrameShape(QFrame.NoFrame)
        self.frame_4.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_5 = QHBoxLayout(self.frame_4)
        self.horizontalLayout_5.setObjectName(u"horizontalLayout_5")
        self.btn_delete_fields_2 = QPushButton(self.frame_4)
        self.btn_delete_fields_2.setObjectName(u"btn_delete_fields_2")

        self.horizontalLayout_5.addWidget(self.btn_delete_fields_2)

        self.btn_confirm_2 = QPushButton(self.frame_4)
        self.btn_confirm_2.setObjectName(u"btn_confirm_2")

        self.horizontalLayout_5.addWidget(self.btn_confirm_2)


        self.verticalLayout_4.addWidget(self.frame_4)

        self.stackedWidget.addWidget(self.page_exist_db)
        self.page_storepassword = QWidget()
        self.page_storepassword.setObjectName(u"page_storepassword")
        self.verticalLayout_5 = QVBoxLayout(self.page_storepassword)
        self.verticalLayout_5.setObjectName(u"verticalLayout_5")
        self.frame_5 = QFrame(self.page_storepassword)
        self.frame_5.setObjectName(u"frame_5")
        self.frame_5.setStyleSheet(u"#frame_5{\n"
"padding: 50px;\n"
"}")
        self.frame_5.setFrameShape(QFrame.NoFrame)
        self.frame_5.setFrameShadow(QFrame.Raised)
        self.formLayout_4 = QFormLayout(self.frame_5)
        self.formLayout_4.setObjectName(u"formLayout_4")
        self.lbl_typepassword = QLabel(self.frame_5)
        self.lbl_typepassword.setObjectName(u"lbl_typepassword")

        self.formLayout_4.setWidget(0, QFormLayout.LabelRole, self.lbl_typepassword)

        self.entry_typepassword = QLineEdit(self.frame_5)
        self.entry_typepassword.setObjectName(u"entry_typepassword")

        self.formLayout_4.setWidget(0, QFormLayout.FieldRole, self.entry_typepassword)

        self.lbl_entryname = QLabel(self.frame_5)
        self.lbl_entryname.setObjectName(u"lbl_entryname")

        self.formLayout_4.setWidget(1, QFormLayout.LabelRole, self.lbl_entryname)

        self.entry_name = QLineEdit(self.frame_5)
        self.entry_name.setObjectName(u"entry_name")

        self.formLayout_4.setWidget(1, QFormLayout.FieldRole, self.entry_name)

        self.lbl_pass_url = QLabel(self.frame_5)
        self.lbl_pass_url.setObjectName(u"lbl_pass_url")

        self.formLayout_4.setWidget(2, QFormLayout.LabelRole, self.lbl_pass_url)

        self.entry_pass_url = QLineEdit(self.frame_5)
        self.entry_pass_url.setObjectName(u"entry_pass_url")

        self.formLayout_4.setWidget(2, QFormLayout.FieldRole, self.entry_pass_url)

        self.lbl_username = QLabel(self.frame_5)
        self.lbl_username.setObjectName(u"lbl_username")

        self.formLayout_4.setWidget(3, QFormLayout.LabelRole, self.lbl_username)

        self.entry_username = QLineEdit(self.frame_5)
        self.entry_username.setObjectName(u"entry_username")

        self.formLayout_4.setWidget(3, QFormLayout.FieldRole, self.entry_username)


        self.verticalLayout_5.addWidget(self.frame_5)

        self.frame_6 = QFrame(self.page_storepassword)
        self.frame_6.setObjectName(u"frame_6")
        self.frame_6.setFrameShape(QFrame.NoFrame)
        self.frame_6.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_6 = QHBoxLayout(self.frame_6)
        self.horizontalLayout_6.setObjectName(u"horizontalLayout_6")
        self.btn_delete_fields_3 = QPushButton(self.frame_6)
        self.btn_delete_fields_3.setObjectName(u"btn_delete_fields_3")

        self.horizontalLayout_6.addWidget(self.btn_delete_fields_3)

        self.btn_random_pass = QPushButton(self.frame_6)
        self.btn_random_pass.setObjectName(u"btn_random_pass")

        self.horizontalLayout_6.addWidget(self.btn_random_pass)

        self.btn_confirm_3 = QPushButton(self.frame_6)
        self.btn_confirm_3.setObjectName(u"btn_confirm_3")

        self.horizontalLayout_6.addWidget(self.btn_confirm_3)


        self.verticalLayout_5.addWidget(self.frame_6)

        self.stackedWidget.addWidget(self.page_storepassword)
        self.page_retrieve = QWidget()
        self.page_retrieve.setObjectName(u"page_retrieve")
        self.page_retrieve.setStyleSheet(u"")
        self.verticalLayout_6 = QVBoxLayout(self.page_retrieve)
        self.verticalLayout_6.setObjectName(u"verticalLayout_6")
        self.frame_7 = QFrame(self.page_retrieve)
        self.frame_7.setObjectName(u"frame_7")
        self.frame_7.setStyleSheet(u"#frame_7{\n"
"padding: 50px;\n"
"}")
        self.frame_7.setFrameShape(QFrame.NoFrame)
        self.frame_7.setFrameShadow(QFrame.Raised)
        self.gridLayout = QGridLayout(self.frame_7)
        self.gridLayout.setObjectName(u"gridLayout")
        self.entry_retrieve_username = QLineEdit(self.frame_7)
        self.entry_retrieve_username.setObjectName(u"entry_retrieve_username")

        self.gridLayout.addWidget(self.entry_retrieve_username, 1, 1, 1, 1)

        self.lbl_retriev_username = QLabel(self.frame_7)
        self.lbl_retriev_username.setObjectName(u"lbl_retriev_username")

        self.gridLayout.addWidget(self.lbl_retriev_username, 1, 0, 1, 1)

        self.lbl_retrieve_name = QLabel(self.frame_7)
        self.lbl_retrieve_name.setObjectName(u"lbl_retrieve_name")

        self.gridLayout.addWidget(self.lbl_retrieve_name, 0, 0, 1, 1)

        self.entry_retreive_name = QLineEdit(self.frame_7)
        self.entry_retreive_name.setObjectName(u"entry_retreive_name")

        self.gridLayout.addWidget(self.entry_retreive_name, 0, 1, 1, 1)


        self.verticalLayout_6.addWidget(self.frame_7)

        self.frame_8 = QFrame(self.page_retrieve)
        self.frame_8.setObjectName(u"frame_8")
        self.frame_8.setFrameShape(QFrame.NoFrame)
        self.frame_8.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_7 = QHBoxLayout(self.frame_8)
        self.horizontalLayout_7.setObjectName(u"horizontalLayout_7")
        self.btn_delete_fields_4 = QPushButton(self.frame_8)
        self.btn_delete_fields_4.setObjectName(u"btn_delete_fields_4")

        self.horizontalLayout_7.addWidget(self.btn_delete_fields_4)

        self.btn_confirm_4 = QPushButton(self.frame_8)
        self.btn_confirm_4.setObjectName(u"btn_confirm_4")

        self.horizontalLayout_7.addWidget(self.btn_confirm_4)


        self.verticalLayout_6.addWidget(self.frame_8)

        self.stackedWidget.addWidget(self.page_retrieve)
        self.page_delete_entry = QWidget()
        self.page_delete_entry.setObjectName(u"page_delete_entry")
        self.verticalLayout_7 = QVBoxLayout(self.page_delete_entry)
        self.verticalLayout_7.setObjectName(u"verticalLayout_7")
        self.tableWidget = QTableWidget(self.page_delete_entry)
        if (self.tableWidget.columnCount() < 3):
            self.tableWidget.setColumnCount(3)
        font1 = QFont()
        font1.setPointSize(13)
        font1.setBold(False)
        __qtablewidgetitem = QTableWidgetItem()
        __qtablewidgetitem.setFont(font1);
        self.tableWidget.setHorizontalHeaderItem(0, __qtablewidgetitem)
        __qtablewidgetitem1 = QTableWidgetItem()
        __qtablewidgetitem1.setFont(font1);
        self.tableWidget.setHorizontalHeaderItem(1, __qtablewidgetitem1)
        __qtablewidgetitem2 = QTableWidgetItem()
        __qtablewidgetitem2.setFont(font1);
        self.tableWidget.setHorizontalHeaderItem(2, __qtablewidgetitem2)
        self.tableWidget.setObjectName(u"tableWidget")
        font2 = QFont()
        font2.setPointSize(12)
        self.tableWidget.setFont(font2)
        self.tableWidget.setEditTriggers(QAbstractItemView.NoEditTriggers)
        self.tableWidget.setSelectionMode(QAbstractItemView.SingleSelection)
        self.tableWidget.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.tableWidget.setGridStyle(Qt.DashDotDotLine)
        self.tableWidget.horizontalHeader().setDefaultSectionSize(150)
        self.tableWidget.horizontalHeader().setStretchLastSection(True)

        self.verticalLayout_7.addWidget(self.tableWidget)

        self.stackedWidget.addWidget(self.page_delete_entry)
        self.page_analyse = QWidget()
        self.page_analyse.setObjectName(u"page_analyse")
        self.verticalLayout_8 = QVBoxLayout(self.page_analyse)
        self.verticalLayout_8.setObjectName(u"verticalLayout_8")
        self.frame_9 = QFrame(self.page_analyse)
        self.frame_9.setObjectName(u"frame_9")
        self.frame_9.setStyleSheet(u"#frame_9{\n"
"padding: 50px;\n"
"}")
        self.frame_9.setFrameShape(QFrame.NoFrame)
        self.frame_9.setFrameShadow(QFrame.Raised)
        self.formLayout_6 = QFormLayout(self.frame_9)
        self.formLayout_6.setObjectName(u"formLayout_6")
        self.lbl_analyse = QLabel(self.frame_9)
        self.lbl_analyse.setObjectName(u"lbl_analyse")

        self.formLayout_6.setWidget(0, QFormLayout.LabelRole, self.lbl_analyse)

        self.entry_analyse = QLineEdit(self.frame_9)
        self.entry_analyse.setObjectName(u"entry_analyse")

        self.formLayout_6.setWidget(0, QFormLayout.FieldRole, self.entry_analyse)


        self.verticalLayout_8.addWidget(self.frame_9)

        self.frame_10 = QFrame(self.page_analyse)
        self.frame_10.setObjectName(u"frame_10")
        self.frame_10.setStyleSheet(u"")
        self.frame_10.setFrameShape(QFrame.NoFrame)
        self.frame_10.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_8 = QHBoxLayout(self.frame_10)
        self.horizontalLayout_8.setObjectName(u"horizontalLayout_8")
        self.btn_delete_fields_5 = QPushButton(self.frame_10)
        self.btn_delete_fields_5.setObjectName(u"btn_delete_fields_5")

        self.horizontalLayout_8.addWidget(self.btn_delete_fields_5)

        self.btn_confirm_5 = QPushButton(self.frame_10)
        self.btn_confirm_5.setObjectName(u"btn_confirm_5")

        self.horizontalLayout_8.addWidget(self.btn_confirm_5)


        self.verticalLayout_8.addWidget(self.frame_10)

        self.stackedWidget.addWidget(self.page_analyse)

        self.horizontalLayout_3.addWidget(self.stackedWidget)


        self.verticalLayout_2.addWidget(self.frame_stacks)

        self.frame_right_buttom = QFrame(self.frame_right)
        self.frame_right_buttom.setObjectName(u"frame_right_buttom")
        sizePolicy1 = QSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        sizePolicy1.setHorizontalStretch(0)
        sizePolicy1.setVerticalStretch(0)
        sizePolicy1.setHeightForWidth(self.frame_right_buttom.sizePolicy().hasHeightForWidth())
        self.frame_right_buttom.setSizePolicy(sizePolicy1)
        self.frame_right_buttom.setMinimumSize(QSize(0, 50))
        self.frame_right_buttom.setMaximumSize(QSize(16777215, 50))
        self.frame_right_buttom.setStyleSheet(u"")
        self.frame_right_buttom.setFrameShape(QFrame.NoFrame)
        self.frame_right_buttom.setFrameShadow(QFrame.Raised)
        self.horizontalLayout_10 = QHBoxLayout(self.frame_right_buttom)
        self.horizontalLayout_10.setSpacing(0)
        self.horizontalLayout_10.setObjectName(u"horizontalLayout_10")
        self.horizontalLayout_10.setContentsMargins(0, 0, 0, 0)
        self.lbl_ss_logo = QLabel(self.frame_right_buttom)
        self.lbl_ss_logo.setObjectName(u"lbl_ss_logo")
        self.lbl_ss_logo.setStyleSheet(u"image: url(:/images/ss_logo.jpeg);\n"
"background-color: rgb(255, 255, 255);")
        self.lbl_ss_logo.setAlignment(Qt.AlignCenter)

        self.horizontalLayout_10.addWidget(self.lbl_ss_logo)


        self.verticalLayout_2.addWidget(self.frame_right_buttom)


        self.horizontalLayout.addWidget(self.frame_right)

        MainWindow.setCentralWidget(self.centralwidget)

        self.retranslateUi(MainWindow)

        self.stackedWidget.setCurrentIndex(3)


        QMetaObject.connectSlotsByName(MainWindow)
    # setupUi

    def retranslateUi(self, MainWindow):
        MainWindow.setWindowTitle(QCoreApplication.translate("MainWindow", u"PASM Password Manager", None))
        self.label_10.setText("")
        self.btn_create.setText(QCoreApplication.translate("MainWindow", u"Create KeePass Database", None))
        self.btn_exist_db.setText(QCoreApplication.translate("MainWindow", u"Existing Keepass DB", None))
        self.btn_store_password.setText(QCoreApplication.translate("MainWindow", u"Store Password", None))
        self.btn_retrieve.setText(QCoreApplication.translate("MainWindow", u"Retrieve Password", None))
        self.btn_delete.setText(QCoreApplication.translate("MainWindow", u"Show Database Entry", None))
        self.btn_analyse.setText(QCoreApplication.translate("MainWindow", u"Analyse Password", None))
        self.btn_logout.setText(QCoreApplication.translate("MainWindow", u"Logout", None))
        self.lbl_welcome.setText(QCoreApplication.translate("MainWindow", u"Welcome,", None))
        self.label_11.setText(QCoreApplication.translate("MainWindow", u"In an increasingly digital world, keeping our online accounts secure is of paramount importance.\n"
"That's why I've developed a Python-based Password Manager Security Analyzer\n"
"to help you manage and safeguard your passwords effectively.\n"
"\n"
"Key features of the Password Manager Security Analyzer include:\n"
"\n"
"* Secure Password Storage: Safely store and manage your passwords in an encrypted\n"
"KeePass database.\n"
"* Website Integration: Associate website URLs with your stored passwords for easy retrieval.\n"
"* Password Analysis: Check if your passwords have been compromised in data breaches\n"
"using the Have I Been Pwned API.\n"
"* Password Sharing: Easily share passwords with others without revealing the actual password.", None))
        self.lbl_db_name.setText(QCoreApplication.translate("MainWindow", u"Database name", None))
        self.lbl_masterpass.setText(QCoreApplication.translate("MainWindow", u"Master password", None))
        self.lbl_materpass_conf.setText(QCoreApplication.translate("MainWindow", u"Confirm master password", None))
        self.btn_delete_fields.setText(QCoreApplication.translate("MainWindow", u"Delete fields", None))
        self.btn_confirm.setText(QCoreApplication.translate("MainWindow", u"Confirm", None))
        self.lbl_select_db.setText(QCoreApplication.translate("MainWindow", u"Select database", None))
        self.lbl_masterpassword.setText(QCoreApplication.translate("MainWindow", u"Master password", None))
        self.btn_browse.setText(QCoreApplication.translate("MainWindow", u"Browse", None))
        self.btn_delete_fields_2.setText(QCoreApplication.translate("MainWindow", u"Delete fields", None))
        self.btn_confirm_2.setText(QCoreApplication.translate("MainWindow", u"Confirm", None))
        self.lbl_typepassword.setText(QCoreApplication.translate("MainWindow", u"Type password", None))
        self.lbl_entryname.setText(QCoreApplication.translate("MainWindow", u"Entry name", None))
        self.lbl_pass_url.setText(QCoreApplication.translate("MainWindow", u"Password for (URL)", None))
        self.lbl_username.setText(QCoreApplication.translate("MainWindow", u"Username", None))
        self.btn_delete_fields_3.setText(QCoreApplication.translate("MainWindow", u"Delete fields", None))
        self.btn_random_pass.setText(QCoreApplication.translate("MainWindow", u"Random Password", None))
        self.btn_confirm_3.setText(QCoreApplication.translate("MainWindow", u"Confirm", None))
        self.lbl_retriev_username.setText(QCoreApplication.translate("MainWindow", u"Username", None))
        self.lbl_retrieve_name.setText(QCoreApplication.translate("MainWindow", u"Entry name", None))
        self.btn_delete_fields_4.setText(QCoreApplication.translate("MainWindow", u"Delete fields", None))
        self.btn_confirm_4.setText(QCoreApplication.translate("MainWindow", u"Confirm", None))
        ___qtablewidgetitem = self.tableWidget.horizontalHeaderItem(0)
        ___qtablewidgetitem.setText(QCoreApplication.translate("MainWindow", u"Title", None));
        ___qtablewidgetitem1 = self.tableWidget.horizontalHeaderItem(1)
        ___qtablewidgetitem1.setText(QCoreApplication.translate("MainWindow", u"Username", None));
        ___qtablewidgetitem2 = self.tableWidget.horizontalHeaderItem(2)
        ___qtablewidgetitem2.setText(QCoreApplication.translate("MainWindow", u"URL", None));
        self.lbl_analyse.setText(QCoreApplication.translate("MainWindow", u"Enter password to analyse", None))
        self.btn_delete_fields_5.setText(QCoreApplication.translate("MainWindow", u"Delete fields", None))
        self.btn_confirm_5.setText(QCoreApplication.translate("MainWindow", u"Confirm", None))
        self.lbl_ss_logo.setText("")
    # retranslateUi

