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
titlebar-font='SF Pro Display Bold 11'
theme='Colloid-Dark'

[org.gnome.settings-daemon.plugins.xsettings]
overrides={'Gtk/Theme': <'Colloid-Dark'>}

[org.gnome.shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com']
favorite-apps=['app.zen_browser.zen.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Software.desktop']

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