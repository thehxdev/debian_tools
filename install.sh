#!/usr/bin/env bash

# Colors
Color_Off='\033[0m'
Black='\033[0;30m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Cyan='\033[0;36m'
White='\033[0;37m'

# Variables
OK="${Green}[OK]"
ERROR="${Red}[ERROR]"
SLEEP="sleep 1"

#USER=$(id -u -n)
#USER=$(cat /etc/passwd | grep -E "/home/" | cut -d ":" -f 1)
#HOME="/home/${USER}"

# Versions
#NODE_VERSION="18.12.0"
NVIM_VERSION="stable"
#GOLANG_VERSION="1.19.3"

# print OK
function print_ok() {
	echo -e "${OK} $1 ${Color_Off}"
}

# print ERROR
function print_error() {
	echo -e "${ERROR} $1 ${Color_Off}"
}

function check_root() {
	if [[ ${EUID} -ne 0 ]]; then
		print_error "You must run the script with root permissions to execute this function."
		exit 1
	else
		print_ok "root user checked"
	fi
}

# check version
function debian_version_check() {
	source /etc/os-release
}

function installit() {
	sudo apt install -y $*
}

# Check status code of previous command
function judge() {
	if [[ 0 -eq $? ]]; then
		print_ok "$1 Finished"
		$SLEEP
	else
		print_error "$1 Failde"
		exit 1
	fi
}

function update_repos() {
	sudo apt update -y
	judge "update repos"
}

# Add QT support to XFCE/Gnome
function qt5ct_kvantum_install() {
	update_repos
	installit qt5ct qt5-style-plugins breeze qt5-style-kvantum qt5-style-kvantum-themes
	judge "install qt5ct and kvantum"

	if ! grep -o "QT_QPA_PLATFORMTHEME" /etc/environment; then
		echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment
		judge "enabling qt5ct"
	fi
}

# install yaru theme for kvantum
function yaru_kvantum() {
	if [[ ! -e "/usr/bin/qt5ct" && ! -e "/usr/bin/kvantummanager" ]]; then
		qt5ct_kvantum_install
	fi

	if ! grep -q -o "QT_QPA_PLATFORMTHEME" /etc/environment; then
		echo "QT_QPA_PLATFORMTHEME=qt5ct" | sudo tee -a /etc/environment
	fi

	if ! command -v git; then
		installit git curl
	fi

	if [[ -e "$HOME/kvantum_Yaru_theme" ]]; then
		rm -rf $HOME/kvantum_Yaru_theme
		judge "remove old repo"
	fi

	git clone --depth 1 https://github.com/GabePoel/KvYaru-Colors.git $HOME/kvantum_Yaru_theme >/dev/null 2>&1
	judge "Clone KvYaru repository"

	if [[ ! -e "$HOME/.config/Kvantum" ]]; then
		mkdir $HOME/.config/Kvantum/ >/dev/null 2>&1
		judge "make kvantum directory"
	fi

	cp -r $HOME/kvantum_Yaru_theme/src/* $HOME/.config/Kvantum/
	judge "Copy files to Kvantum directory"

	rm -rf $HOME/kvantum_Yaru_theme
	judge "delete kvantum_Yaru_theme dir"
}

function yaru_gtk() {
	if ! command -v wget; then 
		update_repos
		installit wget curl
		judge "install wget curl"
	fi
	wget -O $HOME/yaru_gtk_xfce.tar.gz https://github.com/thehxdev/distro_install/raw/main/themes/Yaru-xfce-themes.tar.gz
	judge "download themes"

	#mkdir $HOME/yaru_theme >/dev/null 2>&1
	sudo tar -C $HOME/ -xzf $HOME/yaru_gtk_xfce.tar.gz
	judge "theme extract"
	if [[ -e "$HOME/yaru" ]]; then
		sudo cp -r $HOME/yaru/* /usr/share/themes/
		judge "install themes"
		if [[ $(ls /usr/share/themes/ | grep -co "Yaru") -ne 0 ]]; then
			sudo rm -rf $HOME/yaru/
		fi
	else
		print_error "can't find $HOME/yaru"
	fi
	#sudo tar -C /usr/share/themes -xzf $HOME/yaru_gtk_xfce.tar.gz
	installit papirus-icon-theme
	judge "install papirus-icon-theme"
}

function kali_themes {
    if [[ ! -e "~/.themes" ]]; then
        mkdir $HOME/.themes
    fi

    if ! command -v git; then
        installit git
        judge "Install git"
    fi

    git clone --depth 1 --branch master https://gitlab.com/kalilinux/packages/kali-themes.git
    judge "Clone kali-themes git repository"

    cp -r ./kali-themes/share/themes/* $HOME/.themes
    judge "Install Kali-themes GTK"
}

# Add halifax (Germany) mirror list for better speed
function halifax_mirrors() {
	debian_version_check
	#check_root
	sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
	judge "make backup from sources.list"
	if [[ -s "/etc/apt/sources.list.bak" ]]; then
		sudo tee /etc/apt/sources.list <<EOF
deb http://ftp.halifax.rwth-aachen.de/debian/ ${VERSION_CODENAME} main non-free contrib
deb-src http://ftp.halifax.rwth-aachen.de/debian/ ${VERSION_CODENAME} main non-free contrib

deb http://security.debian.org/debian-security ${VERSION_CODENAME}-security main contrib non-free
deb-src http://security.debian.org/debian-security ${VERSION_CODENAME}-security main contrib non-free

deb http://ftp.halifax.rwth-aachen.de/debian/ ${VERSION_CODENAME}-updates main contrib non-free
deb-src http://ftp.halifax.rwth-aachen.de/debian/ ${VERSION_CODENAME}-updates main contrib non-free
EOF
		judge "update mirrors to halifax"
	else
		print_error "can't find backup file for sources.list"
	fi
	update_repos
}

function zsh_install() {
	if ! command -v curl; then
		installit curl
		judge "install curl"
	fi
	installit zsh
	judge "install zsh"

	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	judge "install OhMyZsh"

	sudo cat << EOF >> $HOME/.zshrc
export PATH=/usr/local/bin:\$PATH

alias nv="nvim"
alias vim="nvim"
alias vi="nvim"
alias tm="tmux"
alias pt="proxychains -q -f /etc/proxychains4.conf"
alias spt="sudo proxychains -q -f /etc/proxychains4.conf"
EOF
	judge "adding data to .zshrc"
	#source $HOME/.zshrc
	#judge "source zshrc"
}

function install_apps() {
	update_repos
	installit curl wget aria2 uget
	judge "install curl wget aria2"

	installit htop rofi tmux
	judge "install htop rofi tmux"

	installit breeze-cursor-theme
	judge "install breeze-cursor-theme"

	installit exfat-fuse
	judge "install exfat utils"

	installit ripgrep fd-find
	judge "install ripgrep fd-find"

	installit bleachbit galculator viewnior flameshot
	judge "install bleachbit galculator viewnior flameshot"

	installit unrar unzip p7zip-full
	judge "install unzip unrar p7zip-full"

	installit okular jcal
	judge "install okular jcal"
	
	installit proxychains4 openvpn openconnect wireguard wireguard-tools
	judge "install proxychains4 openvpn openconnect wireguard (VPN Tools)"

	installit xclip xsel micro
	judge "install xclip xsel micro"
}

function kitty_install() {
	if [[ ! -e "$HOME/.local/bin" ]]; then
		mkdir $HOME/.local/bin >/dev/null 2>&1
		judge "make bin directory in .local"
	fi

	if [[ -e "$HOME/.bashrc" ]]; then
		echo 'export PATH="$HOME/.local/bin:$PATH"' | tee -a $HOME/.bashrc
		judge "add .local/bin path to .bashrc"
	fi

	if [[ -e "$HOME/.zshrc" ]]; then
		echo 'export PATH="$HOME/.local/bin:$PATH"' | tee -a $HOME/.zshrc
		judge "add .local/bin path to .zshrc"
	fi

	if ! command -v wget && ! command -v git; then
		installit wget git curl
		judge "install wget git curl"
	fi

	curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n
	judge "install kitty"

	if [[ -e "$HOME/.local/kitty.app/bin/kitty" ]]; then
		ln -s $HOME/.local/kitty.app/bin/kitty $HOME/.local/bin/
		judge "make a symbolic link of binary file to .local/bin"
		sudo ln -s $HOME/.local/kitty.app/bin/kitty /usr/bin/
		judge "make a symbolic link of binary file to /usr/bin"
	else
		print_error "Can't find kitty binary"
	fi

	if [[ -e "$HOME/.local/share/applications" ]]; then
		sudo cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
		judge "add .desktop files"
	else
		mkdir $HOME/.local/share/applications/ >/dev/null 2>&1
		sudo cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
		judge "add .desktop files"
	fi

	sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" $HOME/.local/share/applications/kitty*.desktop
	judge "edit kitty icon"
	sed -i "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" $HOME/.local/share/applications/kitty*.desktop
	judge "edit kitty binary path in .desktop file"
}

function brave_install() {
	installit apt-transport-https curl
	judge "install apt-transport-https curl"

	sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
	judge "add brave-browser gpg keys"

	echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
	judge "add brave-browser mirrors"

	update_repos

	installit brave-browser
	judge "install brave-browser"
}

function golang_install() {
	GOLANG_VERSION=$(curl -L https://go.dev/dl/ >/dev/null 2>&1 | grep -Eo "go[0-9]{1,2}(\.[0-9]{1,3}){1,2}" | sed -n "1p" | tr -d "go")
	if [[ $(uname -m) -eq "x86_64" ]]; then
		if ! command -v wget; then
			installit wget
			judge "install wget"
		fi

		cd $HOME/
		wget https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz
		judge "download golang"
		rm -rf /usr/local/go && tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz 
		judge "install golang"

		if [[ -e "$HOME/.bashrc" ]]; then
			echo 'export PATH=/usr/local/go/bin:$HOME/go/bin:$PATH' >> $HOME/.bashrc
			judge "add go to .bashrc"
			#source $HOME/.bashrc
		fi

		if [[ -e "$HOME/.zshrc" ]]; then
			echo 'export PATH=/usr/local/go/bin:$HOME/go/bin:$PATH' >> $HOME/.zshrc
			judge "add go to .zshrc"
			#source $HOME/.zshrc
		fi
	else
		print_error "Your CPU architecture is not x86_64 (amd64)"
	fi
}

function nodejs_install() {
	NODE_VERSION=$(curl -L https://nodejs.org/en/ >/dev/null 2>&1 | grep "LTS" | grep -Eo "[0-9]{1,3}(\.[0-9]{1,3}){1,2}" | sed -n "1p")
	if [[ $(uname -m) -eq "x86_64" ]]; then
		cd $HOME/

		if [[ -e "$HOME/node-v${NODE_VERSION}-linux-x64.tar.xz" ]]; then
			rm -rf $HOME/node-v${NODE_VERSION}-linux-x64.tar.xz
			judge "delete old file"
		fi

		wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz
		judge "download nodejs"

		sudo mkdir -p /usr/local/lib/nodejs >/dev/null 2>&1
		judge "make nodejs directory"

		sudo tar -xJf node-v${NODE_VERSION}-linux-x64.tar.xz -C /usr/local/lib/nodejs 
		judge "install nodejs"

		if [[ -e "$HOME/.bashrc" ]]; then
			echo "export PATH=\"/usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64/bin:\$PATH\"" >> $HOME/.bashrc
			judge "add nodejs to .bashrc"
			#source $HOME/.bashrc
		fi

		if [[ -e "$HOME/.zshrc" ]]; then
			echo "export PATH=\"/usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64/bin:\$PATH\"" >> $HOME/.zshrc
			judge "add nodejs to .zshrc"
			#source $HOME/.zshrc
		fi

		#if command -v fish; then
		#	fish add_path $HOME/usr/local/lib/nodejs/node-${NODE_VERSION}-linux-64/bin
		#	judge "add nodejs to root PATH"
		#fi
	else 
		print_error "Your CPU architecture is not x86_64 (amd64)"
		exit 1
	fi
}

function neovim_install() {
	cd $HOME/
	if ! command -v wget && ! command -v curl; then
		installit curl wget
		judge "install curl wget"
	fi
	wget https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.deb
	judge "download neovim .deb file"

	installit ./nvim-linux64.deb
	judge "install neovim"
}

function neovim_configuration() {
	if ! command -v nvim; then 
		neovim_install
	fi
	# install packer (neovim package manager)
	if ! command -v git; then
		installit git curl
		judge "install git curl"
	fi

	if [[ -e "$HOME/.local/share/nvim" ]]; then
		rm -rf $HOME/.local/share/nvim/
		judge "remove Neovim old plugins and data"
	fi

	git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
	judge "install packer"

	# Make a backup from old configs
	if [[ -e "$HOME/.config/nvim" ]]; then
		mv $HOME/.config/nvim $HOME/nvim_backup
		judge "make backup"
	fi

	# install new configuretions
	git clone --depth 1 https://github.com/hxdevlover/nvimdots.git $HOME/.config/nvim
	judge "install new configs"
}

function alacritty_install() {
	update_repos
	if ! command -v wget && ! command -v curl; then
		installit curl wget
		judge "install curl wget"
	fi

	if [[ ! -e "$HOME/.cargo/" ]]; then
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
		judge "install rustup"
	else
		print_ok "Rust is installed already"
	fi

	if [[ -e "$HOME/.bashrc" ]]; then
		echo "export PATH=\$HOME/.cargo/bin:\$PATH" >> $HOME/.bashrc
		judge "add cargo to .bashrc"
		#source $HOME/.bashrc
	fi

	if [[ -e "$HOME/.zshrc" ]]; then
		echo "export PATH=\$HOME/.cargo/bin:\$PATH" >> $HOME/.zshrc
		judge "add cargo to .zshrc"
		#source $HOME/.zshrc
	fi

	installit llvm cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 build-essential
	judge "install alacritty deps"

	if ! command -v git >/dev/null 2>&1; then 
		installit git
		judge "install git"
	fi

	git clone https://github.com/alacritty/alacritty.git
	judge "clone alacritty repo"

	cd alacritty
	$HOME/.cargo/bin/cargo build --release
	judge "clone alacritty repo"

	sudo cp target/release/alacritty /usr/local/bin
	judge "copy alacritty binary to /usr/local/bin"

	sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
	judge "copy alacritty logo to /usr/share/pixmaps"

	sudo desktop-file-install extra/linux/Alacritty.desktop
	judge "initialize alacritty.desktop"
	sudo update-desktop-database
	judge "update desktop database"

	print_ok "Alacritty installed"
}

function kvm_install {
	update_repos
	installit qemu-system libvirt-daemon-system virt-manager qemu-utils bridge-utils netcat-openbsd dnsmasq vde2 ovmf ebtables
	judge "install qemu and virt-manager"

	sudo systemctl enable --now libvirtd.service
	judge "enable libvirtd service"

	curl https://raw.githubusercontent.com/hxdevlover/distro_install/main/br10.xml > $HOME/br10.xml
	judge "download br10.xml for bridge network"

	cd $HOME/
	sudo virsh net-define br10.xml
	judge "define br10"
	sudo virsh net-start br10
	judge "start br10"
	sudo virsh net-autostart br10
	judge "auto start br10"

	sudo gpasswd -a libvirt $USER
	judge "add user to libvirtd group"
}

function fish_install() {
	debian_version_check

	if [[ ${VERSION_ID} -eq 11 ]]; then
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_11/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		judge "add fish opensuse repository"

		curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_11/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		judge "sign repository gpg keys"

		update_repos

		installit fish
		judge "install fish"
	else
		print_error "This function only works for debian 11"
	fi
}

function fish_install_deb() {
	if [[ $(uname -m) -eq "x86_64" ]]; then
		#fish_version=$(curl https://fishshell.com/ | grep -oE "[1-9]{1}(\.[0-9]{1,2}){2}" | sort -r | sed -n "2p")
		fish_version=$(curl https://software.opensuse.org/download.html\?project\=shells%3Afish%3Arelease%3A3\&package\=fish | grep -oE "\-[0-9]{1}(\.[0-9]{1,2}){2}" | tr -d "-" | sort -r | sed -n "2p")

		cd $HOME/
		wget https://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_11/amd64/fish_${fish_version}-1_amd64.deb
		judge "download fish .deb file"

		installit ./fish_${fish_version}-1_amd64.deb
		judge "install fish"
	else 
		print_error "This function only works for debian 11"
	fi
}

function build_tools_install() {
	update_repos

	installit llvm build-essential
	judge "install llvm build-essential"
}

function fonts_install() {
	if ! command -v wget && ! command -v curl; then
		installit wget curl git
		judge "install wget curl git"
	fi

	if [[ -e "$HOME/fonts.tar.xz" ]]; then
		rm -rf $HOME/fonts.tar.xz
		wget https://github.com/thehxdev/dotfiles/releases/download/fontsv2/fonts.tar.xz -O $HOME/fonts.tar.xz
		judge "Download Fonts"
	else
		wget https://github.com/thehxdev/dotfiles/releases/download/fontsv2/fonts.tar.xz -O $HOME/fonts.tar.xz
		judge "Download Fonts"
	fi

	tar -xf $HOME/fonts.tar.xz -C $HOME/
	judge "Extract Fonts"

	if [[ ! -e "$HOME/.local/share/fonts" ]]; then
		mkdir $HOME/.local/share/fonts
	else 
		print_ok "fonts directory exist"
	fi

	cp -r $HOME/fonts/* $HOME/.local/share/fonts/
	judge "Install Fonts"

	installit font-manager font-viewer
	judge "install font-manager font-viewer"
}

function configure_fonts() {
	if [[ ! -e "$HOME/.config/fontconfig" ]]; then
		mkdir $HOME/.config/fontconfig >/dev/null 2>&1
	else
		print_ok "fontconfig directory exist"
	fi

	if [[ -e "$HOME/.config/fontconfig/fonts.conf" ]]; then
		mv $HOME/.config/fontconfig/fonts.conf $HOME/.config/fontconfig/fonts.conf.bak
		judge "make backup from old config"
	fi

	if ! command -v wget; then
		installit wget
	fi

	wget -O $HOME/.config/fontconfig/fonts.conf https://raw.githubusercontent.com/thehxdev/dotfiles/main/fontconfig/fonts.conf
	judge "Download config file"
}

function fix_user_sudo() {
	sudo groupadd wheel && print_ok "created wheel group"

	sudo gpasswd -a $USER wheel
	judge "add ${USER} to wheel group"

	echo "%wheel   ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
	judge "add wheel group to sudoers file"
}

function main_menu() {
	clear
	echo -e '
    ____       __    _                ______            __    
   / __ \___  / /_  (_)___  ____     /_  __/___  ____  / /____
  / / / / _ \/ __ \/ / __ \/ __ \     / / / __ \/ __ \/ / ___/
 / /_/ /  __/ /_/ / / /_/ / / / /    / / / /_/ / /_/ / (__  ) 
/_____/\___/_____/_/\____/_/ /_/    /_/  \____/\____/_/____/  
                                                              
=> by thehxdev
=> https://github.com/thehxdev/
'

	echo -e "====================  Themes  ===================="
	echo -e "${Green}1. Add Qt Support to XFCE/Gnome${Color_Off}"
	echo -e "${Green}2. Install Yaru Theme (Qt/Kvantum)${Color_Off}"
	echo -e "${Green}3. Install Yaru Theme (GTK)${Color_Off}"
	echo -e "${Green}4. Install Kali Themes (GTK)${Color_Off}"
	echo -e "====================  Install Apps  =============="
	echo -e "${Green}5. Install Desktop tools${Color_Off}"
	echo -e "${Green}6. Install KVM/QEMU and Virt-Manager${Color_Off}"
	echo -e "${Green}7. Install Neovim Stable${Color_Off}"
	echo -e "${Green}8. Install Kitty${Color_Off}"
	echo -e "${Green}9. Install Alacritty ${Cyan}(From Source)${Color_Off}"
	echo -e "${Green}10. Install Brave Browser${Color_Off}"
	echo -e "${Green}11. Install and configure ZSH${Color_Off}"
	echo -e "${Green}12. Install Golang${Color_Off}"
	echo -e "${Green}13. Install NodeJS LTS${Color_Off}"
	echo -e "${Green}14. Install Build Tools${Color_Off}"
	echo -e "${Green}15. Install Fonts${Color_Off}"
	echo -e "====================  Configurations ============="
	echo -e "${Green}16. Configure System Fonts${Color_Off}"
	echo -e "${Green}17. Fix [user is not in sudoers...]${Color_Off}"
	echo -e "${Green}18. Configure Neovim${Color_Off}"
	echo -e "${Green}19. Use Halifax Mirrors${Color_Off}"
	echo -e "${Yellow}20. Exit${Color_Off}\n"

	read -rp "Enter an Option: " menu_num
	case $menu_num in
	1)
		qt5ct_kvantum_install
		;; 
	2)
		yaru_kvantum
		;;
	3)
		yaru_gtk
		;;
    4)
        kali_themes
        ;;
	5) 
		install_apps
		;;
	6)
		kvm_install
		;;
	7)
		neovim_install
		;;
	8)
		kitty_install
		;;
	9)
		alacritty_install
		;;
	10)
		brave_install
		;;
	11)
		zsh_install
		;;
	12)
		golang_install
		;;
	13)
		nodejs_install
		;;
	14)
		build_tools_install
		;;
	15)
		fonts_install
		;;
	16)
		configure_fonts
		;;
	17)
		fix_user_sudo
		;;
	18)
		neovim_configuration
		#fonts_install
		;;
	19)
		halifax_mirrors
		;;
	20)
		exit 0
		;;
	*)
		print_error "Invalid Option. Run script again!"
		exit 1
	esac
}

main_menu "$@"
