# Autux

**Autux** (Auto-Usr-Termux) is a powerful ADB automation toolkit designed for Termux on Android. It empowers users to automate, control, and script Android devices directly from the terminal, combining the flexibility of Python and Bash with the power of ADB.

---

## 🚀 Features

- **One-Command Android Automation:** Tap, swipe, hold, input text, launch/kill apps, capture screenshots, record screen, and more—all from your terminal.
- **Gesture Recording:** Log and record tap, swipe, and hold gestures with synchronized screen video.
- **Custom Notifications & Toasts:** Send Android notifications and toast messages programmatically.
- **App Management:** Launch or force-stop apps by package name or user-friendly alias.
- **Wireless ADB Management:** Automate ADB over TCP/IP setup and semi-persistent connections.
- **Settings & Aliases:** Easily manage app aliases, IPs, and session settings via a simple JSON config.
- **Session Management:** Auto-apply settings, clear histories, and manage environment on each boot.
- **Extensible & Scriptable:** Built with modular Python and Bash scripts for easy extension and integration.
- **Cross-Language:** Works directly in the Terminal, Shell Scripts and Python Scripts with an import, at any terminal location.
- **Semi-Persistent:** Attempts to give semi-persistent ADB Acess to continue using Autux Automation while dissconnected from wifi and Wireless Debugging Disabled. Method of persistence is not stable so it may or may not work, See Persistence Help below for more information.

---

## 📦 Installation

> **Requirements:**
>
> - USB ADB Connection to a Seperate PC
> - Wifi Connection
> - Developer Options Enabled
> - USB Debugging Enabled
> - Wireless Debugng Enabled
> - Default USB mode set to 'Transfer Files'
> - Storage permissions enabled in Termux
> - A Main Repository Selected

1. **Clone the Repo :**

   ```sh
   git clone https://github.com/YourUser/Autux.git
   cd Autux
   ```

2. **Run the Setup Script :**

   ```sh
   bash src/bin/__setup__.sh
   ```

3. **Configure Settings (Optional):**
   - Edit `src/configs/settings.jsonc` to add your device IPs, app aliases, and preferences.

## 🛠️ Usage Examples

- **Tap at (x, y):**

  ```sh
  autux --tap 500 800
  ```

- **Swipe from (x1, y1) to (x2, y2):**

  ```sh
  autux --swipe 100 200 300 400
  ```

- **Send Text Input:**

  ```sh
  autux --txt "Hello World"
  ```

- **Launch an App by Alias:**

  ```sh
  autux --app Orna
  ```

- **Record Gestures & Screen:**

  ```sh
  autux --taprec
  ```

- **Show Version:**

  ```sh
  autux --version
  ```

---

## ⚙️ Configuration

Edit `src/configs/settings.jsonc` to:

- Add or update device IPs for ADB connection (Or use autux --ipenw)
- Enable/disable session features
- Define app aliases for quick launching (Or use autux --coms)
- Customize shell and session behaviors

---

## Persistence Help

True Persistence without root is impossible due to android resirictions. Autux attemps to give semi-persistent ADB access by may not give persistence.

- Using a connected ADB PC to set the devices adbd to tcpip port 5555, giving autux the ability to connect with adb connect 'IP_Address':5555
- Using the ADB Access to give Termux extra device permissions
- Using those permissions to setprop service.adb.tcp.port 5555, keeping the port open for Autux to connect
- Typically, Autux Persistance will remain as long as you don 't manually toggle Usb or Wireless Debugging On or Off, Wifi On or Off, Airplane Mode On or Off, or restart the device
- ADB is prohibted from loopback connecting, and connections are to be only accessible from a usb connected pc or authorized wireless debugging from another device on the same wifi network. So when any of those things toggle, Android naturally resets adbd to port 5037 (The usb Port), preventing Autux from connecting. But when the setprop is able to keep it at port 5555, connection persists regarldess of connections or state.
- And it is for this reason persistence is not stable, and upon complete port resets to 5037, you must reconnect to a pc via usb and run adb tcpip 5555 again to reenable Autux.
- Having Persistence and no wifi then connecting to a new network that has not add the given ip address added to autux, will typically cause port resets as well.

## Author

GitHub: [AngrySatan666](https://github.com/AngrySatan666)

---

> **Autux**: Take full control of your Android device—right from your terminal.
