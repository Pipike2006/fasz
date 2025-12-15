#!/bin/bash
# ==========================================
# DEBIAN SERVER ULTIMATE INSTALLER
# Készítette: A Te AI Asszisztensed
# ==========================================
# --- Színek definíciója a "csili-vili" hatáshoz ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
# --- Függvények ---
print_banner() {
   clear
   echo -e "${CYAN}"
   echo "  _____  ______ ____  _          _   _   "
   echo " |  __ \|  ____|  _ \(_)   /\   | \ | |  "
   echo " | |  | | |__  | |_) |_   /  \  |  \| |  "
   echo " | |  | |  __| |  _ <| | / /\ \ | . ' |  "
   echo " | |__| | |____| |_) | |/ ____ \| |\  |  "
   echo " |_____/|______|____/|_/_/    \_\_| \_|  "
   echo "                                         "
   echo "  SERVER AUTO-INSTALLER v1.0             "
   echo -e "${NC}"
   echo -e "${YELLOW}A telepítés hamarosan kezdődik...${NC}"
   echo "-----------------------------------------"
   sleep 2
}
check_root() {
   if [ "$EUID" -ne 0 ]; then
       echo -e "${RED}[HIBA] Kérlek futtasd ezt a scriptet root-ként (sudo)!${NC}"
       exit 1
   fi
}
print_status() {
   echo -e "${BLUE}[INFO]${NC} $1"
}
print_success() {
   echo -e "${GREEN}[SIKER]${NC} $1"
}
print_warning() {
   echo -e "${YELLOW}[FIGYELEM]${NC} $1"
}
# --- Fő Logika ---
check_root
print_banner
# 1. Rendszer frissítése
print_status "Rendszer csomaglisták frissítése..."
apt-get update -y && apt-get upgrade -y
print_success "Rendszer naprakész."
# 2. Alapvető eszközök
print_status "Alapvető eszközök telepítése (curl, git, build-essential)..."
apt-get install -y curl wget git build-essential software-properties-common
print_success "Alapvető eszközök telepítve."
# 3. OpenSSH Server
print_status "OpenSSH Server telepítése..."
apt-get install -y openssh-server
systemctl enable ssh
systemctl start ssh
print_success "SSH szerver fut."
# 4. Apache2 Web Server
print_status "Apache2 webszerver telepítése..."
apt-get install -y apache2
systemctl enable apache2
print_success "Apache2 telepítve."
# 5. MariaDB (SQL)
print_status "MariaDB (MySQL) szerver telepítése..."
apt-get install -y mariadb-server
systemctl enable mariadb
print_success "MariaDB telepítve."
print_warning "Ajánlott futtatni a 'sudo mysql_secure_installation' parancsot a telepítés végén!"
# 6. PHP és modulok
print_status "PHP és szükséges modulok telepítése..."
apt-get install -y php libapache2-mod-php php-mysql php-mbstring php-zip php-gd
print_success "PHP környezet kész."
# 7. phpMyAdmin
print_warning "A phpMyAdmin telepítése interaktív ablakot dobhat fel (kék háttér)."
print_warning "Válaszd az 'apache2'-t (SPACE gombbal jelöld ki, majd ENTER), és nyomj 'Yes'-t a dbconfig-hoz."
sleep 3
apt-get install -y phpmyadmin
# Linkelés, hogy elérhető legyen /phpmyadmin alatt
if [ ! -f /etc/apache2/conf-enabled/phpmyadmin.conf ]; then
   ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf
fi
systemctl reload apache2
print_success "phpMyAdmin telepítve."
# 8. Python
print_status "Python3 és PIP telepítése..."
apt-get install -y python3 python3-pip python3-venv
print_success "Python3 telepítve."
# 9. Mosquitto (MQTT)
print_status "Mosquitto MQTT Broker telepítése..."
apt-get install -y mosquitto mosquitto-clients
systemctl enable mosquitto
print_success "Mosquitto telepítve."
# 10. Node.js és Node-RED
print_status "Node.js (LTS verzió) repo hozzáadása..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
print_status "Node.js telepítése..."
apt-get install -y nodejs
print_status "Node-RED telepítése globálisan..."
npm install -g --unsafe-perm node-red

# Node-RED service létrehozása systemd-vel
print_status "Node-RED automatikus indításának beállítása..."
cat << EOF > /etc/systemd/system/node-red.service
[Unit]
Description=Node-RED
After=syslog.target network.target
[Service]
ExecStart=/usr/bin/node-red --max-old-space-size=128 -v
Restart=on-failure
KillSignal=SIGINT
SyslogIdentifier=node-red
StandardOutput=syslog
User=root
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable node-red
systemctl start node-red
print_success "Node-RED telepítve és elindítva."
# --- Befejezés ---
echo "-----------------------------------------"
echo -e "${GREEN}TELEPÍTÉS BEFEJEZŐDÖTT!${NC}"
echo "-----------------------------------------"
echo -e "Elérhetőségek:"
echo -e "Webszerver:    http://SZERVER_IP/"
echo -e "phpMyAdmin:    http://SZERVER_IP/phpmyadmin"
echo -e "Node-RED:      http://SZERVER_IP:1880"
echo -e "SSH:           port 22"
echo -e "Mosquitto:     port 1883"
echo "-----------------------------------------"
