from PySide6 import QtWidgets, QtUiTools, QtGui, QtCore
import sys, random, os
from passGen_ui import Ui_PassGen

carac = "abcdefghijklmnopqrstuvwxyz"

class PasswordGenerator(QtWidgets.QMainWindow, Ui_PassGen):
    def __init__(self):
        super().__init__()
        self.ui = Ui_PassGen()
        self.ui.setupUi(self)

        self.ui.min.setChecked(True)
        self.ui.max.setChecked(True)
        # all signal 
        self.ui.btnQuit.clicked.connect(self.quitter)
        self.ui.btnCopy.clicked.connect(self.copier)
        self.ui.slider.valueChanged.connect(self.change_length)
        self.ui.btnGenerate.clicked.connect(self.generate)

    def quitter(self):
        self.close()

    def copier(self):
        presse_papier = QtGui.QGuiApplication.clipboard()
        presse_papier.setText(self.ui.lineEdit.text())

    def change_length(self):
        self.ui.slider.value()

    def generate(self):
        taille = self.ui.slider.value()
        minus = self.ui.min.isChecked()
        majus = self.ui.max.isChecked()
        chiffre = self.ui.chiffre.isChecked()
        symb = self.ui.sym.isChecked()
        values = self.generate_password(taille, majus, minus, symb, chiffre)
        self.ui.lineEdit.setText(values)
        
        # main_db.add_value(values, "myapplication")

    def generate_password(
        self, taille=True, majus=True, minus=True, symb=True, chiffre=True
    ):
        caracteres = ""

        if minus:
            caracteres += carac.lower()
        if majus:
            caracteres += carac.upper()
        if symb:
            caracteres += "`~!@#$%^&*()_-+={[]}\|:;'<,>.?/"
        if chiffre:
            caracteres += "0123456789"
        password = ""
        for i in range(taille):
            password += random.choice(caracteres)
        return password


if __name__ == "__main__":
    app = QtWidgets.QApplication(sys.argv)
    win = PasswordGenerator()
    win.show()
    sys.exit(app.exec())
