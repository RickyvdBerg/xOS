#!/usr/bin/env bash
set -oue pipefail

###############################################################################
#  Avios uBlue build script
#  ▸ Base image     : ghcr.io/ublue-os/silverblue-nvidia
#  ▸ Desktop target : GNOME + Dash‑to‑Panel (macOS‑like bottom bar)
#  ▸ Maintainer     : you@example.com
###############################################################################

printf '\n==> Avios build start (uBlue)\n'  >&2

###############################################################################
# 0. Variables – keep all remote assets in one place for easy updates
###############################################################################
FONT_URL="https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/archive/master.zip"
DTPANEL_URL="https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v68.shell-extension.zip"

###############################################################################
# 1. Core RPM packages (dnf5 works inside the build container)
###############################################################################

printf '==> Installing RPMs\n' >&2
dnf5 install -y \
    gnome-tweaks \
    gnome-themes-extra \
    git curl wget unzip jq

# Remove unwanted browser that ships in the *-nvidia base
# (ignore failure if Fedora drops Firefox from the image later)
dnf5 remove -y firefox firefox-langpacks mozilla-filesystem || true

###############################################################################
# 2. Flatpak – add Flathub only (real install happens on first boot)
###############################################################################
printf '==> Adding Flathub remote (no installs during build)\n' >&2
flatpak --system remote-add --if-not-exists flathub \
       https://dl.flathub.org/repo/flathub.flatpakrepo

###############################################################################
# 3. San‑Francisco Pro fonts
###############################################################################
printf '==> Installing SF Pro fonts\n' >&2
install -d /usr/share/fonts/sf-pro
curl -Ls "$FONT_URL" -o /tmp/sf.zip
unzip -q /tmp/sf.zip -d /tmp/sf
install -Dm644 /tmp/sf/*/*.otf /usr/share/fonts/sf-pro/
rm -rf /tmp/sf.zip /tmp/sf
fc-cache -f

###############################################################################
# 4. Colloid icon theme (dark variant) – shallow clone for speed
###############################################################################
printf '==> Installing Colloid icon theme\n' >&2
git clone --depth=1 https://github.com/vinceliuice/Colloid-icon-theme.git /tmp/colloid
/tmp/colloid/install.sh -d /usr/share/icons -s default -t default
rm -rf /tmp/colloid

###############################################################################
# 5. Dash‑to‑Panel (system‑wide so it loads at GDM too)
###############################################################################
printf '==> Installing Dash‑to‑Panel extension\n' >&2
EXTDIR=/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com
install -d "$EXTDIR"
curl -Ls "$DTPANEL_URL" -o /tmp/dtp.zip
unzip -q -o /tmp/dtp.zip -d "$EXTDIR"
rm -f /tmp/dtp.zip

###############################################################################
# 6. Helper wrapper so `zen-browser` works like a native binary
#    /var/usrlocal is the writable location mapped to /usr/local at runtime.
###############################################################################
printf '==> Adding zen-browser wrapper\n' >&2
install -d /var/usrlocal/bin
cat > /var/usrlocal/bin/zen-browser <<'EOS'
#!/usr/bin/env bash
exec flatpak run app.zen_browser.zen "$@"
EOS
chmod +x /var/usrlocal/bin/zen-browser

###############################################################################
# 7. First‑boot Flatpak layering script (runs once via autostart)
###############################################################################
install -d /usr/share/avios
cat > /usr/share/avios/install-flatpaks.sh <<'EOS'
#!/usr/bin/env bash
flatpak --system install -y flathub app.zen_browser.zen || true
rm -f ~/.config/autostart/avios-flatpak.desktop 2>/dev/null || true
EOS
chmod +x /usr/share/avios/install-flatpaks.sh

install -d /etc/xdg/autostart
cat > /etc/xdg/autostart/avios-flatpak.desktop <<'EOS'
[Desktop Entry]
Type=Application
Name=Avios • Flatpak layering
Exec=/usr/share/avios/install-flatpaks.sh
OnlyShowIn=GNOME;
X-GNOME-Autostart-enabled=true
EOS

###############################################################################
# 8. GNOME defaults + Dash‑to‑Panel layout matching the screenshot
###############################################################################
printf '==> Writing dconf defaults & locks\n' >&2
install -d /etc/dconf/profile
cat > /etc/dconf/profile/user <<'EOS'
user-db:user
system-db:local
EOS

install -Dm644 /dev/null /etc/dconf/db/local.d/00-avios-desktop
cat > /etc/dconf/db/local.d/00-avios-desktop <<'EOS'
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
enabled-extensions=['dash-to-panel@jderose9.github.com']
favorite-apps=['io.github.zen_browser.zen.desktop','org.gnome.Nautilus.desktop','org.gnome.Console.desktop','org.gnome.TextEditor.desktop','org.gnome.Software.desktop','org.gnome.Settings.desktop']

[org/gnome/shell/extensions/dash-to-panel]
# ── Positioning ───────────────────────────────────────────────────────────
panel-positions='{"0":"BOTTOM"}'
# full‑width bar
panel-lengths='{"0":100}'
# height = 48px (screenshot)
panel-sizes='{"0":48}'

# ── Element order to match mock‑up ────────────────────────────────────────
panel-element-positions='{"0":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"center"},{"element":"rightBox","visible":true,"position":"stackedBR"}]}'

# ── Icon spacing & grouping ───────────────────────────────────────────────
appicon-margin=6
appicon-padding=4
group-apps=true

# ── Dots & focus indicators ──────────────────────────────────────────────
dot-position='BOTTOM'
dot-style-focused='METRO'
dot-style-unfocused='DOTS'

# ── Transparency (subtle glass effect) ────────────────────────────────────
transparency-mode='ADAPTIVE'
trans-use-custom-opacity=true
background-opacity=0.20
background-color='rgba(28,28,28,1.0)'

# ── Disable redundant GNOME UI parts ──────────────────────────────────────
show-activities-button=false
show-appmenu=false
stockgs-keep-dash=false
stockgs-keep-top-panel=true
EOS

# Lock two keys so users can’t accidentally wreck the curated look.
install -Dm644 /dev/null /etc/dconf/db/local.d/locks/00-avios
cat > /etc/dconf/db/local.d/locks/00-avios <<'EOS'
/org/gnome/desktop/interface/icon-theme
/org/gnome/shell/enabled-extensions
EOS

dconf update

###############################################################################
# 9. Enable useful system services
###############################################################################
printf '==> Enabling podman.socket\n' >&2
systemctl enable --now podman.socket

printf '\n==> Avios build finished successfully\n' >&2
