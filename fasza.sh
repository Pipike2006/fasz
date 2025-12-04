#!/bin/bash

# --- Változók és Színek ---
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'
TARGETS="Apache2, MariaDB, phpMyAdmin (Non-Interactive), MC, Python3, Mosquitto, Node-RED"
# !!! FONTOS: AUTOMATIKUS JELSZÓ BEÁLLÍTÁS A PHPMyAdmin / MariaDB számára !!!
# Ezt az értéket MÓDOSÍTSD, ha éles környezetben használod!
PMA_PASSWORD="supersecurepassword"

# --- Funkciók ---

function header() {
    echo -e "${PURPLE}"
    echo "  ╔═══════════════════════════════════════════════════╗"
    echo "  ║      ** HackTheStack.sh v2.0 - FULL AUTO-DEPLOY ** ║"
    echo "  ║      (NO INTERACTION MODE - AURASYNTH ACTIVE)     ║"
    echo "  ║  Target Stack: $TARGETS   ║"
    echo "  ╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    sleep 1
}

function status_msg() {
    echo -e "\n${PURPLE}[... AURASYNTH ... ]${NC} >> ${1}"
    sleep 0.5
}

function success_msg() {
    echo -e "${GREEN}[** STACK_ONLINE ** ]${NC} >> ${1}"
}

function error_msg() {
    echo -e "\n${RED}[!! FATAL_ERROR !!]${NC} >> ${1}"
}

# Ellenőrzi, hogy rootként fut-e
if [ "$EUID" -ne 0 ]; then
    error_msg "Ez a script root jogosultságot igényel. Kérlek futtasd: sudo ./script_neve.sh"
    exit 1
fi

# --- Fő Logika ---

header

# Állítsuk be a non-interaktív módot a teljes scriptre
export DEBIAN_FRONTEND=noninteractive

status_msg "Rendszer Frissítés és Előkészítés (Silent Mode: ON)..."
apt update -qq > /dev/null 2>&1 && apt upgrade -y -qq > /dev/null 2>&1
if [ $? -eq 0 ]; then
    success_msg "Rendszer Előkészítve. Kezdődhet a Behatolás..."
else
    error_msg "Hiba az apt frissítése során. Ellenőrizd a hálózatot/repo-kat."
    exit 1
fi

# 1. Apache2, MC, Python3 Telepítése (Alap csomagok)
status_msg "Executing Utility Tools & Apache2 Deployment..."
PACKAGES="apache2 mc python3 python3-pip php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl"
apt install $PACKAGES -y -qq > /dev/null 2>&1
if [ $? -eq 0 ]; then
    success_msg "Apache2, MC, Python3, PHP alapkészlet: Online."
    systemctl enable apache2 > /dev/null 2>&1
    systemctl start apache2 > /dev/null 2>&1
else
    error_msg "Alapcsomagok telepítése sikertelen."
fi

# 2. MariaDB (Adatbázis) Telepítése
status_msg "Accessing DataVault: MariaDB Telepítése..."
apt install mariadb-server mariadb-client -y -qq > /dev/null 2>&1
if [ $? -eq 0 ]; then
    success_msg "MariaDB: Online. (SQL Motor Indítva)"
    systemctl enable mariadb > /dev/null 2>&1
    systemctl start mariadb > /dev/null 2>&1
else
    error_msg "MariaDB Telepítés Sikertelen."
fi

# 3. phpMyAdmin Telepítése (Non-Interactive Setup)
status_msg "Injecting Web-Interface: phpMyAdmin Konfiguráció és Telepítés..."

# Előre konfiguráljuk a debconf adatbázist a non-interaktív telepítéshez
# 1. Használandó webszerver (apache2)
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
# 2. Dbconfig beállítás (dbconfig-common használata)
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
# 3. MySQL jelszó a phpmyadmin felhasználónak
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PMA_PASSWORD" | debconf-set-selections
# 4. MySQL jelszó megerősítése
echo "phpmyadmin phpmyadmin/mysql/app-pass-confirm password $PMA_PASSWORD" | debconf-set-selections

# Telepítés
apt install phpmyadmin -y -qq > /dev/null 2>&1

if [ $? -eq 0 ]; then
    # A telepítés automatikusan engedélyezte volna, de biztos ami biztos
    a2enconf phpmyadmin > /dev/null 2>&1
    systemctl reload apache2 > /dev/null 2>&1
    success_msg "phpMyAdmin: Online. (Lásd: http://localhost/phpmyadmin)"
    echo -e "${PURPLE}[... INFO_LOG ... ]${NC} Az automatikus PMA jelszó: ${GREEN}$PMA_PASSWORD${NC} (Módosítsd!)"
else
    error_msg "phpMyAdmin Telepítés Sikertelen."
fi

# 4. Mosquitto (MQTT Broker) Telepítése
status_msg "Establishing Secure Channel: Mosquitto Telepítése..."
apt install mosquitto -y -qq > /dev/null 2>&1
if [ $? -eq 0 ]; then
    success_msg "Mosquitto: Online. (MQTT Broker Fut)"
    systemctl enable mosquitto > /dev/null 2>&1
    systemctl start mosquitto > /dev/null 2>&1
else
    error_msg "Mosquitto Telepítés Sikertelen."
fi

# 5. Node-RED (npm-en keresztül) Telepítése
status_msg "Initializing Flow Engine: Node.js és Node-RED Telepítése..."

# Node.js/npm telepítése a hivatalos repóból (stabilabb)
curl -sL https://deb.nodesource.com/setup_lts.x | bash - > /dev/null 2>&1
apt install -y nodejs -qq > /dev/null 2>&1

# Node-RED telepítése npm-el globálisan
npm install -g --unsafe-perm node-red > /dev/null 2>&1

if [ $? -eq 0 ]; then
    success_msg "Node-RED: Online. (Futtatás: 'node-red' paranccsal)"
    echo -e "${PURPLE}[... INFO_LOG ... ]${NC} Node-RED futtatás: ${GREEN}node-red${NC}"
else
    error_msg "Node-RED Telepítés Sikertelen. Ellenőrizd a Node.js-t."
fi

# --- MariaDB Biztonsági Beállítás (root jelszó beállítása, ha kell) ---
# Ez kicsit bonyolultabb, de a Debianos MariaDB a Debian root jelszavát használja a `mysql_secure_installation` előtt.
# Bár kérted, hogy automatikus legyen, a biztonsági beállításokat (pl. külső hozzáférés tiltása, teszt adatbázis törlése) 
# egyedi jelszó nélkül nehéz teljesen automatizálni. 
# Itt csak a root jelszavát állítjuk be a fenti PMA_PASSWORD-ra a phpmyadmin kompatibilitás miatt.
status_msg "Securing DataVault: MariaDB Root Jelszó Beállítása (NON-STANDARD)."
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$PMA_PASSWORD';"
if [ $? -eq 0 ]; then
    success_msg "MariaDB Root Jelszó Beállítva: ${GREEN}$PMA_PASSWORD${NC}"
else
    error_msg "MariaDB Root Jelszó Beállítás Hiba. Ellenőrizd a MariaDB logokat."
fi

# --- Befejezés ---

echo -e "\n${GREEN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║         ** DEPLOYMENT COMPLETE - STACK READY ** ║"
echo "  ║      >> VÁLASZ THAT STACK! JÓL MEGVAN Csinálva. << ║"
echo "  ║  Access Points:                                   ║"
echo "  ║  - Web:         http://localhost/                 ║"
echo "  ║  - phpMyAdmin:  http://localhost/phpmyadmin       ║"
echo "  ║  - MariaDB PW:  $PMA_PASSWORD (Root és PMA user)  ║"
echo "  ║  - MQTT:        localhost:1883                    ║"
echo "  ║  - Node-RED:    Futtasd a 'node-red' parancsot!   ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ">> Javaslat: ${RED}AZONNAL${NC} módosítsd az ${RED}automatikus jelszót${NC}!"

# --- Script vége ---
