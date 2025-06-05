#!/bin/bash

set -oue pipefail

# Install dependencies
rpm-ostree install gtk-murrine-engine gtk2-engines kvantum qt5ct qt6ct \
    gnome-tweaks git sassc gnome-themes-extra

# Install Colloid GTK Theme Manually
echo "Installing Colloid GTK Theme Manually..."
curl -L https://github.com/vinceliuice/Colloid-gtk-theme/archive/refs/heads/master.zip -o /tmp/colloid.zip
unzip /tmp/colloid.zip -d /tmp

COLLOID_SRC_ROOT="/tmp/Colloid-gtk-theme-main"
SRC_DIR="${COLLOID_SRC_ROOT}/src" # Used by sourced scripts
SASS_SRC_DIR="${SRC_DIR}/sass"
MAIN_SRC_DIR="${SRC_DIR}/main"

# Set environment for non-interactive installation & temporary HOME
export DEBIAN_FRONTEND=noninteractive
export HOME=/tmp/build-home
mkdir -p $HOME
# Precautionary dirs in /root, though HOME is redirected
mkdir -p /root/.config /root/.local/share/themes /root/.themes /root/.gnupg

# Prepare _tweaks-temp.scss (used by all sassc compilations)
echo "Preparing temporary SCSS tweak files..."
cp -f "${SASS_SRC_DIR}/_tweaks.scss" "${SASS_SRC_DIR}/_tweaks-temp.scss"

# Prepare _common-temp.scss for GNOME Shell
# Assuming latest GNOME version for simplicity in build environment
GS_VERSION="48-0"
GNOME_SHELL_SASS_DIR="${SASS_SRC_DIR}/gnome-shell"
cp -f "${GNOME_SHELL_SASS_DIR}/_common.scss" "${GNOME_SHELL_SASS_DIR}/_common-temp.scss"
# Modify based on GS_VERSION (as per original install.sh logic)
sed -i "s/\"40-0\"/\"${GS_VERSION}\"/g" "${GNOME_SHELL_SASS_DIR}/_common-temp.scss" # Affects $widgets-version, $extensions-version initially
# Correct $extensions-version for newer GNOME
if [[ "${GS_VERSION}" == "46-0" || "${GS_VERSION}" == "47-0" || "${GS_VERSION}" == "48-0" ]]; then
  sed -i "s/\"${GS_VERSION}\"/\"46-0\"/g" "${GNOME_SHELL_SASS_DIR}/_common-temp.scss" # Specifically for $extensions-version, making it 46-0
fi
# Apply gnome_version tweak if GS_VERSION >= 47
if [[ "${GS_VERSION}" == "47-0" || "${GS_VERSION}" == "48-0" ]]; then
  sed -i "s/\$gnome_version: default/\$gnome_version: new/" "${SASS_SRC_DIR}/_tweaks-temp.scss"
fi

SASSC_OPT="-M -t expanded"

# Source helper functions from the theme's scripts
echo "Sourcing theme helper scripts..."
# Ensure SHELL_VERSION is set to avoid unbound variable errors in sourced scripts if they use it
SHELL_VERSION="${GS_VERSION%%-*}" # e.g., 48 from 48-0
export SHELL_VERSION

source "${COLLOID_SRC_ROOT}/gtkrc.sh"
source "${COLLOID_SRC_ROOT}/assets.sh"

# --- Install Colloid-Dark Theme ---
THEME_NAME_BASE_DARK="Colloid"      # Name used for some asset/gtkrc logic
VARIANT_NAME_DARK="Colloid-Dark"  # Actual directory and theme name
DEST_DIR_DARK="/usr/share/themes/${VARIANT_NAME_DARK}"
COLOR_SUFFIX_FOR_SASS_DARK="-Dark"
COLOR_PARAM_FOR_HELPERS_DARK="-Dark"

echo "Preparing to install ${VARIANT_NAME_DARK}..."
mkdir -p "${DEST_DIR_DARK}/gtk-3.0" \
           "${DEST_DIR_DARK}/gtk-4.0" \
           "${DEST_DIR_DARK}/gnome-shell" \
           "${DEST_DIR_DARK}/xfwm4" \
           "${DEST_DIR_DARK}/cinnamon" \
           "${DEST_DIR_DARK}/plank" \
           "${DEST_DIR_DARK}/metacity-1"

echo "Compiling SCSS for ${VARIANT_NAME_DARK}..."
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gtk-3.0/gtk${COLOR_SUFFIX_FOR_SASS_DARK}.scss" > "${DEST_DIR_DARK}/gtk-3.0/gtk.css"
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gtk-3.0/gtk-Dark.scss" > "${DEST_DIR_DARK}/gtk-3.0/gtk-dark.css"
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gtk-4.0/gtk${COLOR_SUFFIX_FOR_SASS_DARK}.scss" > "${DEST_DIR_DARK}/gtk-4.0/gtk.css"
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gtk-4.0/gtk-Dark.scss" > "${DEST_DIR_DARK}/gtk-4.0/gtk-dark.css"
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gnome-shell/gnome-shell${COLOR_SUFFIX_FOR_SASS_DARK}.scss" > "${DEST_DIR_DARK}/gnome-shell/gnome-shell.css"

echo "Installing assets and gtkrc for ${VARIANT_NAME_DARK}..."
make_assets "/usr/share/themes" "${THEME_NAME_BASE_DARK}" "" "${COLOR_PARAM_FOR_HELPERS_DARK}" "" "" ""
make_gtkrc "/usr/share/themes" "${THEME_NAME_BASE_DARK}" "" "${COLOR_PARAM_FOR_HELPERS_DARK}" "" "" ""

echo "Generating index.theme for ${VARIANT_NAME_DARK}..."
cat > "${DEST_DIR_DARK}/index.theme" << EOF
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=${VARIANT_NAME_DARK}
Comment=A Flat Gtk+ theme based on Elegant Design
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=${VARIANT_NAME_DARK}
MetacityTheme=${VARIANT_NAME_DARK}
IconTheme=Colloid${COLOR_PARAM_FOR_HELPERS_DARK}
CursorTheme=Colloid-cursors
ButtonLayout=close,minimize,maximize:menu
EOF

# --- Install Colloid Light Theme (as 'Colloid') ---
VARIANT_NAME_LIGHT="Colloid"
DEST_DIR_LIGHT="/usr/share/themes/${VARIANT_NAME_LIGHT}"
SCSS_SUFFIX_LIGHT="-Light" # Use gtk-Light.scss, gnome-shell-Light.scss
COLOR_PARAM_FOR_HELPERS_LIGHT="" # For default/light, the color param to helpers is empty

echo "Preparing to install ${VARIANT_NAME_LIGHT}..."
mkdir -p "${DEST_DIR_LIGHT}/gtk-3.0" \
           "${DEST_DIR_LIGHT}/gtk-4.0" \
           "${DEST_DIR_LIGHT}/gnome-shell" \
           "${DEST_DIR_LIGHT}/xfwm4" \
           "${DEST_DIR_LIGHT}/cinnamon" \
           "${DEST_DIR_LIGHT}/plank" \
           "${DEST_DIR_LIGHT}/metacity-1"

echo "Compiling SCSS for ${VARIANT_NAME_LIGHT}..."
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gtk-3.0/gtk${SCSS_SUFFIX_LIGHT}.scss" > "${DEST_DIR_LIGHT}/gtk-3.0/gtk.css"
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gtk-3.0/gtk-Dark.scss" > "${DEST_DIR_LIGHT}/gtk-3.0/gtk-dark.css" # Still provide for apps requesting dark
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gtk-4.0/gtk${SCSS_SUFFIX_LIGHT}.scss" > "${DEST_DIR_LIGHT}/gtk-4.0/gtk.css"
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gtk-4.0/gtk-Dark.scss" > "${DEST_DIR_LIGHT}/gtk-4.0/gtk-dark.css" # Still provide for apps requesting dark
sassc ${SASSC_OPT} "${MAIN_SRC_DIR}/gnome-shell/gnome-shell${SCSS_SUFFIX_LIGHT}.scss" > "${DEST_DIR_LIGHT}/gnome-shell/gnome-shell.css"

echo "Installing assets and gtkrc for ${VARIANT_NAME_LIGHT}..."
make_assets "/usr/share/themes" "${VARIANT_NAME_LIGHT}" "" "${COLOR_PARAM_FOR_HELPERS_LIGHT}" "" "" ""
make_gtkrc "/usr/share/themes" "${VARIANT_NAME_LIGHT}" "" "${COLOR_PARAM_FOR_HELPERS_LIGHT}" "" "" ""

echo "Generating index.theme for ${VARIANT_NAME_LIGHT}..."
cat > "${DEST_DIR_LIGHT}/index.theme" << EOF
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=${VARIANT_NAME_LIGHT}
Comment=A Flat Gtk+ theme based on Elegant Design
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=${VARIANT_NAME_LIGHT}
MetacityTheme=${VARIANT_NAME_LIGHT}
IconTheme=Colloid # No color suffix for default light icon theme name
CursorTheme=Colloid-cursors
ButtonLayout=close,minimize,maximize:menu
EOF

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
