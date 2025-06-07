#!/bin/bash

set -oue pipefail

echo "=== Building Avios - Professional Linux Desktop ==="

# Install essential dependencies
rpm-ostree install \
    gnome-tweaks git \
    curl wget unzip \
    gnome-themes-extra \

# Install San Francisco Pro fonts
echo "Installing San Francisco Pro fonts..."
mkdir -p /usr/share/fonts/sf-pro
curl -L "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/archive/master.zip" -o /tmp/sf-fonts.zip
unzip -q /tmp/sf-fonts.zip -d /tmp
cp /tmp/San-Francisco-Pro-Fonts-master/*.otf /usr/share/fonts/sf-pro/
fc-cache -f -v
rm -rf /tmp/sf-fonts.zip /tmp/San-Francisco-Pro-Fonts-master

# Install Colloid icon theme (modern, clean icons that complement the Colloid theme)
echo "Installing Colloid icon theme..."
git clone https://github.com/vinceliuice/Colloid-icon-theme.git /tmp/colloid-icons
mkdir -p /usr/share/icons
cd /tmp/colloid-icons
./install.sh -d /usr/share/icons
cd /
rm -rf /tmp/colloid-icons

# Install GNOME Shell Extensions
echo "Installing GNOME Shell extensions..."

# Install Dash to Panel (modern bottom panel like macOS)
mkdir -p /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com
curl -L "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v68.shell-extension.zip" -o /tmp/dash-to-panel.zip
unzip -q -o /tmp/dash-to-panel.zip -d /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com
rm -f /tmp/dash-to-panel.zip


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

# Create Avios system defaults (minimal, macOS-inspired)
cat > /etc/dconf/db/local.d/00-avios-defaults << 'EOF'
# Avios Professional Desktop Defaults

[org/gnome/desktop/interface]
icon-theme='Colloid-dark'
font-name='SF Pro Display 11'
document-font-name='SF Pro Display 11'
monospace-font-name='SF Mono 10'
clock-show-weekday=true
show-battery-percentage=true
enable-animations=true

[org/gnome/desktop/wm/preferences]
titlebar-font='SF Pro Display Bold 11'
# Keep default GNOME button layout
button-layout='appmenu:minimize,maximize,close'

[org/gnome/shell]
enabled-extensions=['dash-to-panel@jderose9.github.com', 'appindicatorsupport@rgcjonas.gmail.com', 'just-perfection-desktop@just-perfection']
favorite-apps=['app.zen_browser.zen.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Software.desktop', 'org.gnome.Settings.desktop']

[org/gnome/shell/extensions/dash-to-panel]
panel-positions='{"0":"BOTTOM"}'
panel-lengths='{"0":100}'
panel-sizes='{"0":48}'
appicon-margin=8
appicon-padding=4
dot-position='BOTTOM'
dot-style-focused='METRO'
dot-style-unfocused='DOTS'
group-apps=true
isolate-workspaces=false
show-activities-button=false
show-appmenu=false
show-clock=true
show-desktop=true
show-window-previews=true
leftbox-padding=-1
centerbox-padding=-1
rightbox-padding=-1
stockgs-keep-dash=false
stockgs-keep-top-panel=true
panel-element-positions='{"0":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'

[org/gnome/shell/extensions/just-perfection]
accessibility-menu=false
activities-button=false
app-menu=false
clock-menu-position=1
dash=false
osd=true
panel=true
panel-in-overview=true
ripple-box=false
search=true
show-apps-button=true
startup-status=0
theme=false
top-panel=true
window-demands-attention-focus=false
window-picker-icon=true
workspace=true
workspace-popup=false
workspaces-in-app-grid=false

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
# Add some macOS-inspired keybindings
close=['<Super>q', '<Alt>F4']
minimize=['<Super>m']
toggle-fullscreen=['<Super>f']

[org/gnome/settings-daemon/plugins/media-keys]
home=['<Super>e']
www=['<Super>b']
EOF

# Lock critical settings
cat > /etc/dconf/db/local.d/locks/00-avios-locks << 'EOF'
/org/gnome/shell/enabled-extensions
/org/gnome/desktop/interface/icon-theme
EOF

# Update dconf database
dconf update

# Create Avios first-boot setup
mkdir -p /usr/share/avios
cat > /usr/share/avios/first-boot-setup.sh << 'EOF'
#!/bin/bash
# Avios First Boot Setup

# Apply fonts
gsettings set org.gnome.desktop.interface font-name 'SF Pro Display 11'
gsettings set org.gnome.desktop.interface document-font-name 'SF Pro Display 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'SF Mono 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'SF Pro Display Bold 11'

# Set icon theme
gsettings set org.gnome.desktop.interface icon-theme 'Colloid-dark'

# Enable extensions
gsettings set org.gnome.shell enabled-extensions "['dash-to-panel@jderose9.github.com', 'appindicatorsupport@rgcjonas.gmail.com', 'just-perfection-desktop@just-perfection']"

# Configure Dash to Panel for modern bottom bar
gsettings set org.gnome.shell.extensions.dash-to-panel panel-positions '{"0":"BOTTOM"}'
gsettings set org.gnome.shell.extensions.dash-to-panel panel-lengths '{"0":100}'
gsettings set org.gnome.shell.extensions.dash-to-panel panel-sizes '{"0":48}'
gsettings set org.gnome.shell.extensions.dash-to-panel appicon-margin 8
gsettings set org.gnome.shell.extensions.dash-to-panel appicon-padding 4
gsettings set org.gnome.shell.extensions.dash-to-panel dot-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-focused 'METRO'
gsettings set org.gnome.shell.extensions.dash-to-panel dot-style-unfocused 'DOTS'
gsettings set org.gnome.shell.extensions.dash-to-panel group-apps true
gsettings set org.gnome.shell.extensions.dash-to-panel show-activities-button false
gsettings set org.gnome.shell.extensions.dash-to-panel show-appmenu false
gsettings set org.gnome.shell.extensions.dash-to-panel stockgs-keep-dash false

# Configure Just Perfection for cleaner experience
gsettings set org.gnome.shell.extensions.just-perfection activities-button false
gsettings set org.gnome.shell.extensions.just-perfection app-menu false
gsettings set org.gnome.shell.extensions.just-perfection dash false

# Set favorite applications
gsettings set org.gnome.shell favorite-apps "['app.zen_browser.zen.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Software.desktop', 'org.gnome.Settings.desktop']"

echo "Avios setup completed successfully - changes will be visible after next login"
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

echo "=== Avios build completed successfully! ==="