#!/bin/bash

# Kullanım kontrolü
if [ "$#" -ne 1 ]; then
    echo "Kullanım: $0 <kullanıcı_adı>"
    exit 1
fi

# Terraform output'larını al
SERVER_IP=$(terraform output -raw vpn_server_ip)
SSH_KEY=$(terraform output -raw ssh_private_key)
SSH_USER=$(terraform output -raw ssh_user)

# Kullanıcı adını al
USERNAME=$1

# Uzak sunucuda script'i çalıştır ve çıktıyı kaydet
echo "VPN kullanıcısı oluşturuluyor: $USERNAME"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" "export SERVER_IP=$SERVER_IP && sudo -E bash /home/ubuntu/add_vpn_user.sh $USERNAME" > "${USERNAME}_vpn_config.conf"

if [ $? -eq 0 ]; then
    echo "VPN yapılandırması başarıyla oluşturuldu!"
    echo "Yapılandırma dosyası: ${USERNAME}_vpn_config.txt"
else
    echo "Hata: VPN kullanıcısı oluşturulamadı!"
    exit 1
fi 