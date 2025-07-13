#!/bin/bash
set -e
echo "User-data started at $(date)" >> /var/log/user-data.log
# Gerekli paketler
apt-get update -y
echo "Updated"
DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard iptables-persistent curl
echo "WireGuard setup done at $(date)" >> /var/log/user-data.log
# Anahtarlar
umask 077
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server_private.key)
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)

# Client key oluştur
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

# WireGuard yapılandırması
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE_KEY
SaveConfig = true

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
EOF

# IP yönlendirme
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1
sysctl -p

iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o ens5 -j MASQUERADE
netfilter-persistent save

# WireGuard servisi
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# İstemci konfigürasyonu
cat <<EOF > /home/ubuntu/client.conf
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $PUBLIC_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

chown ubuntu:ubuntu /home/ubuntu/client.conf
chmod 600 /home/ubuntu/client.conf

