#!/bin/bash

print_msg() {
    COLOR=$1
    MSG=$2
    echo -e "${COLOR}${MSG}"
}

# Fungsi untuk memeriksa keberhasilan perintah
check_success() {
    if [ $? -eq 0 ]; then
        print_msg $GB "Berhasil"
    else
        print_msg $RB "Gagal: $1"
        exit 1
    fi
}

# Fungsi untuk menampilkan pesan kesalahan
print_error() {
    MSG=$1
    print_msg $RB "Error: ${MSG}"
}

# Set your Cloudflare API credentials
API_EMAIL="xcozystore@gmail.com"
API_KEY="828af7595609da87cc0503e2233f5ebb23b97"

# Set the DNS record details
TYPE_A="A"
TYPE_CNAME="CNAME"
IP_ADDRESS=$(curl -sS ipv4.icanhazip.com)

# Fungsi untuk memvalidasi domain
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Fungsi untuk meminta input domain
input_domain() {
    while true; do
        echo -e "Input Domain"
        echo " "
        read -rp $'\e[33;1mInput domain kamu: \e[0m' -e dns

        if [ -z "$dns" ]; then
            echo -e "Tidak ada input untuk domain!"
        elif ! validate_domain "$dns"; then
            echo -e "Format domain tidak valid! Silakan input domain yang valid."
        else
            echo "$dns" > /usr/local/etc/xray/dns/domain
            echo "DNS=$dns" > /var/lib/dnsvps.conf
            echo -e "Domain ${dns} berhasil disimpan"
            break
        fi
    done
}

# Fungsi untuk mendapatkan Zone ID
get_zone_id() {
  echo -e "Getting Zone ID..."
  ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$ZONE_ID" == "null" ]; then
    echo -e "Gagal mendapatkan Zone ID"
    exit 1
  fi

  # Menyensor Zone ID (hanya menampilkan 3 karakter pertama dan terakhir)
  ZONE_ID_SENSORED="${ZONE_ID:0:3}*****${ZONE_ID: -3}"

  echo -e "Zone ID: $ZONE_ID_SENSORED"
}

# Fungsi untuk menangani respon API
handle_response() {
  local response=$1
  local action=$2

  success=$(echo $response | jq -r '.success')
  if [ "$success" == "true" ]; then
    echo -e "$action berhasil."
  else
    echo -e "$action gagal."
    errors=$(echo $response | jq -r '.errors[] | .message')
    echo -e "Kesalahan: $errors"
  fi
}

# Fungsi untuk menghapus DNS record yang ada
delete_record() {
  local record_name=$1
  local record_type=$2
  local zone_id=${3:-$ZONE_ID}

  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=$record_type&name=$record_name" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$RECORD_ID" != "null" ]; then
    echo -e "Menghapus record $record_type yang ada: $record_name ....."
    response=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$RECORD_ID" \
      -H "X-Auth-Email: $API_EMAIL" \
      -H "X-Auth-Key: $API_KEY" \
      -H "Content-Type: application/json")
    handle_response "$response" "Menghapus record $record_type: $record_name"
  fi
}

# Fungsi untuk menghapus DNS record berdasarkan alamat IP
delete_records_based_on_ip() {
  echo -e "Menghapus DNS records berdasarkan alamat IP: $IP_ADDRESS ....."

  # Mendapatkan semua DNS record untuk zona tersebut
  dns_records=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json")

  # Mengurai dan menghapus A record yang cocok dan CNAME record yang terkait
  echo "$dns_records" | jq -c '.result[] | select(.type == "A" and .content == "'"$IP_ADDRESS"'")' | while read -r record; do
    record_name=$(echo "$record" | jq -r '.name')
    delete_record "$record_name" "A"
    # Menghapus CNAME record yang terkait
    cname_record=$(echo "$dns_records" | jq -c '.result[] | select(.type == "CNAME" and .content == "'"$record_name"'")')
    if [ -n "$cname_record" ]; then
      cname_record_name=$(echo "$cname_record" | jq -r '.name')
      delete_record "$cname_record_name" "CNAME"
    fi
  done
}

# Fungsi untuk menambah A record
create_A_record() {
  echo -e "Menambah A record $GB$NAME_A$NC $YB....."
  response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    --data '{
      "type": "'$TYPE_A'",
      "name": "'$NAME_A'",
      "content": "'$IP_ADDRESS'",
      "ttl": 0,
      "proxied": false
    }')
  echo "$NAME_A" > /usr/local/etc/xray/dns/domain
  echo "DNS=$NAME_A" > /var/lib/dnsvps.conf
  handle_response "$response" "Menambah A record $GB$NAME_A$NC"
}

# Fungsi untuk menambah CNAME record
create_CNAME_record() {
  echo -e "Menambah CNAME record untuk wildcard $GB$NAME_CNAME$NC $YB....."
  response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    --data '{
      "type": "'$TYPE_CNAME'",
      "name": "'$NAME_CNAME'",
      "content": "'$TARGET_CNAME'",
      "ttl": 0,
      "proxied": false
    }')
  handle_response "$response" "Menambah CNAME record untuk wildcard $GB$NAME_CNAME$NC"
}

# Fungsi untuk memeriksa apakah DNS record sudah ada
check_dns_record() {
  local record_name=$1
  local zone_id=$2

  RECORD_EXISTS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?name=$record_name" \
    -H "X-Auth-Email: $API_EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result | length')

  if [ "$RECORD_EXISTS" -gt 0 ]; then
    return 0  # Record exists
  else
    return 1  # Record does not exist
  fi
}

# Update Nginx configuration
update_nginx_config() {
    # Get new domain from file
    NEW_DOMAIN=$(cat /usr/local/etc/xray/dns/domain)
    # Update server_name in Nginx configuration
    wget -q -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/xcozyx/v1/main/nginx.conf
    sed -i "s/server_name web.com;/server_name $NEW_DOMAIN;/g" /etc/nginx/nginx.conf
    sed -i "s/server_name \*.web.com;/server_name \*.$NEW_DOMAIN;/" /etc/nginx/nginx.conf

    # Check if Nginx configuration is valid after changes
    if nginx -t &> /dev/null; then
        # Reload Nginx configuration if valid
        systemctl reload nginx
        print_msg $GB "Nginx configuration reloaded successfully."
    else
        # If Nginx configuration is not valid, display error message
        print_msg $RB "Nginx configuration test failed. Please check your configuration."
    fi
}

# Fungsi untuk menampilkan menu utama
setup_domain() {
    while true; do
        clear

        # Menampilkan judul
        echo -e "—————————————"
        echo -e "SETUP DOMAIN"
        echo -e "—————————————"
        echo -e "Pilih Opsi:"
        echo -e "1. Gunakan domain yang tersedia"
        echo -e "2. Gunakan domain sendiri"
        echo -e "3. Certificate Domain"
        echo -e "4. Back to menu"
        read -rp $'\e[33;1mMasukkan pilihan Anda: \e[0m' choice

        # Memproses pilihan pengguna
        case $choice in
            1)
                while true; do
                    echo -e "Pilih Domain anda:"
                    echo -e "1. recycle.us.kg"
                    echo -e "2. xlab.biz.id"
                    echo -e "3. kembali"
                    read -rp $'\e[33;1mMasukkan pilihan Anda: \e[0m' domain_choice
                    case $domain_choice in
                        1)
                            DOMAIN="recycle.us.kg"
                            ;;
                        2)
                            DOMAIN="xlab.biz.id"
                            ;;
                        3)
                            break
                            ;;
                        *)
                            echo -e "Pilihan tidak valid!"
                            sleep 2
                            continue
                            ;;
                    esac

                    while true; do
                        echo -e "Pilih opsi untuk nama DNS:"
                        echo -e "1. Buat nama DNS secara acak"
                        echo -e "2. Buat nama DNS sendiri"
                        echo -e "3. Kembali"
                        read -rp $'\e[33;1mMasukkan pilihan Anda: \e[0m' dns_name_choice
                        case $dns_name_choice in
                            1)
                                NAME_A="$(openssl rand -hex 2).$DOMAIN"
                                NAME_CNAME="*.$NAME_A"
                                TARGET_CNAME="$NAME_A"
                                get_zone_id
                                delete_records_based_on_ip
                                create_A_record
                                create_CNAME_record
                                update_nginx_config
                                return
                                ;;
                            2)
                                while true; do
                                    read -rp $'\e[33;1mMasukkan nama DNS Anda (hanya huruf kecil dan angka, tanpa spasi): \e[0m' custom_dns_name
                                    if [[ ! "$custom_dns_name" =~ ^[a-z0-9-]+$ ]]; then
                                        echo -e "Nama DNS hanya boleh mengandung huruf kecil dan angka, tanpa spasi!"
                                        sleep 2
                                        continue
                                    fi
                                    if [ -z "$custom_dns_name" ]; then
                                        echo -e "Nama DNS tidak boleh kosong!"
                                        sleep 2
                                        continue
                                    fi
                                    NAME_A="$custom_dns_name.$DOMAIN"
                                    NAME_CNAME="*.$NAME_A"
                                    TARGET_CNAME="$NAME_A"

                                    get_zone_id
                                    if check_dns_record "$NAME_A" "$ZONE_ID"; then
                                        echo -e "Nama DNS sudah ada! Silakan coba lagi."
                                        sleep 2
                                    else
                                        # get_zone_id
                                        delete_records_based_on_ip
                                        create_A_record
                                        create_CNAME_record
                                        update_nginx_config
                                        return
                                    fi
                                done
                                ;;
                            3)
                                break
                                ;;
                            *)
                                echo -e "Pilihan tidak valid!"
                                sleep 2
                                ;;
                        esac
                    done
                done
                ;;
            2)
                input_domain
                update_nginx_config
                break
                ;;
            3)
                certxray
                break
                ;;
            4)
                menu
                break
                ;;
            *)
                echo -e "Pilihan tidak valid!"
                sleep 2
                ;;
        esac
    done

    sleep 2
}

# Menjalankan menu utama
setup_domain

input_menu() {
    # Isi dengan fungsi atau perintah untuk menampilkan menu Anda
    echo -e "Dont forget to renew certificate."
    sleep 5
    echo -e "Returning to menu..."
    sleep 2
    clear
    dns
    # Contoh: panggil skrip menu atau perintah lain
    # ./menu.sh
}

# Panggil fungsi menu untuk kembali ke menu
input_menu
