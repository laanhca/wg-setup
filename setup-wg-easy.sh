#!/bin/bash
set -euo pipefail

# ------------------ CÀI ĐẶT HỆ THỐNG ------------------
echo "🔧 Cài đặt Docker, Docker Compose và UFW..."
sudo apt update
sudo apt install -y docker.io docker-compose ufw iptables curl

# ------------------ CẤU HÌNH MẠNG ------------------
echo "🌐 Kích hoạt IP forwarding và NAT..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo sh -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'

sudo iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || \
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# ------------------ TẠO FOLDER VÀ FILE COMPOSE ------------------
echo "📁 Tạo thư mục và file docker-compose.yml..."

mkdir -p ~/wg-easy
cd ~/wg-easy

# Lấy IP công khai VPS để gán vào biến môi trường
WG_HOST=$(curl -s https://api.ipify.org)

cat > docker-compose.yml <<EOD
version: "3.8"

services:
  wg-easy:
    container_name: wg-easy
    image: weejewel/wg-easy
    restart: always
    environment:
      - WG_HOST=${WG_HOST}
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

# ------------------ KHỞI CHẠY WG-EASY ------------------
echo "🚀 Khởi động dịch vụ wg-easy..."
docker-compose up -d

# ------------------ CẤU HÌNH FIREWALL (UFw) ------------------
echo "🛡️ Cấu hình firewall..."
sudo ufw allow ssh
sudo ufw allow 51820/udp
yes | sudo ufw enable

# ------------------ HOÀN TẤT ------------------
echo -e "\n✅ Hoàn tất cài đặt WireGuard VPN với wg-easy!"
echo "👉 Truy cập: http://${WG_HOST}:51821"
echo "🔐 Mật khẩu đăng nhập: Hal0cvietn@m@123"
