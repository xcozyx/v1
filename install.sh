#!/bin/bash
get_vps_ip() {
    curl -s https://ipinfo.io/ip
}

check_ip_permission() {
    VPS_IP=$(get_vps_ip)
    ACCESS_URL="https://raw.githubusercontent.com/xcozyx/iz/main/access"

    echo "Mengecek izin untuk ip $VPS_IP"
	sleep 2
	clear
    ACCESS_LIST=$(curl -s $ACCESS_URL)

    MATCH=$(echo "$ACCESS_LIST" | grep -w "^$VPS_IP")

    if [ -n "$MATCH" ]; then
        COMMENTS=$(echo "$MATCH" | cut -d'#' -f2-)
		clear
    else
        echo "Sepertinya anda tidak memiliki ijin untuk menggunakan autoscript ini"
        echo "Silakan hubungi @November2k atau gunakan script asli dari dugong-lewat."
        exit 1
    fi
}

check_ip_permission
rm -rf install.sh
clear
NC='\e[0m'       # No Color (mengatur ulang warna teks ke default)
DEFBOLD='\e[39;1m' # Default Bold
RB='\e[31;1m'    # Red Bold
GB='\e[32;1m'    # Green Bold
YB='\e[33;1m'    # Yellow Bold
BB='\e[34;1m'    # Blue Bold
MB='\e[35;1m'    # Magenta Bold
CB='\e[36;1m'    # Cyan Bold
WB='\e[37;1m'    # White Bold

secs_to_human() {
echo -e "Installation time : $(( ${1} / 3600 )) hours $(( (${1} / 60) % 60 )) minute's $(( ${1} % 60 )) seconds"
}
start=$(date +%s)

# Fungsi untuk mencetak pesan dengan warna
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

# Memastikan pengguna adalah root
if [ "$EUID" -ne 0 ]; then
  print_error "Harap jalankan skrip ini sebagai root."
  exit 1
fi

# Selamat datang
print_msg $YB "Selamat datang! Skrip ini akan memasang beberapa paket penting pada sistem Anda."

# Update package list
print_msg $YB "Memperbarui daftar paket..."
apt update -y
check_success
sleep 1

# Install paket pertama
print_msg $YB "Memasang socat, netfilter-persistent, dan bsdmainutils..."
apt install socat netfilter-persistent bsdmainutils -y
check_success
sleep 1

# Install paket kedua
print_msg $YB "Memasang vnstat, lsof, dan fail2ban..."
apt install vnstat lsof fail2ban -y
check_success
sleep 1

# Install paket ketiga
print_msg $YB "Memasang jq, curl, sudo, dan cron..."
apt install jq curl sudo cron -y
check_success
sleep 1

# Install paket keempat
print_msg $YB "Memasang build-essential dan dependensi lainnya..."
apt install build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev gcc clang llvm g++ valgrind make cmake debian-keyring debian-archive-keyring apt-transport-https systemd bind9-host gnupg2 ca-certificates lsb-release ubuntu-keyring debian-archive-keyring -y
apt install unzip python-is-python3 python3-pip -y
pip install psutil pandas tabulate rich py-cpuinfo distro requests pycountry geoip2 #--break-system-packages
check_success
sleep 1

# Pesan selesai
print_msg $GB "Semua paket telah berhasil dipasang!"
sleep 3
clear

# Selamat datang
print_msg $YB "Selamat datang! Skrip ini akan memasang Xray-core dan melakukan beberapa konfigurasi pada sistem Anda."

# Membuat direktori yang diperlukan
print_msg $YB "Membuat direktori yang diperlukan..."
sudo mkdir -p /user /tmp /usr/local/etc/xray /var/log/xray
check_success "Gagal membuat direktori."

# Menghapus file konfigurasi lama jika ada
print_msg $YB "Menghapus file konfigurasi lama..."
sudo rm -f /usr/local/etc/xray/city /usr/local/etc/xray/org /usr/local/etc/xray/timezone /usr/local/etc/xray/region
check_success "Gagal menghapus file konfigurasi lama."

# Fungsi untuk mendeteksi OS dan distribusi
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        print_msg $RB "Tidak dapat mendeteksi OS. Skrip ini hanya mendukung distribusi berbasis Debian dan Red Hat."
        exit 1
    fi
}

# Fungsi untuk memeriksa versi terbaru Xray-core
get_latest_xray_version() {
    LATEST_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq -r '.tag_name')
    if [ -z "$LATEST_VERSION" ]; then
        print_msg $RB "Tidak dapat menemukan versi terbaru Xray-core."
        exit 1
    fi
}

# Fungsi untuk memasang Xray-core
install_xray_core() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="64"
            ;;
        aarch64)
            ARCH="arm64-v8a"
            ;;
        *)
            print_msg $RB "Arsitektur $ARCH tidak didukung."
            exit 1
            ;;
    esac

    DOWNLOAD_URL="https://github.com/XTLS/Xray-core/releases/download/$LATEST_VERSION/Xray-linux-$ARCH.zip"

    # Unduh dan ekstrak Xray-core
    print_msg $YB "Mengunduh dan memasang Xray-core..."
    curl -L -o xray.zip $DOWNLOAD_URL
    check_success "Gagal mengunduh Xray-core."

    sudo unzip -o xray.zip -d /usr/local/bin
    check_success "Gagal mengekstrak Xray-core."
    rm xray.zip

    sudo chmod +x /usr/local/bin/xray
    check_success "Gagal mengatur izin eksekusi untuk Xray-core."

    # Membuat layanan systemd
    print_msg $YB "Mengkonfigurasi layanan systemd untuk Xray-core..."
    sudo bash -c 'cat <<EOF > /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
Group=nogroup
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -confdir /usr/local/etc/xray/config/
RestartSec=5
Restart=always
StandardOutput=file:/var/log/xray/access.log
StandardError=file:/var/log/xray/error.log
SyslogIdentifier=xray
LimitNOFILE=infinity
OOMScoreAdjust=100

[Install]
WantedBy=multi-user.target
EOF'
    check_success "Gagal mengkonfigurasi layanan systemd untuk Xray-core."

    sudo systemctl daemon-reload
    sudo systemctl enable xray
    sudo systemctl start xray
    check_success "Gagal memulai layanan Xray-core."
}

# Deteksi OS
print_msg $YB "Mendeteksi sistem operasi..."
detect_os

# Cek apakah OS didukung
if [[ "$OS" == "Ubuntu" || "$OS" == "Debian" || "$OS" == "Debian GNU/Linux" || "$OS" == "CentOS" || "$OS" == "Fedora" || "$OS" == "Red Hat Enterprise Linux" ]]; then
    print_msg $GB "Mendeteksi OS: $OS $VERSION"
else
    print_msg $RB "Distribusi $OS tidak didukung oleh skrip ini. Proses instalasi dibatalkan."
    exit 1
fi

# Memeriksa versi terbaru Xray-core
print_msg $YB "Memeriksa versi terbaru Xray-core..."
get_latest_xray_version
print_msg $GB "Versi terbaru Xray-core: $LATEST_VERSION"

# Memasang dependensi yang diperlukan
print_msg $YB "Memasang dependensi yang diperlukan..."
if [[ "$OS" == "Ubuntu" || "$OS" == "Debian" ]]; then
    sudo apt update
    sudo apt install -y curl unzip
elif [[ "$OS" == "CentOS" || "$OS" == "Fedora" || "$OS" == "Red Hat Enterprise Linux" ]]; then
    sudo yum install -y curl unzip
fi
check_success "Gagal memasang dependensi yang diperlukan."

# Memasang Xray-core
install_xray_core

print_msg $GB "Pemasangan Xray-core versi $LATEST_VERSION selesai."

# Mengumpulkan informasi dari ipinfo.io
print_msg $YB "Mengumpulkan informasi lokasi dari ipinfo.io..."
curl -s ipinfo.io/city?token=f209571547ff6b | sudo tee /usr/local/etc/xray/city
curl -s ipinfo.io/org?token=f209571547ff6b | cut -d " " -f 2-10 | sudo tee /usr/local/etc/xray/org
curl -s ipinfo.io/timezone?token=f209571547ff6b | sudo tee /usr/local/etc/xray/timezone
curl -s ipinfo.io/region?token=f209571547ff6b | sudo tee /usr/local/etc/xray/region
check_success "Gagal mengumpulkan informasi lokasi."

print_msg $GB "Semua tugas selesai. Xray-core telah dipasang dan dikonfigurasi dengan informasi lokasi."
sleep 3
clear

# Menampilkan pesan interaktif
print_msg $YB "Selamat datang! Skrip ini akan menginstal Speedtest CLI dan mengatur zona waktu Anda."
sleep 3

# Mengunduh dan menginstal Speedtest CLI
print_msg $YB "Mengunduh dan menginstal Speedtest CLI..."
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash &>/dev/null
sudo apt-get install -y speedtest &>/dev/null
print_msg $YB "Speedtest CLI berhasil diinstal."

# Mengatur zona waktu ke Asia/Jakarta
print_msg $YB "Mengatur zona waktu ke Asia/Jakarta..."
sudo timedatectl set-timezone Asia/Jakarta &>/dev/null
print_msg $YB "Zona waktu berhasil diatur."

# Memberikan pesan penyelesaian
print_msg $YB "Instalasi selesai."
sleep 3
clear

# Selamat datang
print_msg $YB "Selamat datang! Skrip ini akan memasang dan mengkonfigurasi WireProxy untuk WARP pada sistem Anda."

print_msg $YB "Instalasi WireProxy"
rm -rf /usr/local/bin/wireproxy >> /dev/null 2>&1
wget -q -O /usr/local/bin/wireproxy https://github.com/xcozyx/v1/raw/main/wireproxy
chmod +x /usr/local/bin/wireproxy
check_success "Gagal instalasi WireProxy."
print_msg $YB "Mengkonfigurasi WireProxy"
cat > /etc/wireproxy.conf << END
[Interface]
PrivateKey = 4Osd07VYMrPGDtrJfRaRZ+ynuscBVi4PjzOZmLUJDlE=
Address = 172.16.0.2/32, 2606:4700:110:8fdc:f256:b15d:9e5c:5d1/128
DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001
MTU = 1280

[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
AllowedIPs = 0.0.0.0/0
AllowedIPs = ::/0
Endpoint = engage.cloudflareclient.com:2408

[Socks5]
BindAddress = 127.0.0.1:40000
END
check_success "Gagal mengkonfigurasi WireProxy."

print_msg $YB "Membuat service untuk WireProxy"
cat > /etc/systemd/system/wireproxy.service << END
[Unit]
Description=WireProxy for WARP
After=network.target

[Service]
ExecStart=/usr/local/bin/wireproxy -c /etc/wireproxy.conf
RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
END
check_success "Gagal membuat service untuk WireProxy."
sudo systemctl enable wireproxy
sudo systemctl start wireproxy
sudo systemctl daemon-reload
sudo systemctl restart wireproxy
print_msg $YB "Instalasi selesai."
sleep 3
clear

# Selamat datang
print_msg $YB "Selamat datang! Skrip ini akan memasang dan mengkonfigurasi Nginx pada sistem Anda."

# Mendapatkan informasi distribusi dan codename
print_msg $YB "Mendeteksi distribusi dan codename Linux..."

# Fungsi untuk mendeteksi OS
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
  else
    print_error "OS tidak didukung. Hanya mendukung Ubuntu dan Debian."
    exit 1
  fi
}

# Fungsi untuk menambahkan repositori Nginx
add_nginx_repo() {
  if [ "$OS" == "ubuntu" ]; then
    sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring -y
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
  elif [ "$OS" == "debian" ]; then
    sudo apt install curl gnupg2 ca-certificates lsb-release debian-archive-keyring -y
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
  else
    print_error "OS tidak didukung. Hanya mendukung Ubuntu dan Debian."
    exit 1
  fi
}

# Fungsi untuk menginstal Nginx
install_nginx() {
  sudo apt update
  sudo apt install nginx -y
  sudo systemctl start nginx
  sudo systemctl enable nginx
}

# Fungsi utama
main_nginx() {
  detect_os
  add_nginx_repo
  install_nginx
}

# Menjalankan fungsi utama
main_nginx

# Menghapus konfigurasi default Nginx dan konten default web
print_msg $YB "Menghapus konfigurasi default Nginx dan konten default web..."
rm -rf /etc/nginx/conf.d/default.conf >> /dev/null 2>&1
rm -rf /etc/nginx/sites-enabled/default >> /dev/null 2>&1
rm -rf /etc/nginx/sites-available/default >> /dev/null 2>&1
rm -rf /var/www/html/* >> /dev/null 2>&1
sudo systemctl restart nginx
check_success "Gagal menghapus konfigurasi default Nginx dan konten default web."

# Membuat direktori untuk Xray
print_msg $YB "Membuat direktori untuk Xray di /var/www/html..."
mkdir -p /var/www/html/xray >> /dev/null 2>&1
check_success "Gagal membuat direktori untuk Xray."

# Pesan selesai
print_msg $GB "Pemasangan dan konfigurasi Nginx telah selesai."
sleep 3
clear
systemctl restart nginx
systemctl stop nginx
systemctl stop xray
mkdir -p /usr/local/etc/xray/config >> /dev/null 2>&1
mkdir -p /usr/local/etc/xray/dns >> /dev/null 2>&1
touch /usr/local/etc/xray/dns/domain

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

# Fungsi untuk menginstal acme.sh dan mendapatkan sertifikat
install_acme_sh() {
    domain=$(cat /usr/local/etc/xray/dns/domain)
    rm -rf ~/.acme.sh/*_ecc >> /dev/null 2>&1
    export CF_Email="xcozystore@gmail.com"
    export CF_Key="828af7595609da87cc0503e2233f5ebb23b97"
    curl https://get.acme.sh | sh
    source ~/.bashrc
    ~/.acme.sh/acme.sh --register-account -m $(echo $RANDOM | md5sum | head -c 6; echo;)@gmail.com --server letsencrypt
    ~/.acme.sh/acme.sh --issue --dns dns_cf -d $domain -d *.$domain --listen-v6 --server letsencrypt --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.cer --key-file /usr/local/etc/xray/private.key --reloadcmd "systemctl restart nginx" --force
    chmod 745 /usr/local/etc/xray/private.key
    echo -e "Sertifikat SSL berhasil dipasang!"
}

install_acme_sh2() {
    domain=$(cat /usr/local/etc/xray/dns/domain)
    rm -rf ~/.acme.sh/*_ecc >> /dev/null 2>&1
    curl https://get.acme.sh | sh
    source ~/.bashrc
    ~/.acme.sh/acme.sh --register-account -m $(echo $RANDOM | md5sum | head -c 6; echo;)@gmail.com --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d $domain --standalone --listen-v6 --server letsencrypt --keylength ec-256 --fullchain-file /usr/local/etc/xray/fullchain.cer --key-file /usr/local/etc/xray/private.key --reloadcmd "systemctl restart nginx" --force
    chmod 745 /usr/local/etc/xray/private.key
    echo -e "Sertifikat SSL berhasil dipasang!"
}

# Fungsi untuk menampilkan menu utama
setup_domain() {
    while true; do
        clear

        # Menampilkan judul
        echo -e "—————————————"
        echo -e "SETUP DOMAIN"
        echo -e "—————————————"

        # Menampilkan pilihan untuk menggunakan domain acak atau domain sendiri
        echo -e "Pilih Opsi:"
        echo -e "1. Gunakan domain yang tersedia"
        echo -e "2. Gunakan domain sendiri"

        # Meminta input dari pengguna untuk memilih opsi
        read -rp $'\e[33;1mMasukkan pilihan Anda: \e[0m' choice

        # Memproses pilihan pengguna
        case $choice in
            1)
                while true; do
                    echo -e "Pilih Domain anda:"
                    echo -e "1. recycle.us.kg"
                    echo -e "2. xlab.biz.id"
                    echo -e " "
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
                        echo -e " "
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
                                install_acme_sh
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
                                        install_acme_sh
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
                install_acme_sh2
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

# Panggil fungsi install_acme_sh untuk menginstal acme.sh dan mendapatkan sertifikat
#install_acme_sh
#install_acme_sh2

# Menjalankan menu utama
setup_domain

echo -e "[ INFO ] Setup Nginx & Xray Config"
# Menghasilkan UUID
uuid=$(cat /proc/sys/kernel/random/uuid)

# Menghasilkan password random
pwtr=$(openssl rand -hex 4)
pwss=$(echo $RANDOM | md5sum | head -c 6; echo;)

# Menghasilkan PSK (Pre-Shared Key) untuk pengguna dan server
userpsk=$(openssl rand -base64 32)
serverpsk=$(openssl rand -base64 32)
echo "$serverpsk" > /usr/local/etc/xray/serverpsk

# Konfigurasi Xray-core
print_msg $YB "Mengonfigurasi Xray-core..."
XRAY_CONFIG=raw.githubusercontent.com/xcozyx/v1/main/config
wget -q -O /usr/local/etc/xray/config/00_log.json "https://${XRAY_CONFIG}/00_log.json"
wget -q -O /usr/local/etc/xray/config/01_api.json "https://${XRAY_CONFIG}/01_api.json"
wget -q -O /usr/local/etc/xray/config/02_dns.json "https://${XRAY_CONFIG}/02_dns.json"
wget -q -O /usr/local/etc/xray/config/03_policy.json "https://${XRAY_CONFIG}/03_policy.json"
cat > /usr/local/etc/xray/config/04_inbounds.json << END
{
    "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api"
    },
# XTLS
    {
      "listen": "::",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "flow": "xtls-rprx-vision",
            "id": "$uuid"
#xtls
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "alpn": "h2",
            "dest": 4443,
            "xver": 2
          },
          {
            "dest": 8080,
            "xver": 2
          },
          // Websocket
          {
            "path": "/vless-ws",
            "dest": "@vless-ws",
            "xver": 2
          },
          {
            "path": "/vmess-ws",
            "dest": "@vmess-ws",
            "xver": 2
          },
          {
            "path": "/trojan-ws",
            "dest": "@trojan-ws",
            "xver": 2
          },
          // HTTPupgrade
          {
            "path": "/vless-hup",
            "dest": "@vl-hup",
            "xver": 2
          },
          {
            "path": "/vmess-hup",
            "dest": "@vm-hup",
            "xver": 2
          },
          {
            "path": "/trojan-hup",
            "dest": "@tr-hup",
            "xver": 2
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "tlsSettings": {
          "certificates": [
            {
              "ocspStapling": 3600,
              "certificateFile": "/usr/local/etc/xray/fullchain.cer",
              "keyFile": "/usr/local/etc/xray/private.key"
            }
          ],
          "minVersion": "1.2",
          "cipherSuites": "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "tcp",
        "security": "tls"
      },
      "tag": "in-01"
    },
# TROJAN TCP TLS
    {
      "listen": "127.0.0.1",
      "port": 4443,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ],
        "fallbacks": [
          {
            "dest": "8443",
            "xver": 2
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "tcpSettings": {
          "acceptProxyProtocol": true
        },
        "network": "tcp",
        "security": "none"
      },
      "tag": "in-02"
    },
# VLESS WS
    {
      "listen": "@vless-ws",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email":"general@vless-ws",
            "id": "$uuid"
#vless
          }
        ],
        "decryption": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vless-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-03"
    },
# VMESS WS
    {
      "listen": "@vmess-ws",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email": "general@vmess-ws", 
            "id": "$uuid"
#vmess
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmess-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-04"
    },
# TROJAN WS
    {
      "listen": "@trojan-ws",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-05"
    },
# VLESS HTTPupgrade
    {
      "listen": "@vl-hup",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email":"general@vless-ws",
            "id": "$uuid"
#vless
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/vless-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-08"
    },
# VMESS HTTPupgrade
    {
      "listen": "@vm-hup",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email":"general@vless-ws",
            "id": "$uuid"
#vmess
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/vmess-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-09"
    },
# TROJAN HTTPupgrade
    {
      "listen": "@tr-hup",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ]
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-10"
    },
# VLESS gRPC
    {
      "listen": "127.0.0.1",
      "port": 5000,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email": "grpc",
            "id": "$uuid"
#vless
          }
        ],
        "decryption": "none",
        "fallbacks": []
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "grpcSettings": {
          "multiMode": true,
          "serviceName": "vless-grpc",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "grpc",
        "security": "none"
      },
      "tag": "in-13"
    },
# VMESS gRPC
    {
      "listen": "127.0.0.1",
      "port": 5100,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "email": "grpc",
            "id": "$uuid"
#vmess
          }
        ],
        "decryption": "none",
        "fallbacks": []
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "grpcSettings": {
          "multiMode": true,
          "serviceName": "vmess-grpc",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "grpc",
        "security": "none"
      },
      "tag": "in-14"
    },
# TROJAN gRPC
    {
      "listen": "127.0.0.1",
      "port": 5200,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "email": "grpc",
            "password": "$pwtr"
#trojan
          }
        ],
        "decryption": "none",
        "fallbacks": []
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "grpcSettings": {
          "multiMode": true,
          "serviceName": "trojan-grpc",
          "alpn": [
            "h2",
            "http/1.1"
          ]
        },
        "network": "grpc",
        "security": "none"
      },
      "tag": "in-15"
    },
    {
      "port": 80,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$uuid"
#universal
          }
        ],
        "fallbacks": [
          {
            "dest": 8080,
            "xver": 2
          },
          // Websocket
          {
            "path": "/vless-ws",
            "dest": "@vless-ws",
            "xver": 2
          },
          {
            "path": "/vmess-ws",
            "dest": "@vmess-ws",
            "xver": 2
          },
          {
            "path": "/trojan-ws",
            "dest": "@trojan",
            "xver": 2
          },
          {
            "dest": 2000,
            "xver": 2
          },
          {
            "dest": 2100,
            "xver": 2
          },
          // HTTPupgrade
          {
            "path": "/vless-hup",
            "dest": "@vl-hup",
            "xver": 2
          },
          {
            "path": "/vmess-hup",
            "dest": "@vm-hup",
            "xver": 2
          },
          {
            "path": "/trojan-hup",
            "dest": "@trojan-hup",
            "xver": 2
          }
        ],
        "decryption": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-18"
    },
# TROJAN WS
    {
      "listen": "@trojan",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ]
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "streamSettings": {
        "wsSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-ws"
        },
        "network": "ws",
        "security": "none"
      },
      "tag": "in-19"
    },
# TROJAN HTTPupgrade
    {
      "listen": "@trojan-hup",
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$pwtr"
#trojan
          }
        ]
      },
      "streamSettings": {
        "httpupgradeSettings": {
          "acceptProxyProtocol": true,
          "path": "/trojan-hup"
        },
        "network": "httpupgrade",
        "security": "none"
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "in-22"
    }
  ]
}
END
wget -q -O /usr/local/etc/xray/config/05_outbonds.json "https://${XRAY_CONFIG}/05_outbonds.json"
wget -q -O /usr/local/etc/xray/config/06_routing.json "https://${XRAY_CONFIG}/06_routing.json"
wget -q -O /usr/local/etc/xray/config/07_stats.json "https://${XRAY_CONFIG}/07_stats.json"
sleep 1.5

# Membuat file log Xray yang diperlukan
print_msg $YB "Membuat file log Xray yang diperlukan..."
sudo touch /var/log/xray/access.log /var/log/xray/error.log
sudo chown nobody:nogroup /var/log/xray/access.log /var/log/xray/error.log
sudo chmod 664 /var/log/xray/access.log /var/log/xray/error.log
check_success "Gagal membuat file log Xray yang diperlukan."
sleep 1.5

# Konfigurasi Nginx
print_msg $YB "Mengonfigurasi Nginx..."
wget -q -O /var/www/html/index.html https://raw.githubusercontent.com/xcozyx/v1/main/index.html
wget -q -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/xcozyx/v1/main/nginx.conf
domain=$(cat /usr/local/etc/xray/dns/domain)
sed -i "s/server_name web.com;/server_name $domain;/g" /etc/nginx/nginx.conf
sed -i "s/server_name \*.web.com;/server_name \*.$domain;/" /etc/nginx/nginx.conf
# Jika sampai di sini tidak ada error, maka konfigurasi berhasil
print_msg $GB "Konfigurasi Xray-core dan Nginx berhasil."
sleep 3
systemctl restart nginx
systemctl restart xray
echo -e "[ INFO ] Setup Done"
sleep 3
clear

# Blokir lalu lintas torrent (BitTorrent)
sudo iptables -A INPUT -p udp --dport 6881:6889 -j DROP
sudo iptables -A INPUT -p tcp --dport 6881:6889 -j DROP
# Blokir lalu lintas torrent dengan modul string
sudo iptables -A INPUT -p tcp --dport 6881:6889 -m string --algo bm --string "BitTorrent" -j DROP
sudo iptables -A INPUT -p udp --dport 6881:6889 -m string --algo bm --string "BitTorrent" -j DROP
cd /usr/bin
GITHUB=raw.githubusercontent.com/xcozyx/v1/main/
echo -e "[ INFO ] Mengunduh menu utama..."
wget -q -O menu "https://${GITHUB}/menu/menu.sh"
wget -q -O allxray "https://${GITHUB}/menu/allxray.sh"
wget -q -O del-xray "https://${GITHUB}/xray/del-xray.sh"
wget -q -O extend-xray "https://${GITHUB}/xray/extend-xray.sh"
wget -q -O create-xray "https://${GITHUB}/xray/create-xray.sh"
wget -q -O cek-xray "https://${GITHUB}/xray/cek-xray.sh"
wget -q -O route-xray "https://${GITHUB}/xray/route-xray.sh"
wget -q -O system_info.py "https://${GITHUB}/system_info.py"
wget -q -O traffic.py "https://${GITHUB}/traffic.py"
sleep 0.5
sleep 0.5

echo -e "[ INFO ] Mengunduh menu lainnya..."
wget -q -O xp "https://${GITHUB}/other/xp.sh"
wget -q -O dns "https://${GITHUB}/other/dns.sh"
wget -q -O certxray "https://${GITHUB}/other/certxray.sh"
wget -q -O about "https://${GITHUB}/other/about.sh"
wget -q -O clear-log "https://${GITHUB}/other/clear-log.sh"
wget -q -O log-xray "https://${GITHUB}/other/log-xray.sh"
wget -q -O update-xray "https://${GITHUB}/other/update-xray.sh"
wget -q -O update-menu "https://${GITHUB}/other/updatemenu.sh"
wget -q -O bot-notif "https://${GITHUB}/other/bot-notif.sh"

echo -e "[ INFO ] Memberikan izin eksekusi pada skrip..."
chmod +x bot-notif update-menu del-xray extend-xray create-xray cek-xray log-xray menu allxray xp dns certxray about clear-log update-xray route-xray
echo -e "[ INFO ] Persiapan Selesai."
sleep 3
cd
echo "0 0 * * * root xp" >> /etc/crontab
echo "*/3 * * * * root clear-log" >> /etc/crontab
systemctl restart cron
clear
echo ""
echo -e "—————————————————————————————"
echo -e "    XRAY SCRIPT BY DUGONG"
echo -e "—————————————————————————————"
echo -e " »»» Protocol Service «««  "
echo -e "—————————————————————————————"
echo -e "Vmess Websocket     : 443 & 80"
echo -e "Vmess HTTPupgrade   : 443 & 80"
echo -e "Vmess gRPC          : 443"
echo ""
echo -e "Vless XTLS-Vision   : 443"
echo -e "Vless Websocket     : 443 & 80"
echo -e "Vless HTTPupgrade   : 443 & 80"
echo -e "Vless gRPC          : 443"
echo ""
echo -e "Trojan TCP TLS      : 443"
echo -e "Trojan Websocket    : 443 & 80"
echo -e "Trojan HTTPupgrade  : 443 & 80"
echo -e "Trojan gRPC         : 443"
echo -e "————————————————————————————"
echo ""
rm -f install.sh
secs_to_human "$(($(date +%s) - ${start}))"
echo -e "[ WARNING ] reboot now ? (Y/N) "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
reboot
fi
