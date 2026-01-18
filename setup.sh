#!/usr/bin/env bash

# sudo check
if [ "$EUID" -eq 0 ]; then
  echo "This script must be run without sudo. Exiting..."
  exit 1
fi

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "arch" || "$ID" == "manjaro" || "$ID" == "endeavouros" || "$ID" == "archcraft" ]]; then
            echo "arch"
        elif [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "zorin" ]]; then
            echo "ubuntu"
        elif [[ "$ID" == "opensuse-tumbleweed" ]]; then
            echo "opensuse"
        elif [[ "$ID" == "fedora" ]]; then
            echo "fedora"
        else
            echo "unsupported"
        fi
    else
        echo "unsupported"
    fi
}

DISTRO=$(detect_distro)
echo "Detected distribution: $DISTRO"

# Ask yes/no questions
ask_user() {
    local prompt="$1"
    local response
    while true; do
        read -rp "$prompt (y/n): " response
        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Setup variables
TARGET_USER=$(logname)
HOME_DIR="/home/$TARGET_USER"
SETUP_DIR="$HOME_DIR/Gaming-setup"
LOGFILE="$SETUP_DIR/setup.log"

sudo mkdir -p "$SETUP_DIR"
sudo chown "$TARGET_USER:$TARGET_USER" "$SETUP_DIR"

# Enable logging
exec > >(sudo tee -a "$LOGFILE") 2>&1

# Logo
cat << 'EOF'

⠀⠀⠀⠀⠀            .88888888:.
                88888888.88888.
              .8888888888888888.
              888888888888888888
              88' _`88'_  `88888
              88 88 88 88  88888
              88_88_::_88_:88888
              88:::,::,:::::8888
              88`:::::::::'`8888
             .88  `::::'    8:88.
            8888            `8:888.
          .8888'             `888888.
         .8888:..  .::.  ...:'8888888:.
        .8888.'     :'     `'::`88:88888
       .8888        '         `.888:8888.
      888:8         .           888:88888
    .888:88        .:           888:88888:
    8888888.       ::           88:888888
    `.::.888.      ::          .88888888
   .::::::.888.    ::         :::`8888'.:.
  ::::::::::.888   '         .::::::::::::
  ::::::::::::.8    '      .:8::::::::::::.
 .::::::::::::::.        .:888:::::::::::::
 :::::::::::::::88:.__..:88888:::::::::::'
  `'.:::::::::::88888888888.88:::::::::'
     `':::_:' -- '' -'-' `':_::::'⠀⠀⠀⠀⠀⠀

EOF

# Arch Linux section
if [[ "$DISTRO" == "arch" ]]; then
    echo "=== Arch Linux Setup ==="
    
    # Dependencies
    if ask_user "Install base dependencies and enable multilib repo?"; then
      sudo pacman -Sy --noconfirm

      if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy
      fi

      sudo pacman -S --needed --noconfirm curl git base-devel flatpak fuse2
      if ! command -v paru &> /dev/null; then
        cd /tmp
        git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        makepkg -si --noconfirm
      fi
    else
      echo -e "\e[1;31mDependencies required. Exiting...\e[0m"
      exit 1
    fi

    # Mirrors
    if ask_user "Set fastest mirrors?"; then
      sudo pacman -S --needed --noconfirm reflector
      sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
      sudo pacman -Sy
    fi

    # Steam
    if ask_user "Install steam?"; then
      sudo pacman -S --noconfirm --needed steam
    fi

    # Heroic Games Launcher
    if ask_user "Install Heroic Games launcher from AUR? (Epic Games/GOG access)"; then
      paru -S --noconfirm --needed heroic-games-launcher-bin
    fi

    # System optimizations
    if ask_user "Apply general optimizations and setup gamemode?"; then
      sudo pacman -S --noconfirm --needed gamemode

      cat <<EOF | sudo tee -a /etc/sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
kernel.nmi_watchdog=0
EOF
      sudo sysctl -p
    fi
    
    # OpenRGB
    if ask_user "Install an RGB control app (OpenRGB)?"; then
      sudo pacman -S --noconfirm --needed openrgb
    fi

     # mangojuice
    if ask_user "Install a peformance monitoring overlay like RivaTunerStatistics/Afterburner (mangojuice)?"; then
       paru -S --noconfirm --needed mangojuice-bin
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)?"; then
      sudo pacman -S --noconfirm --needed lact
    fi

    # proton-ge
    if ask_user "Install a superior custom proton version (proton-GE)?"; then
       paru -S --noconfirm --needed proton-ge-custom-bin
    fi

    # ntfs
    if ask_user "Install Windows drive support (ntfs-3g)?"; then
       sudo pacman -S --noconfirm --needed ntfs-3g
    fi
    
    # CachyOS repo
    if ask_user "Install CachyOS repositories and install cachyos optimizations?"; then
      curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
      tar xvf cachyos-repo.tar.xz && cd cachyos-repo
      sudo ./cachyos-repo.sh
      sudo pacman -Syu --noconfirm
      cd
      sudo pacman -S --noconfirm --needed cachyos-settings
    fi

    # CachyOS kernel
    if ask_user "Compile/install CachyOS kernel? (can be slow if you don't have CachyOS repo)"; then
      paru -S --noconfirm --needed linux-cachyos linux-cachyos-headers
    fi

# Ubuntu section
elif [[ "$DISTRO" == "ubuntu" ]]; then
    echo "=== Ubuntu Setup ==="
    
    # Dependencies
    if ask_user "Install base dependencies?"; then
      sudo apt update && sudo apt upgrade -y
      sudo apt install -y flatpak libfuse2t64 software-properties-common
      sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    else
      echo -e "\e[1;31mDependencies required. Exiting...\e[0m"
      exit 1
    fi

    # Steam
    if ask_user "Install Steam?"; then
      sudo apt install -y steam
    fi

    # Heroic Games Launcher
    if ask_user "Install Heroic Games Launcher from Flatpak? (Epic Games/GOG access)"; then
      flatpak install -y flathub com.heroicgameslauncher.hgl
    fi

    # System optimizations
    if ask_user "Apply general optimizations and install gamemode?"; then
      sudo apt install -y gamemode

      cat <<EOF | sudo tee -a /etc/sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
kernel.nmi_watchdog=0

EOF
      sudo sysctl -p
    fi

    # NVIDIA drivers 
    if ask_user "Install newest NVIDIA drivers? (UBUNTU ONLY)"; then
      sudo apt install pkg-config libglvnd-dev dkms build-essential libegl-dev libegl1 libgl-dev libgl1 libgles-dev libgles1 libglvnd-core-dev libglx-dev libopengl-dev gcc make -y
      sudo apt remove --purge '^nvidia-.*'
      sudo apt autoremove -y
      sudo add-apt-repository -y ppa:graphics-drivers/ppa
      ubuntu-drivers devices
      sudo ubuntu-drivers autoinstall
      sudo apt update
    fi
  
    # OpenRGB
    if ask_user "Install an RGB control app (OpenRGB)?"; then
      flatpak install -y flathub org.openrgb.OpenRGB
    fi

    # mangojuice
    if ask_user "Install a peformance monitoring overlay like RivaTunerStatistics (mangojuice)?"; then
      flatpak install -y flathub io.github.radiolamp.mangojuice
      sudo apt install -y mangohud
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)?"; then
        flatpak install -y flathub io.github.ilya_zlobintsev.LACT
    fi
    # protonplus
    if ask_user "Install an app to manage/install custom Proton versions like Proton-GE (protonplus)?"; then
        flatpak install -y flathub com.vysp3r.ProtonPlus
    fi

    # Updated mesa
    if ask_user "Install updated mesa (AMD Drivers)?"; then
       sudo add-apt-repository ppa:kisak/kisak-mesa
       sudo apt update && sudo apt upgrade -y    
    fi

    # Liquorix kernel
    if ask_user "Install Liquorix kernel for better performance and responsiveness? (Will break secure boot)"; then
      sudo add-apt-repository ppa:damentz/liquorix -y
      sudo apt update
      sudo apt install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64
      sudo sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux liquorix-amd64"/' /etc/default/grub
      sudo update-grub
    fi

# OpenSUSE section
elif [[ "$DISTRO" == "opensuse" ]]; then
    echo "=== OpenSUSE Tumbleweed Setup ==="
    
    # Dependencies
    if ask_user "Install base dependencies?"; then
      sudo zypper refresh
      sudo zypper install -y flatpak
      sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    else
      echo -e "\e[1;31mDependencies required. Exiting...\e[0m"
      exit 1
    fi

    # Steam
    if ask_user "Install Steam?"; then
      sudo zypper install -y steam
    fi

    # Heroic
    if ask_user "Install Heroic Games Launcher from Flatpak? (Epic Games/GOG access)"; then
      sudo zypper install -y heroic-games-launcher
    fi

    # System optimizations
    if ask_user "Apply general optimizations and install gamemode?"; then
      sudo zypper install -y gamemode
      sudo zypper addrepo https://download.opensuse.org/repositories/home:Herbster0815/openSUSE_Tumbleweed/home:Herbster0815.repo
      sudo zypper refresh
      sudo zypper install -y cachyos-settings
    fi

    # OpenRGB
    if ask_user "Install an RGB control app (OpenRGB)?"; then
      sudo zypper install -y OpenRGB
    fi

    # mangojuice
    if ask_user "Install a peformance monitoring overlay like RivaTunerStatistics/Afterburner (mangojuice)?"; then
      flatpak install -y flathub io.github.radiolamp.mangojuice
      sudo zypper install -y mangohud
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)?"; then
      flatpak install -y flathub io.github.ilya_zlobintsev.LACT
    fi

    # protonplus
    if ask_user "Install an app to manage/install custom Proton versions like Proton-GE (protonplus)?"; then
      sudo zypper install -y ProtonPlus
    fi

# Fedora section
elif [[ "$DISTRO" == "fedora" ]]; then
    echo "=== Fedora Setup ==="
    
    # Dependencies
    if ask_user "Install base dependencies?"; then
        sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf update -y
      fi
    else
      echo -e "\e[1;31mDependencies required. Exiting...\e[0m"
      exit 1
    fi

    # Steam
    if ask_user "Install Steam?"; then
      sudo dnf install -y steam
    fi

    # Heroic Games Launcher
    if ask_user "Install Heroic Games Launcher from Flatpak? (Epic Games/GOG access)"; then
      flatpak install -y flathub com.heroicgameslauncher.hgl
    fi

    # System optimizations
    if ask_user "Apply general optimizations and install gamemode?"; then
      sudo dnf install -y gamemode gamemode-devel
      sudo dnf copr enable bieszczaders/kernel-cachyos-addons
      sudo dnf install -y cachyos-settings
    fi

    # NVIDIA drivers 
    if ask_user "Install NVIDIA drivers?"; then
      sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-cuda-libs nvidia-settings
      sudo dracut --force
    fi
  
    # OpenRGB
    if ask_user "Install an RGB control app (OpenRGB)?"; then
      sudo dnf install -y openrgb
    fi

    # mangojuice
    if ask_user "Install a peformance monitoring overlay like RivaTunerStatistics (mangojuice)?"; then
      flatpak install -y flathub io.github.radiolamp.mangojuice
      sudo dnf install -y mangohud
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)?"; then
        flatpak install -y flathub io.github.ilya_zlobintsev.LACT
    fi
    # protonplus
    if ask_user "Install an app to manage/install custom Proton versions like Proton-GE (protonplus)?"; then
        flatpak install -y flathub com.vysp3r.ProtonPlus
    fi

    # CachyOS kernel
    if ask_user "Install CachyOS kernel for better performance and responsiveness (NEEDS x86_64_v3) (WILL BREAK SECURE BOOT)?"; then
     sudo setsebool -P domain_kernel_load_modules on
     sudo dnf copr enable bieszczaders/kernel-cachyos
     sudo dnf copr enable bieszczaders/kernel-cachyos-addons 
     sudo dnf install -y kernel-cachyos kernel-cachyos-devel 
    fi

else
    echo "Unsupported distribution: $DISTRO"
    echo "This script only supports Arch, Ubuntu, OpenSUSE Tumbleweed, and Fedora. Exiting..."
    exit 1
fi

# Reboot
if ask_user "Do you want to reboot to apply changes?"; then
    sudo reboot
fi
