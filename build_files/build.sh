#!/bin/bash

set -oue pipefail

# Install dependencies
rpm-ostree install gtk-murrine-engine gtk2-engines kvantum qt5ct qt6ct \
    gnome-tweaks git sassc gnome-themes-extra

# Install Colloid from source
echo "Installing Colloid GTK Theme..."
curl -L https://github.com/vinceliuice/Colloid-gtk-theme/archive/refs/heads/master.zip -o /tmp/colloid.zip
unzip /tmp/colloid.zip -d /tmp

# Define source directories from the unzipped theme
COLLOID_SRC_ROOT="/tmp/Colloid-gtk-theme-main"
THEME_SRC_DIR="${COLLOID_SRC_ROOT}/src"
SASS_SRC_DIR="${THEME_SRC_DIR}/sass"
MAIN_SRC_DIR="${THEME_SRC_DIR}/main"

# Set environment for non-interactive installation
export DEBIAN_FRONTEND=noninteractive
export HOME=/tmp/build-home # Safety for any script part trying to write to $HOME
mkdir -p $HOME
mkdir -p /root/.config /root/.local/share/themes /root/.themes /root/.gnupg # Precaution

# --- Install Colloid-Dark Theme ---
THEME_NAME_DARK="Colloid-Dark"
DEST_DIR_DARK="/usr/share/themes/${THEME_NAME_DARK}"

echo "Preparing to install ${THEME_NAME_DARK}..."
mkdir -p "${DEST_DIR_DARK}/gtk-3.0" \
           "${DEST_DIR_DARK}/gtk-4.0" \
           "${DEST_DIR_DARK}/gnome-shell" \
           "${DEST_DIR_DARK}/xfwm4" \
           "${DEST_DIR_DARK}/cinnamon" \
           "${DEST_DIR_DARK}/plank" \
           "${DEST_DIR_DARK}/metacity-1"

echo "Setting up SCSS links for ${THEME_NAME_DARK}..."
ln -sf "${SASS_SRC_DIR}/_colors-dark.scss" "${SASS_SRC_DIR}/_colors.scss"
ln -sf "${SASS_SRC_DIR}/_drawing-dark.scss" "${SASS_SRC_DIR}/_drawing.scss"

echo "Compiling SCSS for ${THEME_NAME_DARK}..."
sassc "${MAIN_SRC_DIR}/gtk-3.0/gtk.scss" "${DEST_DIR_DARK}/gtk-3.0/gtk.css"
sassc "${MAIN_SRC_DIR}/gtk-3.0/gtk-dark.scss" "${DEST_DIR_DARK}/gtk-3.0/gtk-dark.css"
sassc "${MAIN_SRC_DIR}/gtk-4.0/gtk.scss" "${DEST_DIR_DARK}/gtk-4.0/gtk.css"
sassc "${MAIN_SRC_DIR}/gtk-4.0/gtk-dark.scss" "${DEST_DIR_DARK}/gtk-4.0/gtk-dark.css"
sassc "${MAIN_SRC_DIR}/gnome-shell/gnome-shell.scss" "${DEST_DIR_DARK}/gnome-shell/gnome-shell.css"

echo "Installing assets for ${THEME_NAME_DARK}..."
bash "${COLLOID_SRC_ROOT}/assets.sh" -d "/usr/share/themes" -n "${THEME_NAME_DARK}" -c dark
echo "Installing gtkrc for ${THEME_NAME_DARK}..."
bash "${COLLOID_SRC_ROOT}/gtkrc.sh" -d "/usr/share/themes" -n "${THEME_NAME_DARK}" -c dark

# --- Install Colloid Light Theme (as 'Colloid') ---
THEME_NAME_LIGHT="Colloid"
DEST_DIR_LIGHT="/usr/share/themes/${THEME_NAME_LIGHT}"

echo "Preparing to install ${THEME_NAME_LIGHT}..."
mkdir -p "${DEST_DIR_LIGHT}/gtk-3.0" \
           "${DEST_DIR_LIGHT}/gtk-4.0" \
           "${DEST_DIR_LIGHT}/gnome-shell" \
           "${DEST_DIR_LIGHT}/xfwm4" \
           "${DEST_DIR_LIGHT}/cinnamon" \
           "${DEST_DIR_LIGHT}/plank" \
           "${DEST_DIR_LIGHT}/metacity-1"

echo "Setting up SCSS links for ${THEME_NAME_LIGHT}..."
ln -sf "${SASS_SRC_DIR}/_colors-light.scss" "${SASS_SRC_DIR}/_colors.scss"
ln -sf "${SASS_SRC_DIR}/_drawing-light.scss" "${SASS_SRC_DIR}/_drawing.scss"

echo "Compiling SCSS for ${THEME_NAME_LIGHT}..."
sassc "${MAIN_SRC_DIR}/gtk-3.0/gtk.scss" "${DEST_DIR_LIGHT}/gtk-3.0/gtk.css"
sassc "${MAIN_SRC_DIR}/gtk-4.0/gtk.scss" "${DEST_DIR_LIGHT}/gtk-4.0/gtk.css"
sassc "${MAIN_SRC_DIR}/gnome-shell/gnome-shell.scss" "${DEST_DIR_LIGHT}/gnome-shell/gnome-shell.css"

echo "Installing assets for ${THEME_NAME_LIGHT}..."
bash "${COLLOID_SRC_ROOT}/assets.sh" -d "/usr/share/themes" -n "${THEME_NAME_LIGHT}" -c default
echo "Installing gtkrc for ${THEME_NAME_LIGHT}..."
bash "${COLLOID_SRC_ROOT}/gtkrc.sh" -d "/usr/share/themes" -n "${THEME_NAME_LIGHT}" -c default

# Clean up
rm -rf "${COLLOID_SRC_ROOT}" /tmp/colloid.zip $HOME

# Install Colloid Icon Theme from source
echo "Installing Colloid Icon Theme..."
if git clone --depth 1 https://github.com/vinceliuice/Colloid-icon-theme.git /tmp/Colloid-icon-theme; then
    (cd /tmp/Colloid-icon-theme && ./install.sh -d /usr/share/icons)
    echo "Colloid Icon Theme installed."
else
    echo "ERROR: Failed to clone Colloid Icon Theme repository. Exiting."
    exit 1
fi
rm -rf /tmp/Colloid-icon-theme

# Install Dash to Panel GNOME Shell Extension
echo "Installing Dash to Panel GNOME Shell Extension..."
if git clone --depth 1 https://github.com/home-sweet-gnome/dash-to-panel.git /tmp/dash-to-panel; then
    (cd /tmp/dash-to-panel && make install INSTALL_PATH=/usr/share/gnome-shell/extensions GLIB_SCHEMAS_INSTALL_DIR=/usr/share/glib-2.0/schemas)
    echo "Dash to Panel installed."
else
    echo "ERROR: Failed to clone Dash to Panel repository. Exiting."
    exit 1
fi
rm -rf /tmp/dash-to-panel

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux 

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

[org.gnome.desktop.wm.preferences]
button-layout='close,minimize,maximize:'

[org.gnome.shell]
enabled-extensions=['dash-to-panel@jderose9.github.com']
favorite-apps=['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Software.desktop']

[org.gnome.shell.extensions.dash-to-panel]
panel-position='BOTTOM'
panel-size=48
panel-length=100
appicon-margin=4
appicon-padding=4
running-indicator-style='DOTS'
show-showapps-button=true
translucent-mode='ADAPTIVE'
intellihide=false
animate-show-apps=false
dot-style-focused='DOTS'
dot-style-unfocused='DOTS'
EOF

# Recompile GSchema to apply the overrides
if command -v glib-compile-schemas &> /dev/null; then
    echo "Compiling GSettings schemas..."
    glib-compile-schemas /usr/share/glib-2.0/schemas/
else
    echo "WARNING: glib-compile-schemas command not found. System-wide GSettings might not be applied correctly."
fi
