#!/usr/bin/env bash

function ask_question() {
    read -rp "$1 (y/N): " choice
    case "${choice,,}" in
        y|yes) return 0 ;;
        *) return 1 ;;
    esac
}

if ask_question "Do you use KDE Plasma?"; then
		echo "For Turing (GeForce RTX 2080 and earlier): Choose [2] for Proprietary."
        echo "For Ampere and later (RTX 3050+): Choose [5] for Open Kernel."
        echo "Building optimus-manager-qt with Plasma support"
		echo "Building optimus-manager-qt with Plasma support"
		echo "AUR is ${AUR}"
		paru -G optimus-manager-qt 
		cd optimus-manager-qt
		echo "current folder is $(pwd)"
		read -n1 -p "Press any key to continue"
		sed -i 's/_with_plasma=false/_with_plasma=true/' PKGBUILD
		echo "edited PKG"
		read -n1 -p "Press any key to continue"	
		paru -Bi .
		echo "Run paru -Bi"
		read -n1 -p "Press any key to continue"
	else
		echo "For Turing (GeForce RTX 2080 and earlier): Choose [2] for Proprietary."
        echo "For Ampere and later (RTX 3050+): Choose [5] for Open Kernel."
		exec_log "${AUR} -S optimus-manager-qt" "(might be long)"
    fi

	
