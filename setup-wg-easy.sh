#!/bin/bash
set -euo pipefail

# Cài đặt Docker, docker-compose, UFW
sudo apt update
sudo apt install -y docker.io docker-compose ufw iptables curl

# Kích hoạt IP forwarding và NAT
sudo sysctl -w net.ipv4.ip_forward=1
sudo sh -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'
sudo iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || \
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Tạo folder wg-easy
mkdir -p ~/wg-easy
cd ~/wg-easy

# Tạo docker-compose.yml
cat > docker-compose.yml <<EOD
version: "3.8"

services:
  wg-easy:
    container_name: wg-easy
    image: weejewel/wg-easy
    restart: always
    environment:
      - WG_HOST=\$(curl -s https://api.ipify.org)
      - PASSWORD=Hal0cvietn@m@123
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    volumes:
      - ./config:/etc/wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
EOD

# Chạy wg-easy
docker-compose up -d

# Cấu hình UFW sau khi Docker đã chạy thành công
sudo ufw allow ssh
sudo ufw allow 51820/udp
yes | sudo ufw enable

# Thông báo hoàn tất
echo -e "\n✅ WireGuard setup hoàn tất!"
echo "👉 Truy cập http://$(curl -s https://api.ipify.org):51821"
echo "🔐 Mật khẩu đăng nhập: Hal0cvietn@m@123"
