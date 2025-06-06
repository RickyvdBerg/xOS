#!/bin/bash

set -oue pipefail

# Install dependencies
rpm-ostree install gtk-murrine-engine gtk2-engines kvantum qt5ct qt6ct \
    gnome-tweaks git gnome-themes-extra sassc curl wget unzip

# Install Colloid from source with manual libadwaita setup
curl -L https://github.com/vinceliuice/Colloid-gtk-theme/archive/refs/heads/master.zip -o /tmp/colloid.zip
unzip /tmp/colloid.zip -d /tmp

# Install themes normally (without -l flag to avoid /root directory issues)
/tmp/Colloid-gtk-theme-main/install.sh -d /usr/share/themes -t all -c dark
/tmp/Colloid-gtk-theme-main/install.sh -d /usr/share/themes -t all -c light

# Manually setup libadwaita theming for GTK4 apps (replicating what -l flag does)
echo "Setting up libadwaita theming manually..."

# Create system-wide gtk-4.0 config directory
mkdir -p /etc/gtk-4.0

# Copy assets for libadwaita (matching the install script logic)
cp -r /tmp/Colloid-gtk-theme-main/src/assets/gtk/assets /etc/gtk-4.0/
cp -r /tmp/Colloid-gtk-theme-main/src/assets/gtk/symbolics/*.svg /etc/gtk-4.0/assets/

# Prepare tweaks (this is what theme_tweaks() does)
cd /tmp/Colloid-gtk-theme-main
cp -rf "src/sass/_tweaks.scss" "src/sass/_tweaks-temp.scss"

# Set GNOME Shell version for compatibility
SHELL_VERSION="$(gnome-shell --version 2>/dev/null | cut -d ' ' -f 3 | cut -d . -f -1)" || SHELL_VERSION="48"
if [[ "${SHELL_VERSION:-}" -ge "47" ]]; then
    sed -i "/\gnome_version/s/default/new/" "src/sass/_tweaks-temp.scss"
fi

# Compile libadwaita themes for both Light and Dark variants
# This matches the conditional logic in libadwaita_theme() function
sassc -M -t expanded "src/main/libadwaita/libadwaita-Light.scss" "/etc/gtk-4.0/gtk.css"
sassc -M -t expanded "src/main/libadwaita/libadwaita-Dark.scss" "/etc/gtk-4.0/gtk-dark.css"

# Create user config template directory 
mkdir -p /usr/share/gtk-4.0
cp -r /etc/gtk-4.0/* /usr/share/gtk-4.0/

# Also create skeleton config for new users
mkdir -p /etc/skel/.config/gtk-4.0
ln -sf /etc/gtk-4.0/assets /etc/skel/.config/gtk-4.0/assets
ln -sf /etc/gtk-4.0/gtk.css /etc/skel/.config/gtk-4.0/gtk.css
ln -sf /etc/gtk-4.0/gtk-dark.css /etc/skel/.config/gtk-4.0/gtk-dark.css

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

# Install Colloid Cursor Theme
echo "Installing Colloid Cursor Theme..."
if git clone --depth 1 https://github.com/vinceliuice/Colloid-icon-theme.git /tmp/Colloid-cursors; then
    (cd /tmp/Colloid-cursors && ./install.sh -c -d /usr/share/icons)
    echo "Colloid Cursor Theme installed."
else
    echo "ERROR: Failed to clone Colloid Cursor Theme repository."
fi
rm -rf /tmp/Colloid-cursors

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

# Install Zen Browser from Flathub
echo "Installing Zen Browser from Flathub..."
# Add Flathub remote if not already configured
flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Install Zen Browser as a system-wide Flatpak
flatpak install --system -y flathub app.zen_browser.zen

# Create symbolic link for easier access
# Create the wrapper script (skip if /usr/local/bin creation fails)
cat > /usr/local/bin/zen-browser << 'EOF' || true
#!/bin/bash
flatpak run app.zen_browser.zen "$@"
EOF
chmod +x /usr/local/bin/zen-browser 2>/dev/null || true

echo "Zen Browser installed from Flathub."

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


### Create system-wide dconf defaults (Bluefin-style approach)
echo "Creating system-wide dconf defaults..."

# Create dconf system database directory
mkdir -p /etc/dconf/db/local.d
mkdir -p /etc/dconf/profile

# Create user profile to use system defaults
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF

# Create system defaults database
cat > /etc/dconf/db/local.d/00-xos-defaults << 'EOF'
# xOS System Defaults

[org/gnome/desktop/interface]
gtk-theme='Colloid-Dark'
icon-theme='Colloid-Dark'
cursor-theme='Colloid-cursors'
font-name='SF Pro Display 11'
document-font-name='SF Pro Display 11'
monospace-font-name='SF Mono 10'
clock-show-weekday=true
show-battery-percentage=true
enable-animations=true

[org/gnome/desktop/wm/preferences]
titlebar-font='SF Pro Display Bold 11'

[org/gnome/desktop/sound]
theme-name='ocean'

[org/gnome/shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com']
favorite-apps=['app.zen_browser.zen.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Software.desktop']

[org/gnome/shell/extensions/dash-to-dock]
dock-position='BOTTOM'
dock-fixed=false
intellihide=false
autohide=false
extend-height=false
height-fraction=0.9
dash-max-icon-size=48
icon-size-fixed=false
show-favorites=true
show-running=true
show-apps-at-top=false
show-show-apps-button=true
animate-show-apps=true
click-action='CYCLE'
scroll-action='CYCLE_WINDOWS'
running-indicator-style='DOTS'
apply-custom-theme=true
custom-theme-shrink=false
transparency-mode='ADAPTIVE'
background-opacity=0.8
custom-background-color=false
hot-keys=true
shortcut=['<Super>q']

[org/gnome/desktop/background]
picture-options='zoom'
primary-color='#000000'

[org/gnome/desktop/screensaver]
picture-options='zoom'
primary-color='#000000'

[org/gnome/mutter]
center-new-windows=true
dynamic-workspaces=true

[org/gnome/shell/app-switcher]
current-workspace-only=false

[org/gnome/desktop/wm/keybindings]
close=['<Super>q']
minimize=['<Super>m']
toggle-fullscreen=['<Super>f']

[org/gnome/settings-daemon/plugins/media-keys]
home=['<Super>e']
www=['<Super>b']
EOF

# Create locks directory and lock certain settings
mkdir -p /etc/dconf/db/local.d/locks
cat > /etc/dconf/db/local.d/locks/00-xos-locks << 'EOF'
# Lock theme settings
/org/gnome/desktop/interface/gtk-theme
/org/gnome/desktop/interface/icon-theme
/org/gnome/desktop/interface/cursor-theme
/org/gnome/shell/enabled-extensions
EOF

# Update dconf database
dconf update

echo "System dconf defaults created and applied."

# Create first-boot setup script (Bluefin-style)
mkdir -p /usr/share/xos
cat > /usr/share/xos/first-boot-setup.sh << 'EOF'
#!/bin/bash
# xOS First Boot Setup Script

# Enable and configure Dash to Dock extension
gsettings set org.gnome.shell enabled-extensions "['dash-to-dock@micxgx.gmail.com']"

# Apply theme settings for current user
gsettings set org.gnome.desktop.interface gtk-theme 'Colloid-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Colloid-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Colloid-cursors'

# Configure Dash to Dock to be always visible
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme true
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'ADAPTIVE'

# Set favorite applications
gsettings set org.gnome.shell favorite-apps "['app.zen_browser.zen.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Software.desktop']"

# Apply fonts
gsettings set org.gnome.desktop.interface font-name 'SF Pro Display 11'
gsettings set org.gnome.desktop.interface document-font-name 'SF Pro Display 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'SF Mono 10'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'SF Pro Display Bold 11'

echo "xOS first boot setup completed"
EOF

chmod +x /usr/share/xos/first-boot-setup.sh

# Create autostart entry for first boot setup
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/xos-first-boot.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=xOS First Boot Setup
Exec=/usr/share/xos/first-boot-setup.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=3
OnlyShowIn=GNOME;
EOF