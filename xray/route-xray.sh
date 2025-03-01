#!/bin/bash

CONFIG_FILE="/usr/local/etc/xray/config/06_routing.json"

# Fungsi untuk Verifikasi
verification_1st() {
    # Verifikasi perubahan
    if grep -q '"outboundTag": "warp"' $CONFIG_FILE; then
        echo -e "Perubahan berhasil dilakukan."
    else
        echo -e "Perubahan gagal, silakan periksa file konfigurasi."
    fi
}

# Fungsi untuk Verifikasi
verification_2nd() {
    # Verifikasi perubahan
    if grep -q '"outboundTag": "direct"' $CONFIG_FILE; then
        echo -e "Perubahan berhasil dilakukan."
    else
        echo -e "Perubahan gagal, silakan periksa file konfigurasi."
    fi
}

# Fungsi untuk merutekan seluruh lalu lintas via WARP
route_all_traffic() {
    # Menggunakan 'sed' untuk mengganti 'outboundTag' dari 'direct' menjadi 'warp'
    # sed -i '/"inboundTag": \[/,/"type": "field"/ s/"outboundTag": "direct"/"outboundTag": "warp"/' $CONFIG_FILE
    sed -i 's/"outboundTag": "direct"/"outboundTag": "warp"/g' $CONFIG_FILE
    verification_1st
    systemctl restart xray
}

# Fungsi untuk merutekan lalu lintas beberapa situs web via WARP
route_some_traffic() {
    # Menggunakan 'sed' untuk mengganti 'outboundTag' dari 'direct' menjadi 'warp' untuk domain tertentu
    sed -i '/"domain": \[/,/"type": "field"/ s/"outboundTag": "direct"/"outboundTag": "warp"/' $CONFIG_FILE
    verification_1st
    systemctl restart xray
}

# Fungsi untuk menonaktifkan rute WARP
disable_route() {
    # Menggunakan 'sed' untuk mengganti 'outboundTag' dari 'warp' menjadi 'direct'
    sed -i 's/"outboundTag": "warp"/"outboundTag": "direct"/g' $CONFIG_FILE
    systemctl restart xray
}

function_1st() {
  disable_route
  route_all_traffic
}
function_2nd() {
  disable_route
  route_some_traffic
}
function_3rd() {
  disable_route
  verification_2nd
}

# Fungsi untuk menampilkan menu
show_wg_menu() {
    clear
    echo -e "——————————————————————————"
    echo -e "-- [ Route Xray Menu ] --"
    echo -e "——————————————————————————"
    echo -e ""
    echo -e " [1] Route all traffic via WARP"
    echo -e " [2] Route some website traffic via WARP"
    echo -e " [3] Disable route WARP"
    echo -e ""
    echo -e " [0] Back To Menu"
    echo -e ""
    echo -e "——————————————————————————"
    echo -e ""
}

# Fungsi untuk menangani input menu
handle_wg_menu() {
    read -p "[ root ] t.me/November2k~# "  opt
    echo -e ""
    case $opt in
        1) function_1st ; sleep 2 ;;
        2) function_2nd ; sleep 2 ;;
        3) function_3rd ; sleep 2 ;;
        0) clear ; allxray ;;
        *) echo -e "Invalid input" ; sleep 1 ; show_wg_menu ;;
    esac
}

# Tampilkan menu dan tangani input pengguna
while true; do
    show_wg_menu
    handle_wg_menu
done