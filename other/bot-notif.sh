#!/bin/bash

read -p "Masukkan BOT_TOKEN Anda: " BOT_TOKEN
read -p "Masukkan USER ID Anda: " CHAT_ID

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "BOT_TOKEN dan USER ID tidak boleh kosong!"
    exit 1
fi

echo "$BOT_TOKEN" > /etc/bot_telegram
echo "$CHAT_ID" > /etc/user_telegram

chmod 600 /etc/bot_telegram /etc/user_telegram
clear
allxray