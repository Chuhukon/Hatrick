#!/bin/bash

# Fedora Post-Install Script - Jeroen Wijdeven 2026

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

# Prepare

dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo
dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
dnf config-manager addrepo --from-repofile=https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
dnf install -y golang git

# Update & Upgrade
echo -e "\n\e[36mUpdating package lists and upgrading existing packages...\e[0m"
dnf update -y

# Install required dependencies
echo -e "\n\e[36mInstalling required dependencies...\e[0m"
dnf install -y wget gpg curl ca-certificates gnupg2 fontconfig unzip tar git


# Install Vivaldi (RPM) as default browser
echo -e "\n\e[36mInstalling Vivaldi...\e[0m"
dnf install -y vivaldi-stable

# # # # # # # # # # # # # # # # # # # # # # #
# Fonts                                     #
# # # # # # # # # # # # # # # # # # # # # # #

# Install JetBrains Mono font
echo -e "\n\e[36mInstalling JetBrains Mono font...\e[0m"
mkdir -p /usr/share/fonts/truetype/jetbrains
wget -O /tmp/JetBrainsMono.zip https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip
unzip /tmp/JetBrainsMono.zip -d /tmp/jetbrainsmono
cp /tmp/jetbrainsmono/fonts/ttf/* /usr/share/fonts/truetype/jetbrains/
fc-cache -fv

# Install Mona Sans fonts
echo -e "\n\e[36mInstalling Mona Sans fonts...\e[0m"
mkdir -p /usr/share/fonts/truetype/mona-sans
wget -O /tmp/mona-sans.zip https://github.com/github/mona-sans/releases/download/v2.0.27/mona-sans-complete-v2.0.27.zip
unzip /tmp/mona-sans.zip -d /tmp/mona-sans
cp /tmp/mona-sans/fonts/static/ttf/* /usr/share/fonts/truetype/mona-sans/
cp /tmp/mona-sans/fonts/variable/*.ttf /usr/share/fonts/truetype/mona-sans/
fc-cache -fv


# Configure GNOME font settings
echo -e "\n\e[36mConfiguring GNOME font settings...\e[0m"
gsettings set org.gnome.desktop.interface font-name 'Mona Sans 10'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono NL Light 11'
gsettings set org.gnome.desktop.interface document-font-name 'JetBrains Mono NL Light 12'

# # # # # # # # # # # # # # # # # # # # # # #
# Development                               #
# # # # # # # # # # # # # # # # # # # # # # #

# Install .NET Core 8.0
echo -e "\n\e[36mInstalling .NET Core 8.0...\e[0m"
rpm -Uvh https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
dnf install -y dotnet-sdk-8.0

# Install .NET Core 10
echo -e "\n\e[36mInstalling .NET Core 10...\e[0m"
dnf install -y dotnet-sdk-10.0

# Install Docker Engine
echo -e "\n\e[36mInstalling Docker Engine...\e[0m"
dnf remove -y docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker
usermod -aG docker $USER

# Install lazydocker
echo -e "\n\e[36mInstalling lazydocker...\e[0m"
go install github.com/jesseduffield/lazydocker@latest
cp ~/go/bin/lazydocker /usr/local/bin/
chmod +x /usr/local/bin/lazydocker

# Install Sublime Text and Sublime Merge
echo -e "\n\e[36mInstalling Sublime Text and Sublime Merge...\e[0m"
rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
dnf install -y sublime-text sublime-merge

# Install VS Code (RPM)
echo -e "\n\e[36mInstalling VS Code...\e[0m"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
dnf install -y code

# Install JetBrains Toolbox
echo -e "\n\e[36mInstalling JetBrains Toolbox...\e[0m"
wget -O /tmp/toolbox.tar.gz https://download.jetbrains.com/toolbox/jetbrains-toolbox-3.6.4.86641.tar.gz
tar -xzf /tmp/toolbox.tar.gz -C /opt
su - $USER -c '/opt/jetbrains-toolbox-*/bin/jetbrains-toolbox' 2>/dev/null &
ln -sf /opt/jetbrains-toolbox-*/bin/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox
rm -f /tmp/toolbox.tar.gz

# Install VirtualBox (latest from Oracle)
if ! command -v VirtualBox >/dev/null 2>&1; then
    echo -e "\n\e[36mInstalling VirtualBox...\e[0m"
    dnf install -y @development-tools
    dnf install -y kernel-devel kernel-headers

    # Download and install latest VirtualBox RPM (Fedora 40 build works on Fedora 44)
    wget -O /tmp/virtualbox.rpm https://download.virtualbox.org/virtualbox/rpm/fedora/40/x86_64/VirtualBox-7.2-7.2.12_174389_fedora40-1.x86_64.rpm
    dnf install -y /tmp/virtualbox.rpm
    rm /tmp/virtualbox.rpm

    # Create vboxusers group if it doesn't exist
    if ! getent group vboxusers > /dev/null 2>&1; then
        groupadd vboxusers
    fi

    # Add current user to vboxusers group
    usermod -aG vboxusers $USER

    # Build kernel modules for current kernel
    if [ -x /sbin/vboxconfig ]; then
        /sbin/vboxconfig
    else
        echo "WARNING: vboxconfig not found. Run '/sbin/vboxconfig' manually after VirtualBox install."
    fi
else
    echo -e "\n\e[32mVirtualBox is already installed. Skipping.\e[0m"
fi

# Setup RavenDB data directory and run container
echo -e "\n\e[36mSetting up RavenDB...\e[0m"
mkdir -p ~/ravendb/data
docker run -d \
  --name ravendb \
  -p 8080:8080 \
  -p 38888:38888 \
  -v ~/ravendb/data:/opt/RavenDB/Server/RavenData \
  -e RAVEN_Setup_Mode=None \
  -e RAVEN_License_Eula_Accepted=true \
  -e RAVEN_Security_UnsecuredAccessAllowed=PrivateNetwork \
  ravendb/ravendb:latest

# # # # # # # # # # # # # # # # # # # # # # #
# Tooling / Office                          #
# # # # # # # # # # # # # # # # # # # # # # #

# Install Obsidian (via Flatpak)
echo -e "\n\e[36mInstalling Obsidian...\e[0m"
flatpak install -y flathub md.obsidian.Obsidian 2>/dev/null || {
    echo "Flatpak not available. Try manual AppImage download from https://obsidian.md."
}


# TODO
# Install GNOME extensions via flatpack including GNOME Tweaks


# Cleanup
echo -e "\n\e[36mCleaning up...\e[0m"
dnf autoremove -y
rm -f /tmp/JetBrainsMono.zip /tmp/mona-sans.zip
rm -rf /tmp/jetbrainsmono /tmp/mona-sans

echo -e "\n\e[36mInstallation complete! Please reboot if necessary!\e[0m"
echo "Access RavenDB at: http://localhost:8080"

# Ask user to reboot
read -p "Do you want to reboot now? (y/n): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n\e[36mRebooting system...\e[0m"
    reboot
fi
