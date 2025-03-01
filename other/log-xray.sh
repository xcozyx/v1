#!/bin/bash

info() {
    echo -e "[ INFO ] $1"
    sleep 0.5
}

# Fungsi untuk menampilkan peringatan dengan penundaan
warning() {
    echo -e "[ WARNING ] $1"
    sleep 0.5
}

# Fungsi untuk menampilkan menu jika tidak ada klien
no_clients_menu() {
    clear
    echo -e "————————————————————————"
    echo -e "       User List        "
    echo -e "————————————————————————"
    echo -e "You have no existing clients!"
    echo -e "————————————————————————"
    echo ""
    read -n 1 -s -r -p "Press any key to back"
    menu
}

clear
NUMBER_OF_CLIENTS=$(grep -c -E "^#&@ " "/usr/local/etc/xray/config/04_inbounds.json")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
    no_clients_menu
fi

clear
echo -e "————————————————————————"
echo -e "       User List        "
echo -e "————————————————————————"
echo -e "       User EXP        "
echo -e "————————————————————————"
grep -E "^#&@ " "/usr/local/etc/xray/config/04_inbounds.json" | cut -d ' ' -f 2-3 | column -t | sort | uniq
echo ""
echo -e "Tap enter to go back"
echo -e "————————————————————————"
read -rp "Input Username: " user
if [[ -z $user ]]; then
    menu
else
    clear
    log_file="/user/xray-$user.log"
    if [[ -f $log_file ]]; then
        echo -e "$(cat "$log_file")"
    else
        warning "Log file for user $user not found."
    fi
    echo ""
    read -n 1 -s -r -p "Press any key to back"
    allxray
fi
