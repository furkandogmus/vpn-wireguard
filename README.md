# AWS WireGuard VPN Server

Bu proje, AWS üzerinde WireGuard VPN sunucusu kurmak için gerekli Terraform konfigürasyonlarını içerir. WireGuard, modern, hızlı ve güvenli bir VPN protokolüdür.

## Özellikler

- AWS üzerinde otomatik VPN sunucusu kurulumu
- WireGuard VPN yapılandırması
- Güvenli ve hızlı VPN bağlantısı
- Kolay yönetim ve yapılandırma
- **Yeni kullanıcı ekleme sistemi** - Dinamik olarak yeni VPN kullanıcıları ekleyebilirsiniz
- Otomatik IP adresi yönetimi (10.0.0.2'den başlayarak)

## Ön Gereksinimler

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 veya üzeri)
- [AWS CLI](https://aws.amazon.com/cli/) yüklü olmalı
- [WireGuard](https://www.wireguard.com/install/) istemcisi (yerel makinenizde)

### AWS Credentials Yapılandırması

AWS CLI'yi yapılandırmak için aşağıdaki adımları izleyin:

1. AWS IAM konsolundan bir kullanıcı oluşturun ve `AmazonEC2FullAccess` yetkisi verin
2. Access Key ve Secret Access Key'inizi alın
3. Aşağıdaki komutla AWS CLI'yi yapılandırın:
   ```bash
   aws configure
   ```
4. İstenilen bilgileri girin:
   ```
   AWS Access Key ID: [Access Key'iniz]
   AWS Secret Access Key: [Secret Key'iniz]
   Default region name: [Tercih ettiğiniz bölge örn: eu-central-1]
   Default output format: json
   ```

Alternatif olarak, credentials'ları doğrudan `~/.aws/credentials` dosyasına ekleyebilirsiniz:
```ini
[default]
aws_access_key_id = [Access Key'iniz]
aws_secret_access_key = [Secret Key'iniz]
```

## Kurulum

1. Projeyi klonlayın:
   ```bash
   git clone https://github.com/your-username/aws-wireguard-vpn.git
   cd aws-wireguard-vpn
   ```

2. SSH key pair oluşturun:
   ```bash
   # Key pair oluşturma
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/wireguard-key -N ""
   
   # Dosya izinlerini düzenleme
   chmod 400 ~/.ssh/wireguard-key
   chmod 400 ~/.ssh/wireguard-key.pub
   ```

3. `terraform.tfvars.example` dosyasını `terraform.tfvars` olarak kopyalayın ve gerekli değişkenleri ayarlayın:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   Dosyayı düzenleyerek:
   - AWS bölgesini
   - Instance tipini
   - SSH anahtar çifti ayarlarını (oluşturduğunuz key pair'in yolunu)
   güncelleyin.

4. Terraform'u başlatın ve altyapıyı oluşturun:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. Kurulum tamamlandığında, çıktılar arasında VPN sunucusunun IP adresi ve istemci yapılandırma dosyası bulunacaktır.

## VPN Kullanıcı Yönetimi

### İlk Kullanıcı
Terraform kurulumu tamamlandığında, `client.conf` dosyasında ilk kullanıcı yapılandırması bulunur.

### Yeni Kullanıcı Ekleme

1. Script'e çalıştırma izni verin:
   ```bash
   chmod +x scripts/add_client.sh
   ```

2. Yeni bir VPN kullanıcısı ekleyin:
   ```bash
   ./scripts/add_client.sh kullanici_adi
   ```

3. Bu komut:
   - Sunucuya SSH ile bağlanır
   - Yeni bir WireGuard yapılandırması oluşturur
   - Benzersiz IP adresi atar (10.0.0.2'den başlayarak)
   - Yapılandırmayı `kullanici_adi_vpn_config.txt` dosyasına kaydeder

### Örnek Kullanım
```bash
# Furkan adında bir kullanıcı ekle
./scripts/add_client.sh furkan

# Mehmet adında bir kullanıcı ekle
./scripts/add_client.sh mehmet
```

### Özellikler
- **Otomatik IP Yönetimi**: Her yeni kullanıcı için benzersiz IP adresi
- **Güvenli Key Yönetimi**: Her kullanıcı için benzersiz kriptografik anahtarlar
- **Dinamik Yapılandırma**: Sunucu yeniden başlatılmadan kullanıcı ekleme
- **Kolay Kullanım**: Tek komutla kullanıcı ekleme
- **Maksimum Kullanıcı**: 253 kullanıcıya kadar destek (10.0.0.2 - 10.0.0.254)

## İstemci Yapılandırması

1. WireGuard istemcisini yükleyin
2. Oluşturulan yapılandırma dosyasını (.txt uzantılı) WireGuard istemcisine import edin
3. Bağlantıyı başlatın

## Desteklenen AWS Bölgeleri

Proje aşağıdaki AWS bölgelerini destekler:
- **us-east-1**: N. Virginia
- **us-east-2**: Ohio
- **us-west-1**: N. California
- **us-west-2**: Oregon
- **ap-south-1**: Mumbai
- **ap-southeast-1**: Singapore
- **ap-southeast-2**: Sydney
- **ap-northeast-1**: Tokyo
- **ap-northeast-2**: Seoul
- **ap-northeast-3**: Osaka
- **ca-central-1**: Central Canada
- **eu-north-1**: Stockholm
- **eu-west-1**: Ireland
- **eu-west-2**: London
- **eu-west-3**: Paris
- **sa-east-1**: São Paulo

## Güvenlik

- Sunucu sadece WireGuard portu (UDP 51820) ve SSH portu (TCP 22) üzerinden erişilebilir
- AWS Security Group ile güvenlik sağlanır
- Her istemci için benzersiz kriptografik anahtarlar kullanılır
- Disk şifreleme aktif
- Client yapılandırma dosyaları güvenli izinlerle saklanır

## Temizlik

Altyapıyı silmek için:
```bash
terraform destroy
```

## Sorun Giderme

### Key Pair Hatası
Eğer "key pair not found" hatası alırsanız:
1. SSH key pair'in doğru yolda olduğundan emin olun
2. `terraform.tfvars` dosyasındaki key path'leri kontrol edin
3. Key dosyalarının izinlerini kontrol edin (400 olmalı)

### Bölge Değiştirme
Farklı bir AWS bölgesine geçmek için:
1. `terraform.tfvars` dosyasında `aws_region` değerini güncelleyin
2. `terraform apply` komutunu çalıştırın

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## Katkıda Bulunma

1. Bu projeyi fork edin
2. Feature branch'inizi oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Bir Pull Request oluşturun
