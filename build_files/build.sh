#!/bin/bash

set -oue pipefail

echo "=== Building Avios - Professional Linux Desktop ==="

# Install essential dependencies
rpm-ostree install \
    gtk-murrine-engine gtk2-engines \
    kvantum \
    gnome-tweaks git sassc \
    curl wget unzip \
    gnome-themes-extra \

# Install WhiteSur GTK Theme (macOS Big Sur style)
echo "Installing WhiteSur Theme..."
curl -L https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/heads/master.zip -o /tmp/whitesur.zip
unzip -q /tmp/whitesur.zip -d /tmp

cd /tmp/WhiteSur-gtk-theme-master

# Make script executable and install with minimal options to avoid issues
chmod +x install.sh

# Install both variants with macOS-style window controls
./install.sh -d /usr/share/themes -c Light -t all -N glassy --round || echo "Light theme install had issues, continuing..."
./install.sh -d /usr/share/themes -c Dark -t all -N glassy --round || echo "Dark theme install had issues, continuing..."

# Install WhiteSur Shell Theme for GNOME Shell
echo "Installing WhiteSur Shell Theme..."
./install.sh -l -d /usr/share/themes -c Dark -t all || echo "Shell theme install had issues, continuing..."

# Install WhiteSur icon theme
echo "Installing WhiteSur Icon Theme..."
curl -L https://github.com/vinceliuice/WhiteSur-icon-theme/archive/refs/heads/master.zip -o /tmp/whitesur-icons.zip
unzip -q /tmp/whitesur-icons.zip -d /tmp
cd /tmp/WhiteSur-icon-theme-master
chmod +x install.sh
./install.sh -d /usr/share/icons || echo "Icon theme install had issues, continuing..."

# Install WhiteSur cursor theme
echo "Installing WhiteSur Cursors..."
curl -L https://github.com/vinceliuice/WhiteSur-cursors/archive/refs/heads/master.zip -o /tmp/whitesur-cursors.zip
unzip -q /tmp/whitesur-cursors.zip -d /tmp
cd /tmp/WhiteSur-cursors-master
chmod +x install.sh
./install.sh -d /usr/share/icons || echo "Cursor theme install had issues, continuing..."

# Setup Qt theming with Kvantum
echo "Setting up Qt theming..."
mkdir -p /usr/share/Kvantum
curl -L https://github.com/vinceliuice/WhiteSur-kde/archive/refs/heads/master.zip -o /tmp/whitesur-kvantum.zip
unzip -q /tmp/whitesur-kvantum.zip -d /tmp
if [ -d "/tmp/WhiteSur-kde-master/Kvantum" ]; then
    cp -r /tmp/WhiteSur-kde-master/Kvantum/* /usr/share/Kvantum/ || echo "Kvantum setup had issues, continuing..."
else
    echo "Kvantum themes not found, skipping Qt theming..."
fi

# Create system-wide Qt configuration
mkdir -p /etc/xdg/qt5ct
mkdir -p /etc/xdg/qt6ct

cat > /etc/xdg/qt5ct/qt5ct.conf << 'EOF'
[Appearance]
style=kvantum-dark
color_scheme_path=/usr/share/qt5ct/colors/darker.conf
custom_palette=false
icon_theme=WhiteSur-dark
standard_dialogs=default

[Fonts]
fixed="SF Mono,10,-1,5,50,0,0,0,0,0"
general="SF Pro Display,10,-1,5,50,0,0,0,0,0"
EOF

cat > /etc/xdg/qt6ct/qt6ct.conf << 'EOF'
[Appearance]
style=kvantum-dark
color_scheme_path=/usr/share/qt6ct/colors/darker.conf
custom_palette=false
icon_theme=WhiteSur-dark
standard_dialogs=default

[Fonts]
fixed="SF Mono,10,-1,5,50,0,0,0,0,0"
general="SF Pro Display,10,-1,5,50,0,0,0,0,0"
EOF

# Clean up theme downloads
rm -rf /tmp/WhiteSur-* /tmp/whitesur*.zip

# Install San Francisco Pro fonts
echo "Installing San Francisco Pro fonts..."
mkdir -p /usr/share/fonts/sf-pro
curl -L "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/archive/master.zip" -o /tmp/sf-fonts.zip
unzip -q /tmp/sf-fonts.zip -d /tmp
cp /tmp/San-Francisco-Pro-Fonts-master/*.otf /usr/share/fonts/sf-pro/
fc-cache -f -v
rm -rf /tmp/sf-fonts.zip /tmp/San-Francisco-Pro-Fonts-master

# Install GNOME Shell Extensions
echo "Installing GNOME Shell extensions..."

# Install User Themes extension (essential for shell theming)
mkdir -p /usr/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com
curl -L "https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v64.shell-extension.zip" -o /tmp/user-theme.zip
unzip -q -o /tmp/user-theme.zip -d /usr/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com
rm -f /tmp/user-theme.zip

# Install Dash to Dock GNOME Shell Extension
mkdir -p /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
curl -L "https://github.com/micheleg/dash-to-dock/releases/download/extensions.gnome.org-v100/dash-to-dock@micxgx.gmail.com.zip" -o /tmp/dash-to-dock.zip
unzip -q -o /tmp/dash-to-dock.zip -d /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
rm -f /tmp/dash-to-dock.zip

# Install WhiteSur Dash to Dock Theme
echo "Installing WhiteSur Dash to Dock theme..."
curl -L https://github.com/vinceliuice/WhiteSur-gtk-theme/raw/master/src/other/dash-to-dock/whitesur.css -o /tmp/whitesur-dash.css
mkdir -p /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/themes
cp /tmp/whitesur-dash.css /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/themes/
rm -f /tmp/whitesur-dash.css

# Install Zen Browser from Flathub
echo "Installing Zen Browser..."
flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y flathub app.zen_browser.zen

# Create Zen Browser wrapper
if [ ! -d "/usr/local/bin" ]; then
    mkdir -p /usr/local/bin || echo "Could not create /usr/local/bin, skipping wrapper..."
fi

if [ -d "/usr/local/bin" ]; then
    cat > /usr/local/bin/zen-browser << 'EOF' || echo "Could not create zen-browser wrapper"
#!/bin/bash
exec flatpak run app.zen_browser.zen "$@"
EOF
    chmod +x /usr/local/bin/zen-browser 2>/dev/null || echo "Could not make zen-browser executable"
else
    echo "Skipping Zen Browser wrapper creation"
fi

# Remove Firefox and related packages
rpm-ostree override remove firefox firefox-langpacks || true
rpm-ostree override remove mozilla-filesystem || true

# Enable essential services
systemctl enable podman.socket

# Create Avios system configuration
echo "Creating Avios system defaults..."
mkdir -p /etc/dconf/db/local.d
mkdir -p /etc/dconf/profile
mkdir -p /etc/dconf/db/local.d/locks

# Create dconf user profile
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF

# Create Avios system defaults
cat > /etc/dconf/db/local.d/00-avios-defaults << 'EOF'
# Avios Professional Desktop Defaults

[org/gnome/desktop/interface]
gtk-theme='WhiteSur-Dark'
icon-theme='WhiteSur-dark'
cursor-theme='WhiteSur-cursors'
font-name='SF Pro Display 11'
document-font-name='SF Pro Display 11'
monospace-font-name='SF Mono 10'
clock-show-weekday=true
show-battery-percentage=true
enable-animations=true
color-scheme='prefer-dark'

[org/gnome/desktop/wm/preferences]
titlebar-font='SF Pro Display Bold 11'
button-layout='close,minimize,maximize:'
theme='WhiteSur-Dark'

[org/gnome/shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com', 'user-theme@gnome-shell-extensions.gcampax.github.com']
favorite-apps=['app.zen_browser.zen.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Software.desktop']

[org/gnome/shell/extensions/user-theme]
name='WhiteSur-Dark'

[org/gnome/shell/extensions/dash-to-dock]
dock-position='bottom'
dock-fixed=true
intellihide=false
autohide=false
extend-height=false
dash-max-icon-size=48
show-favorites=true
show-running=true
show-show-apps-button=true
apply-custom-theme=false
custom-theme-shrink=true
custom-theme-running-dots=true
custom-theme-customize-running-dots=true
running-indicator-style='METRO'
transparency-mode='DYNAMIC'
background-opacity=0.3
custom-background-color=false
animate-show-apps=true
animation-time=0.2
hide-delay=0.2
show-delay=0.25
pressure-threshold=100.0
height-fraction=0.9

[org/gnome/mutter]
center-new-windows=true
dynamic-workspaces=true
experimental-features=['scale-monitor-framebuffer']

[org/gnome/desktop/sound]
theme-name='ocean'

[org/gnome/desktop/background]
picture-options='zoom'
primary-color='#1e1e1e'

[org/gnome/desktop/screensaver]
picture-options='zoom'
primary-color='#1e1e1e'

[org/gnome/desktop/wm/keybindings]
close=['<Super>q']
minimize=['<Super>m']
toggle-fullscreen=['<Super>f']

[org/gnome/settings-daemon/plugins/media-keys]
home=['<Super>e']
www=['<Super>b']
EOF

# Lock critical settings
cat > /etc/dconf/db/local.d/locks/00-avios-locks << 'EOF'
/org/gnome/shell/enabled-extensions
/org/gnome/desktop/interface/gtk-theme
/org/gnome/desktop/interface/icon-theme
/org/gnome/desktop/interface/cursor-theme
EOF

# Update dconf database
dconf update

# Create Avios first-boot setup
mkdir -p /usr/share/avios
cat > /usr/share/avios/first-boot-setup.sh << 'EOF'
#!/bin/bash
# Avios First Boot Setup

# Ensure themes are applied for current user
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Apply fonts
gsettings set org.gnome.desktop.interface font-name 'SF Pro Display 11'
gsettings set org.gnome.desktop.interface document-font-name 'SF Pro Display 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'SF Mono 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'SF Pro Display Bold 11'

# Enable extensions and configure
gsettings set org.gnome.shell enabled-extensions "['dash-to-dock@micxgx.gmail.com', 'user-theme@gnome-shell-extensions.gcampax.github.com']"

# Configure User Themes extension for shell theming
gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Dark'

# Configure Dash to Dock with WhiteSur theme
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme false
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots true
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-customize-running-dots true
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'METRO'
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'DYNAMIC'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.3
gsettings set org.gnome.shell.extensions.dash-to-dock custom-background-color false
gsettings set org.gnome.shell.extensions.dash-to-dock animate-show-apps true
gsettings set org.gnome.shell.extensions.dash-to-dock animation-time 0.2

# Set favorite applications
gsettings set org.gnome.shell favorite-apps "['app.zen_browser.zen.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Software.desktop']"

# Set Qt theme environment
mkdir -p "$HOME/.config/environment.d"
cat > "$HOME/.config/environment.d/qt-theme.conf" << 'QTEOF'
QT_QPA_PLATFORMTHEME=qt5ct
QTEOF

# Apply window manager theme for traffic light buttons
gsettings set org.gnome.desktop.wm.preferences theme 'WhiteSur-Dark'

# Restart GNOME Shell to apply all theme changes (if not on Wayland)
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    nohup bash -c 'sleep 3 && killall -3 gnome-shell' >/dev/null 2>&1 &
fi

echo "Avios setup completed successfully - theme changes will be visible after next login"
EOF

chmod +x /usr/share/avios/first-boot-setup.sh

# Create autostart entry
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/avios-first-boot.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Avios First Boot Setup
Exec=/usr/share/avios/first-boot-setup.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=2
OnlyShowIn=GNOME;
EOF

# Create theme switcher script for users
if [ -d "/usr/local/bin" ]; then
    cat > /usr/local/bin/avios-theme-switcher << 'EOF' || echo "Could not create theme switcher"
#!/bin/bash
# Avios Theme Switcher - Switch between Light and Dark modes

case "${1:-}" in
    "light")
        gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Light'
        gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-light'
        gsettings set org.gnome.desktop.interface color-scheme 'default'
        gsettings set org.gnome.desktop.wm.preferences theme 'WhiteSur-Light'
        gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Light'
        echo "Switched to Avios Light theme"
        ;;
    "dark")
        gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
        gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.wm.preferences theme 'WhiteSur-Dark'
        gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Dark'
        echo "Switched to Avios Dark theme"
        ;;
    *)
        echo "Usage: avios-theme-switcher [light|dark]"
        echo "Current theme: $(gsettings get org.gnome.desktop.interface gtk-theme)"
        ;;
esac
EOF
    chmod +x /usr/local/bin/avios-theme-switcher 2>/dev/null || echo "Could not make theme switcher executable"
else
    echo "Skipping theme switcher creation"
fi

echo "=== Avios build completed successfully! ==="