#!/bin/bash

set -oue pipefail

# Install dependencies
rpm-ostree install gtk-murrine-engine gtk2-engines kvantum qt5ct qt6ct \
    gnome-tweaks git gnome-themes-extra sassc curl wget unzip

# Install Colloid from source
curl -L https://github.com/vinceliuice/Colloid-gtk-theme/archive/refs/heads/master.zip -o /tmp/colloid.zip
unzip /tmp/colloid.zip -d /tmp
# Install themes without libadwaita integration to avoid /root directory issues
/tmp/Colloid-gtk-theme-main/install.sh -d /usr/share/themes -t all -c dark
/tmp/Colloid-gtk-theme-main/install.sh -d /usr/share/themes -t all -c light

rm -rf /tmp/Colloid-gtk-theme-main /tmp/colloid.zip

# Install Colloid Icon Theme from source
echo "Installing Colloid Icon Theme..."
if git clone --depth 1 https://github.com/vinceliuice/Colloid-icon-theme.git /tmp/Colloid-icon-theme; then
    (cd /tmp/Colloid-icon-theme && ./install.sh -d /usr/share/icons)
    echo "Colloid Icon Theme installed."
else
    echo "ERROR: Failed to clone Colloid Icon Theme repository."
fi
rm -rf /tmp/Colloid-icon-theme

# Install Dash to Dock GNOME Shell Extension
echo "Installing Dash to Dock GNOME Shell Extension..."
# Download pre-built release from GitHub
curl -L "https://github.com/micheleg/dash-to-dock/releases/download/extensions.gnome.org-v100/dash-to-dock@micxgx.gmail.com.zip" -o /tmp/dash-to-dock.zip
# Remove any existing extension directory and create fresh
rm -rf /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
mkdir -p /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
# Extract with overwrite flag to avoid prompts
unzip -q -o /tmp/dash-to-dock.zip -d /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com
rm -f /tmp/dash-to-dock.zip
echo "Dash to Dock installed."

# Install San Francisco Pro fonts (macOS-like)
echo "Installing San Francisco Pro fonts..."
mkdir -p /usr/share/fonts/sf-pro
curl -L "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/archive/master.zip" -o /tmp/sf-fonts.zip
unzip -q /tmp/sf-fonts.zip -d /tmp
cp /tmp/San-Francisco-Pro-Fonts-master/*.otf /usr/share/fonts/sf-pro/
fc-cache -f -v
rm -rf /tmp/sf-fonts.zip /tmp/San-Francisco-Pro-Fonts-master

# Install Zen Browser
echo "Installing Zen Browser..."
ZEN_VERSION=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -L "https://github.com/zen-browser/desktop/releases/download/${ZEN_VERSION}/zen-linux-x86_64.tar.xz" -o /tmp/zen-browser.tar.xz
tar -xf /tmp/zen-browser.tar.xz -C /tmp
mkdir -p /usr/share/zen-browser
cp -r /tmp/zen/* /usr/share/zen-browser/
ln -sf /usr/share/zen-browser/zen-bin /usr/local/bin/zen-browser

# Create Zen Browser desktop entry
cat > /usr/share/applications/zen-browser.desktop << EOF
[Desktop Entry]
Version=1.0
Name=Zen Browser
Comment=Experience tranquillity while browsing the web without people tracking you!
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer
Exec=/usr/share/zen-browser/zen-bin %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=/usr/share/zen-browser/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
EOF

rm -rf /tmp/zen-browser.tar.xz /tmp/zen

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux 

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket


### Apply System-wide GNOME Settings via GSchema overrides
echo "Applying GSettings via GSchema overrides..."
OVERRIDE_FILE="/usr/share/glib-2.0/schemas/90_xos-defaults.gschema.override"
mkdir -p "$(dirname "${OVERRIDE_FILE}")"
cat > "${OVERRIDE_FILE}" << EOF
[org.gnome.desktop.interface]
gtk-theme='Colloid-Dark'
icon-theme='Colloid-Dark'
font-name='SF Pro Display 11'
document-font-name='SF Pro Display 11'
monospace-font-name='SF Mono 10'
cursor-theme='Adwaita'
clock-show-weekday=true
show-battery-percentage=true
enable-animations=true

[org.gnome.desktop.wm.preferences]
button-layout='close,minimize,maximize:'
titlebar-font='SF Pro Display Bold 11'

[org.gnome.shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com']
favorite-apps=['zen-browser.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Software.desktop']

[org.gnome.shell.extensions.dash-to-dock]
dock-position='BOTTOM'
dock-fixed=false
intellihide=true
intellihide-mode='FOCUS_APPLICATION_WINDOWS'
autohide=true
autohide-in-fullscreen=false
extend-height=false
height-fraction=0.9
dash-max-icon-size=48
icon-size-fixed=false
show-favorites=true
show-running=true
show-apps-at-top=false
show-show-apps-button=true
animate-show-apps=false
click-action='CYCLE'
scroll-action='CYCLE_WINDOWS'
running-indicator-style='DOTS'
apply-custom-theme=false
custom-theme-shrink=false
transparency-mode='FIXED'
background-opacity=0.8
custom-background-color=false

[org.gnome.desktop.background]
picture-options='zoom'
primary-color='#000000'
secondary-color='#000000'

[org.gnome.desktop.screensaver]
picture-options='zoom'
primary-color='#000000'
secondary-color='#000000'

[org.gnome.mutter]
center-new-windows=true
dynamic-workspaces=true

[org.gnome.shell.app-switcher]
current-workspace-only=false

[org.gnome.desktop.wm.keybindings]
switch-applications=['<Alt>Tab']
switch-applications-backward=['<Shift><Alt>Tab']
switch-windows=['<Super>Tab']
switch-windows-backward=['<Shift><Super>Tab']
close=['<Super>q']
minimize=['<Super>m']
toggle-fullscreen=['<Super>f']

[org.gnome.settings-daemon.plugins.media-keys]
home=['<Super>e']
www=['<Super>b']
EOF

# Recompile GSchema to apply the overrides
if command -v glib-compile-schemas &> /dev/null; then
    echo "Compiling GSettings schemas..."
    glib-compile-schemas /usr/share/glib-2.0/schemas/
else
    echo "WARNING: glib-compile-schemas command not found. System-wide GSettings might not be applied correctly."
fi