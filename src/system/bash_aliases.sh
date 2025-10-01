function bash_aliases() {
	if [[ ! -f "${HOME}/.bash_aliases" ]]; then
		cat > "${HOME}/.bash_aliases" <<'EOF'
### Custom Aliases ###

# Clear screen and history
alias cls='clear'
alias acls='history -c; clear'

# List hidden files
alias lh='ls -a --color=auto'

# Directory commands
alias mkdir='mkdir -pv'
alias rmdir='rm -rdv'

# Safer file operations
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'

# Networking and package management
alias brctl='sudo brctl'
alias net?='ping google.com -c 5'

# System info
alias stats='sudo systemctl status'
alias fstats='sudo systemctl status > status.txt'
alias analyze='systemd-analyze'
alias blame='systemd-analyze blame'
alias chain='systemd-analyze critical-chain'
alias chart='systemd-analyze plot > test.svg'

# KDE
alias plasmareset='killall plasmashell; kstart plasmashell'

# Grep with color
alias grep='grep --colour=auto'

# Pacman and AUR
alias add='sudo pacman -S --needed'
alias sp='pacman -Ss'
alias rem='sudo pacman -Rsn'
alias yay='paru -S'
alias sa='paru -Ss'
alias pac='sudo nano /etc/pacman.conf'

# Editors and config
alias nb='nano ~/.bashrc'
alias nano='vim'
alias n='nano'

# Fastfetch
alias ff='fastfetch'

# Disk and navigation
alias ld='lsblk'
alias up='cd ..'
alias up2='cd ../..'
alias up3='cd ../../..'
alias up4='cd ../../../..'
alias up5='cd ../../../../..'

# Network IP info
alias lan="ip addr show | grep 'inet ' | grep -v '127.0.0.1' | cut -d' ' -f6 | cut -d/ -f1"
alias lan6="ip addr show | grep 'inet6 ' | cut -d ' ' -f6 | sed -n '2p'"
alias wan='curl ipinfo.io/ip'

# Make all .sh files executable
#alias run='find . -type f -name \"*.sh\" -exec chmod +x {} \;'
alias run='find . -type f -name "*.sh" -exec chmod +x {} \;'

# Gaming and Wine tools
alias proton='protontricks --gui --no-bwrap'
alias bottles='flatpak run --command=bottles-cli com.usebottles.bottles'
EOF
		echo "Aliases written to ~/.bash_aliases"
	else
		echo ".bash_aliases already exists — skipping creation"
	fi
fi
}