#!/bin/bash

# --- Változók és Színek ---
# Zöld: Minden rendben
GREEN='\033[0;32m'
# Lila: Folyamatban lévő vagy kiemelés
PURPLE='\033[0;35m'
# Tiszta: Vissza a normálhoz
NC='\033[0m'
# Célok
TARGETS="Apache2, MariaDB, phpMyAdmin, MC, Python3, Mosquitto, Node-RED"

# --- Funkciók ---

# Hacker Stílusú Fejléc
function header() {
    echo -e "${PURPLE}"
    echo "  ╔═══════════════════════════════════════════════════╗"
    echo "  ║      ** HackTheStack.sh v1.0 - Auto-Deploy ** ║"
    echo "  ║  Target Stack: $TARGETS   ║"
    echo "  ╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    sleep 1
}

# Állapot Jelzés
function status_msg() {
    echo -e "\n${PURPLE}[... AURASYNTH ... ]${NC} >> ${1}"
    sleep 0.5
}

# Sikeres Művelet
function success_msg() {
    echo -e "${GREEN}[** STACK_ONLINE ** ]${NC} >> ${1}"
}

# --- Fő Logika ---

header

status_msg "Rendszer Frissítés és Függőségek Előkészítése..."
apt update > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1
if [ $? -eq 0 ]; then
    success_msg "Rendszer Előkészítve. Kezdődhet a Behatolás..."
else
    echo -e "\n${RED}[!! FATAL_ERROR !!]${NC} Hiba az apt frissítése során. Lépjen ki."
    exit 1
fi

# 1. Apache2 (Webszerver) Telepítése
status_msg "Engaging Stealth Mode: Apache2 Webkiszolgáló Telepítése..."
apt install apache2 -y > /dev/null 2>&1
if [ $? -eq 0 ]; then
    success_msg "Apache2: Online. (http://localhost/)"
    systemctl enable apache2 > /dev/null 2>&1
    systemctl start apache2 > /dev/null 2>&1
else
    echo -e "\n${RED}[!! FATAL_ERROR !!]${NC} Apache2 Telepítés Sikertelen."
fi

# 2. MariaDB (Adatbázis) Telepítése
status_msg "Accessing DataVault: MariaDB Telepítése..."
apt install mariadb-server mariadb-client -y > /dev/null 2>&1
if [ $? -eq 0 ]; then
    success_msg "MariaDB: Online. (SQL Motor Indítva)"
    systemctl enable mariadb > /dev/null 2>&1
    systemctl start mariadb > /dev/null 2>&1
else
    echo -e "\n${RED}[!! FATAL_ERROR !!]${NC} MariaDB Telepítés Sikertelen."
fi

# 3. PHP és phpMyAdmin Telepítése (PHPmyadmin függ a PHP-tól)
status_msg "Decrypting Logs: PHP és phpMyAdmin Telepítése..."
apt install php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl -y > /dev/null 2>&1
apt install phpmyadmin -y
# Fontos: A phpMyAdmin telepítéskor megkérdezi, melyik webszervert konfigurálja. 
# Mivel ezt automatizáljuk, a debconf adatbázisban a 'dbconfig-common' jelszót és 
# beállítást manuálisan kellene kezelni a teljes csendes telepítéshez, de az apt install 
# itt leállhat. Feltételezzük, hogy a felhasználó az 'apache2'-t választja, ha interaktív.
# Csendes telepítéshez a DEBIAN_FRONTEND=noninteractive kellene.
# Hozzáadjuk a phpMyAdmin konfigurációs fájlt az Apache-hoz
if [ $? -eq 0 ]; then
    PHPMYADMIN_CONF="/etc/apache2/conf-available/phpmyadmin.conf"
    if [ -f "$PHPMYADMIN_CONF" ]; then
        a2enconf phpmyadmin > /dev/null 2>&1
        success_msg "phpMyAdmin: Online. (Lásd: http://localhost/phpmyadmin)"
    else
        echo -e "\n${PURPLE}[... INFO_LOG ... ]${NC} phpMyAdmin: A kézi beállítást igényelhet. Keresd: /phpmyadmin"
    fi
    systemctl reload apache2 > /dev/null 2>&1
else
    echo -e "\n${RED}[!! FATAL_ERROR !!]${NC} phpMyAdmin Telepítés Sikertelen."
fi


# 4. Midnight Commander (mc) és Python3 Telepítése
status_msg "Executing Utility Tools: MC és Python3 Telepítése..."
apt install mc python3 python3-pip -y > /dev/null 2>&1
if [ $? -eq 0 ]; then
    success_msg "MC (Midnight Commander) és Python3: Online. (Mellékes eszközök)"
else
    echo -e "\n${RED}[!! FATAL_ERROR !!]${NC} MC/Python3 Telepítés Sikertelen."
fi

# 5. Mosquitto (MQTT Broker) Telepítése
status_msg "Establishing Secure Channel: Mosquitto Telepítése..."
apt install mosquitto -y > /dev/null 2>&1
if [ $? -eq 0 ]; then
    success_msg "Mosquitto: Online. (MQTT Broker Fut)"
    systemctl enable mosquitto > /dev/null 2>&1
    systemctl start mosquitto > /dev/null 2>&1
else
    echo -e "\n${RED}[!! FATAL_ERROR !!]${NC} Mosquitto Telepítés Sikertelen."
fi

# 6. Node-RED (npm-en keresztül) Telepítése
status_msg "Initializing Flow Engine: Node.js és Node-RED Telepítése..."

# Node.js/npm telepítése (Node-RED függősége)
# A Debian repóban lehet, hogy régi, ezért a hivatalos módszert alkalmazzuk
curl -sL https://deb.nodesource.com/setup_lts.x | bash - > /dev/null 2>&1
apt install -y nodejs > /dev/null 2>&1

# Node-RED telepítése npm-el
npm install -g --unsafe-perm node-red > /dev/null 2>&1

if [ $? -eq 0 ]; then
    success_msg "Node-RED: Online. (Futtatás: 'node-red' paranccsal)"
    echo -e "${PURPLE}[... INFO_LOG ... ]${NC} Node-RED futtatás: ${GREEN}node-red${NC}"
else
    echo -e "\n${RED}[!! FATAL_ERROR !!]${NC} Node-RED Telepítés Sikertelen. Ellenőrizd a Node.js-t."
fi


# --- Befejezés ---

echo -e "\n${GREEN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║         ** DEPLOYMENT COMPLETE - STACK READY ** ║"
echo "  ║  Access Points:                                   ║"
echo "  ║  - Web:         http://localhost/                 ║"
echo "  ║  - phpMyAdmin:  http://localhost/phpmyadmin       ║"
echo "  ║  - MQTT:        localhost:1883                    ║"
echo "  ║  - Node-RED:    Futtasd a 'node-red' parancsot!   ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ">> Javaslat: Futtasd a 'mysql_secure_installation' parancsot a MariaDB biztonságossá tételéhez!"

# --- Script vége ---
