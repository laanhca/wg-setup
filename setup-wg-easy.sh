#!/bin/bash
set -euo pipefail

sudo apt update
sudo apt install -y docker.io docker-compose ufw iptables curl

sudo ufw allow ssh
sudo ufw allow 51820/udp
yes | sudo ufw enable

sudo sysctl -w net.ipv4.ip_forward=1
sudo sh -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'

sudo iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || \
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

mkdir -p ~/wg-easy
cd ~/wg-easy

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

docker-compose up -d

echo "✅ Cài đặt xong! Truy cập http://\$(curl -s https://api.ipify.org):51821"
