#!/bin/bash

# Kullanım kontrolü
if [ "$#" -ne 1 ]; then
    echo "Kullanım: $0 <kullanıcı_adı>"
    exit 1
fi

# Server IP kontrolü
if [ -z "$SERVER_IP" ]; then
    echo "Hata: SERVER_IP environment variable tanımlanmamış!"
    exit 1
fi

USERNAME=$1
CONFIG_DIR="/etc/wireguard"
CLIENT_CONFIG_DIR="/home/ubuntu/client-configs"
PRIVATE_KEY_FILE="$CONFIG_DIR/client_${USERNAME}_private.key"
PUBLIC_KEY_FILE="$CONFIG_DIR/client_${USERNAME}_public.key"

# Gerekli dizinlerin varlığını kontrol et ve sahipliğini ayarla
if [ ! -d "$CLIENT_CONFIG_DIR" ]; then
    mkdir -p "$CLIENT_CONFIG_DIR"
    chown ubuntu:ubuntu "$CLIENT_CONFIG_DIR"
    chmod 700 "$CLIENT_CONFIG_DIR"
else
    # Dizin varsa da sahipliğini kontrol et
    chown ubuntu:ubuntu "$CLIENT_CONFIG_DIR"
fi

# Mevcut client sayısını bul ve yeni IP ata
LAST_IP=$(wg show wg0 allowed-ips | grep -oE "10\.0\.0\.[0-9]+" | sort -V | tail -n1)
if [ -z "$LAST_IP" ]; then
    NEW_IP="10.0.0.2"
else
    LAST_NUM=$(echo "$LAST_IP" | cut -d. -f4)
    NEW_NUM=$((LAST_NUM + 1))
    if [ $NEW_NUM -gt 254 ]; then
        echo "Maksimum client sayısına ulaşıldı!"
        exit 1
    fi
    NEW_IP="10.0.0.$NEW_NUM"
fi

# Client için yeni key pair oluştur
wg genkey | tee "$PRIVATE_KEY_FILE" | wg pubkey > "$PUBLIC_KEY_FILE"
CLIENT_PRIVATE_KEY=$(cat "$PRIVATE_KEY_FILE")
CLIENT_PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")

# Server public key'i al
SERVER_PUBLIC_KEY=$(wg show wg0 public-key)
SERVER_PORT=$(wg show wg0 listen-port)

# Client config dosyasını oluştur
CLIENT_CONFIG="$CLIENT_CONFIG_DIR/${USERNAME}.conf"
cat > "$CLIENT_CONFIG" << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $NEW_IP/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:$SERVER_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# Client config dosyasının sahipliğini ayarla
chown ubuntu:ubuntu "$CLIENT_CONFIG"
chmod 600 "$CLIENT_CONFIG"

# Yeni peer'ı WireGuard'a ekle
wg set wg0 peer "$CLIENT_PUBLIC_KEY" allowed-ips "$NEW_IP/32"

# Değişiklikleri kaydet
wg-quick save wg0

cat "$CLIENT_CONFIG"
