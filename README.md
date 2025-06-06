# Avios

**Professional. Clean. Powerful.**

Avios is a refined macOS-inspired Linux desktop built on Universal Blue's Silverblue-NVIDIA foundation. Designed for professionals who demand beauty, performance, and reliability.

## Features

### 🎨 **Elegant Design**
- **WhiteSur Theme**: Professional macOS Big Sur-inspired interface
- **Light & Dark Modes**: Seamless switching with `avios-theme-switcher`
- **San Francisco Pro Fonts**: System-wide typography matching macOS
- **Always-visible Dock**: Clean, productive workspace organization

### 🖥️ **Gaming Ready**
- **NVIDIA Drivers**: Pre-installed proprietary drivers for optimal performance
- **Steam Integration**: Ready for gaming out of the box
- **Performance Optimized**: Built on proven Universal Blue infrastructure

### 🌐 **Modern Browsing**
- **Zen Browser**: Privacy-focused, feature-rich Firefox fork
- **No Bloat**: Clean installation without unnecessary browsers

### ⚡ **Professional Tools**
- **Full Qt/GTK Theming**: Consistent experience across all applications
- **Flatpak Support**: Secure, sandboxed application delivery
- **Office Ready**: Professional workspace for productivity

## Quick Start

### Installation
```bash
# Rebase from any Fedora Atomic desktop
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/RickyvdBerg/avios:latest

# Reboot to complete
systemctl reboot
```

### Theme Switching
```bash
# Switch to light mode
avios-theme-switcher light

# Switch to dark mode  
avios-theme-switcher dark
```

## What's Included

### Core Applications
- **Zen Browser** - Modern, privacy-focused web browser
- **Files** (Nautilus) - Clean file management
- **Console** - Modern terminal experience
- **Text Editor** - Simple, elegant text editing
- **Software** - Flatpak application store

### Themes & Appearance
- **WhiteSur GTK Theme** (Light & Dark variants)
- **WhiteSur Icons** - Consistent, beautiful iconography
- **WhiteSur Cursors** - Polished cursor theme
- **Kvantum Qt Theme** - Complete Qt application theming

### Extensions
- **Dash to Dock** - Always-visible, customizable application dock

## Target Audience

**Avios is perfect for:**
- 🎮 **Gamers** seeking a clean desktop with NVIDIA support
- 💼 **Professionals** who value aesthetics and productivity
- 🌐 **Privacy-conscious users** wanting modern browsing
- 🎯 **Anyone** seeking a refined, bloat-free Linux experience

## Philosophy

Avios follows a **"less is more"** approach:
- ✅ **Essential features** that enhance productivity
- ✅ **Professional appearance** suitable for any environment
- ✅ **Gaming performance** without compromise
- ❌ **No bloat** - every component serves a purpose
- ❌ **No compromise** on quality or user experience

## Building

```bash
# Clone the repository
git clone https://github.com/RickyvdBerg/xOS.git
cd xOS

# Build the image
just build avios

# Build optimized version
just build-rechunk avios
```

## Technical Foundation

- **Base**: Universal Blue Silverblue-NVIDIA
- **Desktop**: GNOME with refined extensions
- **Theming**: Complete WhiteSur ecosystem
- **Applications**: Flatpak-first approach
- **Updates**: Atomic, reliable system updates

## Support

- **Documentation**: [GitHub Repository](https://github.com/RickyvdBerg/xOS)
- **Issues**: [Report Problems](https://github.com/RickyvdBerg/xOS/issues)
- **Community**: Built on Universal Blue's proven infrastructure

---

**Avios** - *Where professional meets beautiful.*
