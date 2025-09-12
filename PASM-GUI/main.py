from PySide6.QtWidgets import (
    QMainWindow,
    QApplication,
    QLineEdit,
    QMessageBox,
    QFileDialog,
    QTableWidgetItem,
)
from PySide6.QtGui import QFont
from PySide6.QtCore import Qt
import pykeepass, hashlib, requests, base64, os, pyperclip, string, random,validators
from PySide6 import QtCore, QtGui
from cryptography.fernet import Fernet
import sys, os
from principal_ui import Ui_MainWindow
from gen_pass import PasswordGenerator

carac = "abcdefghijklmnopqrstuvwxyz"
# Constant variable for the global scope
DB_FILE = ""
MASTER_PASSWORD = ""

# Create the database directory if not exist
db_dir = r"./db/"
if not os.path.exists(db_dir):
    os.mkdir(r"./db/")


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        # Set up the main window UI from Qt Designer
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
        self.setWindowTitle("PASM Password Manager")
        self.setFixedSize(1024, 580)

        self.ui.stackedWidget.setCurrentIndex(0)

        # Signals when clicking buttons

        self.ui.btn_create.clicked.connect(self.create_database)
        self.ui.btn_exist_db.clicked.connect(self.use_existing_db)
        self.ui.btn_store_password.clicked.connect(self.store_password)
        self.ui.btn_retrieve.clicked.connect(self.retrieve_password)
        self.ui.btn_delete.clicked.connect(self.show_entries)
        self.ui.btn_random_pass.clicked.connect(self.random_pass)
        self.ui.btn_analyse.clicked.connect(self.analyze_password)
        self.ui.btn_logout.clicked.connect(self.logout)

    # =====================================================================================
    # =====================================================================================

    # Native function from the command line version

    def encrypt_password(password):
        key = hashlib.sha256(MASTER_PASSWORD.encode()).digest()
        fernet_key = base64.urlsafe_b64encode(key)
        fernet = Fernet(fernet_key)
        encrypted_password = fernet.encrypt(password.encode())
        return encrypted_password

    def decrypt_password(encrypted_password):
        key = hashlib.sha256(MASTER_PASSWORD.encode()).digest()
        fernet_key = base64.urlsafe_b64encode(key)
        fernet = Fernet(fernet_key)
        decrypted_password = fernet.decrypt(encrypted_password).decode()
        return decrypted_password

    def generate_password(length=12):
        characters = string.ascii_letters + string.digits + string.punctuation
        password = "".join(random.choice(characters) for _ in range(length))
        return password

    # =========================================================================================
    # =========================================================================================
    # create database function
    def create_database(self):
        self.ui.lbl_welcome.setText("Create Database")
        self.ui.stackedWidget.setCurrentIndex(1)
        self.ui.entry_db_name.setFocus()
        # Set master password and master password confirmation to echo mode password
        self.ui.entry_masterpass.setEchoMode(QLineEdit.Password)
        self.ui.entry_masterpass_conf.setEchoMode(QLineEdit.Password)
        # confirm database creation
        self.ui.btn_confirm.clicked.connect(self.confirm_create_db)
        # clear fields
        self.ui.btn_delete_fields.clicked.connect(self.delete_entries_1)

    # action to confirm database creation function

    def confirm_create_db(self):
        global DB_FILE
        global MASTER_PASSWORD

        database_name = self.ui.entry_db_name.text()
        current_directory = os.getcwd()  # Get current directory

        DB_FILE = os.path.join(current_directory, f"db/{database_name}.kdbx")

        if os.path.exists(DB_FILE):
            QMessageBox.warning(
                self,
                "Warning",
                f"A database with the name 'db/{database_name}.kdbx' already exists in {os.path.basename(current_directory)}.",
            )
            self.delete_entries_1()
            return

        master_password = self.ui.entry_masterpass.text()
        confirm_password = self.ui.entry_masterpass_conf.text()

        if master_password != confirm_password:
            QMessageBox.warning(
                self, "Warning", f"Passwords do not match. Database creation aborted."
            )
            self.delete_entries_1()
            return

        if len(master_password) < 8:
            QMessageBox.warning(
                self,
                "Warning",
                f"Master password should be a minimum of 8 characters long. Database creation aborted.",
            )
            self.delete_entries_1()
            return

        try:
            # Create an empty KeePass database file
            kp = pykeepass.create_database(DB_FILE, master_password)
            kp.save()
            QMessageBox.information(
                self,
                "Database creation",
                f"Database 'db/{database_name}.kdbx' created successfully in {os.path.basename(current_directory)}!",
            )
            # Save DB_FILE and MASTER_PASSWORD
            with open(".keepass_settings", "w") as settings_file:
                settings_file.write(f"{DB_FILE}\n{master_password}")

            MASTER_PASSWORD = master_password
            self.delete_entries_1()
        except Exception as e:
            QMessageBox.critical(self, "Critical", f"Error creating database:{str(e)}")
            self.delete_entries_1()

    def delete_entries_1(self):
        self.ui.entry_db_name.clear()
        self.ui.entry_masterpass.clear()
        self.ui.entry_masterpass_conf.clear()
        self.ui.entry_db_name.setFocus()

    # =========================================================================================
    # =========================================================================================
    # use existing database function
    def use_existing_db(self):
        self.ui.lbl_welcome.setText("Use Existing DB")
        self.ui.stackedWidget.setCurrentIndex(2)
        # disable select database entry
        self.ui.entry_select_db.setDisabled(True)
        self.ui.entry_masterpassword.setFocus()
        self.ui.entry_masterpassword.setEchoMode(QLineEdit.Password)

        # function action
        self.ui.btn_browse.clicked.connect(self.browse_db)
        self.ui.btn_confirm_2.clicked.connect(self.confirm_existing_db)
        self.ui.btn_delete_fields_2.clicked.connect(self.delete_entries_2)

    def confirm_existing_db(self):
        global DB_FILE
        global MASTER_PASSWORD

        db_name = self.ui.entry_select_db.text()
        db_path = os.path.join("db", f"{db_name}")
        master_password = self.ui.entry_masterpassword.text()

        if not os.path.exists(db_path):
            QMessageBox.warning(self, "Warning", "Database file does not exist.")
            self.delete_entries_2()
            return

        try:
            with pykeepass.PyKeePass(db_path, password=master_password):
                DB_FILE = db_path
                MASTER_PASSWORD = master_password

            QMessageBox.information(
                self,
                "Use existing DB",
                f"Using existing database = Ok\nDatabase Path: {DB_FILE}",
            )
            self.delete_entries_2()
        except Exception as e:
            QMessageBox.warning(
                self, "Warning", f"Error opening existing database:{str(e)}"
            )
            self.delete_entries_2()

    def browse_db(self):
        directory = QFileDialog.getOpenFileName()[0]
        self.ui.entry_select_db.setText(directory)
        self.ui.entry_masterpassword.setFocus()

    def delete_entries_2(self):
        self.ui.entry_select_db.clear()
        self.ui.entry_masterpassword.clear()
        self.ui.entry_masterpassword.setFocus()

    # =========================================================================================
    # =========================================================================================
    # store password function
    def store_password(self):
        self.ui.lbl_welcome.setText("Store Password")
        self.ui.stackedWidget.setCurrentIndex(3)
        self.ui.entry_typepassword.setFocus()
        
        self.ui.btn_confirm_3.clicked.connect(self.confirm_store_password)
        self.ui.btn_delete_fields_3.clicked.connect(self.delete_store_entries)

    def random_pass(self):
        self.win_random = PasswordGenerator()
        self.win_random.setWindowModality(Qt.ApplicationModal)
        self.win_random.show()
        
    def confirm_store_password(self):
        global DB_FILE
        global MASTER_PASSWORD

        if DB_FILE == "" or MASTER_PASSWORD == "":
            QMessageBox.warning(self, "Warning",
                "Please create a new database or use an existing database first"
            )
            self.ui.entry_typepassword.setFocus()
            return
        
        while True:
            password = self.ui.entry_typepassword.text()
            e_name = self.ui.entry_name.text()
            website_url = self.ui.entry_pass_url.text()
            username = self.ui.entry_username.text()

            if not validators.url(website_url):
                QMessageBox.warning(self, "Warning","Invalid website URL.")
                self.ui.entry_pass_url.setFocus()
                return
            else:
                break
            
        while True:
            if e_name == "":
                QMessageBox.warning(self, "Warning",
                    "Entry name should not be empty"
                )
                self.ui.entry_name.setFocus()
                return
            else:
                break
            
        while True:
            if len(username) < 4:
                QMessageBox.warning(self, "Warning",
                    "Username should be a minimum of 4 characters long."
                )
                self.ui.entry_username.setFocus()
                return
            else:
                break

        try:
            with pykeepass.PyKeePass(DB_FILE, password=MASTER_PASSWORD) as kp:
                entry_group = kp.find_groups(name="Root", first=True)

                # Check if entry name already exists
                if kp.find_entries(title=e_name, group=entry_group):
                    QMessageBox.warning(self, "Warning",
                        "An entry with the same name already exists. Password not stored.\nChange it"
                    )
                    self.ui.entry_name.setFocus()
                    return

                entry = kp.add_entry(
                    entry_group, title=e_name, username=username, password=password
                )
                entry.url = website_url  # Set the URL field
                kp.save()
            QMessageBox.information(self, "Information",
                    "Password stored successfully!"
                )
            self.delete_store_entries()
        except Exception as e:
            QMessageBox.warning(self, "Warning",f"Error storing password:{str(e)}")

    def delete_store_entries(self):
        self.ui.entry_typepassword.clear()
        self.ui.entry_name.clear()
        self.ui.entry_pass_url.clear()
        self.ui.entry_username.clear()
        self.ui.entry_typepassword.setFocus()
    # =====================================================================================
    # =====================================================================================

    # retrieve password function
    def retrieve_password(self):
        self.ui.lbl_welcome.setText("Retrieve Password")
        self.ui.stackedWidget.setCurrentIndex(4)

        self.delete_retreive_entries()

        self.ui.btn_confirm_4.clicked.connect(self.confirm_retrieve_password)
        self.ui.btn_delete_fields_4.clicked.connect(self.delete_retreive_entries)

    def confirm_retrieve_password(self):
        global DB_FILE
        global MASTER_PASSWORD

        if DB_FILE == "" or MASTER_PASSWORD == "":
            QMessageBox.information(
                self,
                "Information",
                "Please create a new database or use an existing database first.",
            )
            self.delete_retreive_entries()
            return

        entry_name = self.ui.entry_retreive_name.text()
        username = self.ui.entry_retrieve_username.text()

        try:
            with pykeepass.PyKeePass(DB_FILE, password=MASTER_PASSWORD) as kp:
                entries = kp.find_entries(title=entry_name, username=username)
                if entries:
                    entry = entries[0]
                    decrypted_password = (
                        entry.password
                    )  # Password is already stored in encrypted form
                    QMessageBox.information(
                        self,
                        "Information",
                        f"Retrieved password: {decrypted_password}\nPassword copied to clipboard.",
                    )
                    pyperclip.copy(decrypted_password)
                else:
                    QMessageBox.warning(self, "Warning", "No matching entry found")
        except Exception as e:
            QMessageBox.information(
                self, "Information", f"Error retrieving password:{str(e)}"
            )

    def delete_retreive_entries(self):
        self.ui.entry_retreive_name.clear()
        self.ui.entry_retrieve_username.clear()
        self.ui.entry_retreive_name.setFocus()

    # =====================================================================================
    # =====================================================================================

    # delete entry by title function
    def show_entries(self):
        self.ui.lbl_welcome.setText("Display Database Entries")
        self.ui.stackedWidget.setCurrentIndex(5)

        global DB_FILE
        global MASTER_PASSWORD

        if DB_FILE == "" or MASTER_PASSWORD == "":
            QMessageBox.information(
                self,
                "Information",
                "Please create a new database or use an existing database to display the contents.",
            )
            return
        try:
            with pykeepass.PyKeePass(DB_FILE, password=MASTER_PASSWORD) as kp:
                entrieses = kp.entries
                self.populate_table(entrieses)
        except Exception as e:
            QMessageBox.information(
                self, "Information", f"Error retrieving entries:{str(e)}"
            )

    # populate entries in table
    def populate_table(self, entries):
        self.ui.tableWidget.clear()
        self.ui.tableWidget.setRowCount(len(entries))
        self.ui.tableWidget.setColumnCount(3)
        self.ui.tableWidget.setHorizontalHeaderLabels(["Title", "Username", "URL"])

        for row, entry in enumerate(entries):
            title_item = QTableWidgetItem(entry.title)
            username_item = QTableWidgetItem(entry.username)
            url_item = QTableWidgetItem(entry.url)

            self.ui.tableWidget.setItem(row, 0, title_item)
            self.ui.tableWidget.setItem(row, 1, username_item)
            self.ui.tableWidget.setItem(row, 2, url_item)

    def delete_entry(self):
        pass

    # =====================================================================================
    # =====================================================================================

    # analyse password function
    def analyze_password(self):
        self.ui.lbl_welcome.setText("Analyse Password")
        self.ui.stackedWidget.setCurrentIndex(6)
        self.ui.entry_analyse.setEchoMode(QLineEdit.Password)

        self.delete_entry_analyse()
        #
        self.ui.btn_confirm_5.clicked.connect(self.confirm_analyse_password)
        self.ui.btn_delete_fields_5.clicked.connect(self.delete_entry_analyse)

    def confirm_analyse_password(self):
        while True:
            password = self.ui.entry_analyse.text()

            if password.strip() == "":
                QMessageBox.warning(
                    self, "Warning", "Password cannot be empty. Please try again."
                )
                self.delete_entry_analyse()
                return
            else:
                break

        # Generate SHA-1 hash of the password
        sha1_password = hashlib.sha1(password.encode("utf-8")).hexdigest().upper()
        sha1_prefix = sha1_password[:5]
        sha1_suffix = sha1_password[5:]

        try:
            response = requests.get(
                f"https://api.pwnedpasswords.com/range/{sha1_prefix}"
            )
            if response.status_code == 200:
                password_hashes = response.text.splitlines()
                found = False

                # Check if the password hash suffix exists in the response
                for password_hash in password_hashes:
                    if sha1_suffix in password_hash:
                        count = int(password_hash.split(":")[1])
                        QMessageBox.warning(
                            self,
                            "Warning",
                            f"The password <font color='red'>{password}</font> has been found in <font color='red'>{count}</font> data breaches.",
                        )
                        found = True
                        break

                if not found:
                    QMessageBox.warning(
                        self,
                        "Warning ",
                        f"The password <font color='red'>{password}</font> has not been found in any data breaches.",
                    )
                else:
                    QMessageBox.information(
                        self,
                        "Information",
                        "Tip: This password has been compromised in a data breach.\nIt is strongly recommended to choose a different and more secure password.",
                    )
            elif response.status_code == 404:
                QMessageBox.warning(
                    self,
                    "Warning",
                    "Sorry an error 404 was detected, check your internet connection",
                )
            else:
                QMessageBox.warning(
                    self, "Warning", "An error occurred while analyzing the password."
                )
        except Exception as e:
            QMessageBox.warning(
                self,
                "Warning",
                "Error analyzing password.\nContact for support at ssecurity@gmail.com",
            )

    def delete_entry_analyse(self):
        self.ui.entry_analyse.clear()
        self.ui.entry_analyse.setFocus()

    # =====================================================================================
    # =====================================================================================

    # logout function
    def logout(self):        
        print("Application is logout...")

    # execcute the program

if __name__ == "__main__":
    app = QApplication(sys.argv)
    # Create an instance of the main window
    main_window = MainWindow()
    # Show the main window
    main_window.show()
    # Start the application event loop
    sys.exit(app.exec())
