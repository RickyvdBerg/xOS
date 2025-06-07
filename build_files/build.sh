#!/usr/bin/env bash
set -oue pipefail

echo "==> Avios: build start"

###############################################################################
#  0.  VARIABLES
###############################################################################
# Keep ALL URLs in one spot for easy updates / mirroring.
SF_FONT_URL="https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/archive/master.zip"
DTPANEL_URL="https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v68.shell-extension.zip"

###############################################################################
#  1.  CORE PACKAGES  (dnf5 runs fine inside the uBlue build container)
###############################################################################
echo "==> Installing RPMs"
dnf5 install -y \
    gnome-tweaks \
    git curl wget unzip \
    gnome-themes-extra \
    jq # tiny helper used later

# Remove unwanted bits that still ship in the *-nvidia base.
dnf5 remove -y firefox firefox-langpacks mozilla-filesystem || true

###############################################################################
#  2.  FLATPAKs
###############################################################################
echo "==> Installing Flatpaks"
flatpak --system remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --system install -y flathub app.zen_browser.zen

# thin wrapper so `zen-browser https://example.com` works in scripts
install -Dm755 /dev/null /usr/local/bin/zen-browser
cat > /usr/local/bin/zen-browser <<'EOF'
#!/usr/bin/env bash
exec flatpak run app.zen_browser.zen "$@"
EOF

###############################################################################
#  3.  FONTS  (cached under build_files/files/ to avoid network fetches)
###############################################################################
echo "==> Installing San Francisco Pro fonts"
install -d /usr/share/fonts/sf-pro
curl -L "$SF_FONT_URL" -o /tmp/sf.zip
unzip -q /tmp/sf.zip -d /tmp/sf
install -Dm644 /tmp/sf/*/*.otf /usr/share/fonts/sf-pro/
rm -rf /tmp/sf.zip /tmp/sf
fc-cache -f

###############################################################################
#  4.  ICONS  (Colloid, still downloaded because upstream updates often)
###############################################################################
echo "==> Installing Colloid icon theme"
git clone --depth=1 https://github.com/vinceliuice/Colloid-icon-theme.git /tmp/colloid
/tmp/colloid/install.sh -d /usr/share/icons -s standard -t default -c dark
rm -rf /tmp/colloid

###############################################################################
#  5.  GNOME SHELL EXTENSIONS  (system-wide, so they work on the login screen)
###############################################################################
echo "==> Installing dash-to-panel"
EXTDIR=/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com
install -d "$EXTDIR"
curl -L "$DTPANEL_URL" -o /tmp/dtp.zip
unzip -q -o /tmp/dtp.zip -d "$EXTDIR"
rm -f /tmp/dtp.zip

###############################################################################
#  6.  SYSTEM‐WIDE dconf DEFAULTS & LOCKS
###############################################################################
echo "==> Writing dconf defaults"
install -Dm644 /dev/null /etc/dconf/profile/user
cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

install -Dm644 /dev/null /etc/dconf/db/local.d/00-avios-desktop
cat > /etc/dconf/db/local.d/00-avios-desktop <<'EOF'
[org/gnome/desktop/interface]
icon-theme='Colloid-dark'
font-name='SF Pro Display 11'
document-font-name='SF Pro Display 11'
monospace-font-name='SF Mono 10'
clock-show-weekday=true
show-battery-percentage=true

[org/gnome/desktop/wm/preferences]
titlebar-font='SF Pro Display Bold 11'
button-layout='appmenu:minimize,maximize,close'

[org/gnome/shell]
enabled-extensions=['dash-to-panel@jderose9.github.com','appindicatorsupport@rgcjonas.gmail.com','just-perfection-desktop@just-perfection']
favorite-apps=['app.zen_browser.zen.desktop','org.gnome.Nautilus.desktop','org.gnome.Console.desktop','org.gnome.TextEditor.desktop','org.gnome.Software.desktop','org.gnome.Settings.desktop']

[org/gnome/shell/extensions/dash-to-panel]
panel-positions='{"0":"BOTTOM"}'
panel-sizes='{"0":48}'
dot-position='BOTTOM'
group-apps=true
show-activities-button=false
show-appmenu=false
show-desktop=true
dot-style-focused='METRO'
dot-style-unfocused='DOTS'

[org/gnome/mutter]
center-new-windows=true
experimental-features=['scale-monitor-framebuffer']
EOF

# Lock the two things you explicitly never want users to change.
install -Dm644 /dev/null /etc/dconf/db/local.d/locks/00-avios
cat > /etc/dconf/db/local.d/locks/00-avios <<'EOF'
/org/gnome/desktop/interface/icon-theme
/org/gnome/shell/enabled-extensions
EOF

dconf update

###############################################################################
#  7.  SYSTEM SERVICES
###############################################################################
systemctl enable --now podman.socket

###############################################################################
#  8.  DONE
###############################################################################
echo "==> Avios build finished successfully"
