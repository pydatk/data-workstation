#!/usr/bin/bash
set -e

echo -e "\nVisual Studio Code will open. Wait for it to load, minimize the VS Code window then return to setup.\n"

read -p "Press any key to open VS Code... "

code

echo -e "\nWhen Visual Studio Code has opened and been minimized, continue setup.\n"

read -p "Press any key to continue setup... "

gsettings set org.gnome.shell favorite-apps "['code.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Calculator.desktop', 'org.gnome.SystemMonitor.desktop', 'libreoffice-calc.desktop', 'org.gnome.TextEditor.desktop', 'brave-browser.desktop', 'org.gnome.Nautilus.desktop']"