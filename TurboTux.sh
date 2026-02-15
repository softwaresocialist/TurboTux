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
        if [[ "$ID" == "arch" || "$ID" == "endeavouros" || "$ID" == "archcraft" || "$ID" == "omarchy" || "$ID" == "rebornos" ]]; then
            echo "arch"
        elif [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "zorin" ]]; then
            echo "ubuntu"
        elif [[ "$ID" == "opensuse-tumbleweed" ]]; then
            echo "opensuse"
        elif [[ "$ID" == "fedora" ]]; then
            echo "fedora"
        else
            echo -e "\e[1;31mUnsupported Distro\e[0m"
            exit
        fi
    else
        echo "unsupported"
        exit
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


# Arch Linux section
if [[ "$DISTRO" == "arch" ]]; then
    echo "=== Arch Linux Setup ==="
    
    # Repositories
    if ask_user "Enable necessary repositories?"; then

      if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
        sudo pacman -Syu --noconfirm
      fi

      sudo pacman -S --needed --noconfirm curl
      curl -O https://mirror.cachyos.org/cachyos-repo.tar.xz
      tar xvf cachyos-repo.tar.xz && cd cachyos-repo
      sudo ./cachyos-repo.sh
      sudo pacman -Syu --noconfirm
      cd
    else
      echo -e "\e[1;31mRepositories required. Exiting...\e[0m"
      exit 1
    fi

    # Steam
    if ask_user "Install steam?"; then
      sudo pacman -S --noconfirm --needed steam
    fi

    # Heroic Games Launcher
    if ask_user "Install Heroic Games launcher (Epic Games/GOG access)?"; then
      sudo pacman -S --noconfirm --needed heroic-games-launcher-bin
    fi

    # System optimizations
    if ask_user "Apply general optimizations and setup gamemode?"; then
      sudo pacman -S --noconfirm --needed gamemode cachyos-settings
    fi
    
    # OpenRGB
    if ask_user "Install an RGB control app (OpenRGB)?"; then
      sudo pacman -S --noconfirm --needed openrgb
    fi

     # mangojuice
    if ask_user "Install a performance monitoring overlay like RivaTunerStatistics/Afterburner (mangojuice)?"; then
       sudo pacman -S --noconfirm --needed mangohud mangojuice
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)?"; then
      sudo pacman -S --noconfirm --needed lact
    fi

    # protontricks
    if ask_user "Install an app to manage and tinker with Proton prefixes (protontricks)?"; then
      sudo pacman -S --noconfirm --needed protontricks
    fi

    # protonplus
    if ask_user "Install an app to manage/install custom Proton versions like Proton-GE (protonplus)?"; then
      sudo pacman -S --noconfirm --needed protonplus
    fi

    # ntfs
    if ask_user "Install Windows drive support (ntfs-3g)?"; then
       sudo pacman -S --noconfirm --needed ntfs-3g
    fi

    # CachyOS kernel
    if ask_user "Install CachyOS kernel?"; then
       sudo pacman -S --noconfirm --needed linux-cachyos linux-cachyos-headers
    fi

# Ubuntu section
elif [[ "$DISTRO" == "ubuntu" ]]; then
    echo "=== Ubuntu Setup ==="
    
    # Flatpak and Flathub repo
    if ask_user "Install Flatpak and Flathub repo?"; then
      sudo apt update && sudo apt upgrade -y
      sudo apt install -y flatpak
      sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    else
      echo -e "\e[1;31mFlatpak and Flathub are required. Exiting...\e[0m"
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

    # gamemode
    if ask_user "Install gamemode?"; then
      sudo apt install -y gamemode
    fi
  
    # OpenRGB
    if ask_user "Install an RGB control app (OpenRGB)?"; then
      flatpak install -y flathub org.openrgb.OpenRGB
    fi

    # mangojuice
    if ask_user "Install a performance monitoring overlay like RivaTunerStatistics (mangojuice)?"; then
      flatpak install -y flathub io.github.radiolamp.mangojuice
      flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//25.08
      sudo apt install -y mangohud
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)?"; then
        flatpak install -y flathub io.github.ilya_zlobintsev.LACT
    fi

    # protontricks
    if ask_user "Install an app to manage and tinker with Proton prefixes (protontricks)?"; then
        flatpak install -y flathub com.github.Matoking.protontricks
    fi

    # protonplus
    if ask_user "Install an app to manage/install custom Proton versions like Proton-GE (protonplus)?"; then
        flatpak install -y flathub com.vysp3r.ProtonPlus
    fi

    # Liquorix kernel
    if ask_user "Install Liquorix kernel for better performance and responsiveness? (WILL BREAK SECURE BOOT)"; then
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
    if ask_user "Install Flatpak and Flathub repo?"; then
      sudo zypper refresh
      sudo zypper install -y flatpak
      flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
    else
      echo -e "\e[1;31mRepositories required. Exiting...\e[0m"
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
    if ask_user "Install a performance monitoring overlay like RivaTunerStatistics/Afterburner (mangojuice)?"; then
      flatpak install -y --user flathub io.github.radiolamp.mangojuice
      flatpak install -y --user flathub org.freedesktop.Platform.VulkanLayer.MangoHud//25.08
      sudo zypper install -y mangohud
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)?"; then
      flatpak install -y --user flathub io.github.ilya_zlobintsev.LACT
    fi

    # protontricks
    if ask_user "Install an app to manage and tinker with Proton prefixes (protontricks)?"; then
      flatpak install -y --user flathub com.github.Matoking.protontricks
    fi

    # protonplus
    if ask_user "Install an app to manage/install custom Proton versions like Proton-GE (protonplus)?"; then
      sudo zypper install -y ProtonPlus
    fi

# Fedora section
elif [[ "$DISTRO" == "fedora" ]]; then
    echo "=== Fedora Setup ==="
    
    # Dependencies
    if ask_user "Enable necessary repositories?"; then
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        sudo dnf update -y
    else
      echo -e "\e[1;31mRepositories required. Exiting...\e[0m"
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
      sudo dnf install -y cachyos-settings --allowerasing
    fi

    # OpenRGB
    if ask_user "Install an RGB control app (OpenRGB)?"; then
      sudo dnf install -y openrgb
    fi

    # mangojuice
    if ask_user "Install a performance monitoring overlay like RivaTunerStatistics (mangojuice)?"; then
      flatpak install -y flathub io.github.radiolamp.mangojuice
      flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//25.08
      sudo dnf install -y mangohud
    fi

    # lact
    if ask_user "Install a GPU management/overclocking app like afterburner (lact)?"; then
        flatpak install -y flathub io.github.ilya_zlobintsev.LACT
    fi

    # protontricks
    if ask_user "Install an app to manage and tinker with Proton prefixes (protontricks)?"; then
        flatpak install -y flathub com.github.Matoking.protontricks
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
