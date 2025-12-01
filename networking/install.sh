#!/bin/sh

sudo apt-get update -y

mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --yes --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list > /dev/null

sudo apt-get update -y

sudo apt-get install -y \
    iproute2 \
    build-essential \
    git \
    curl \
    wget \
    gpg \
    tar \
    libpcre3-dev \
    libssl-dev \
    libpcap-dev \
    net-tools \
    xsltproc \
    bind9-dnsutils \
    netcat-traditional \
    toilet \
    boxes \
    lolcat \
    automake \
    nmap \
    lolcat \
    toilet \
    boxes \
    masscan \
    gum \
    bind9-host \
    geoip-bin \
    hwinfo \
    autoconf \
    python3 \
    python3-pip \
    python3-venv

# Install Masscan
if ! command -v masscan >/dev/null 2>&1; then
    cd /tmp
    rm -rf masscan
    git clone https://github.com/robertdavidgraham/masscan.git
    cd masscan
    make -j"$(nproc)"
    cp bin/masscan /usr/local/bin/masscan
    chmod +x /usr/local/bin/masscan
fi

# Install Nmap
if ! command -v nmap >/dev/null 2>&1; then
    cd /tmp
    rm -rf nmap-7.95
    wget https://nmap.org/dist/nmap-7.95.tar.bz2
    tar xvjf nmap-7.95.tar.bz2
    cd nmap-7.95
    ./configure --without-zenmap --without-nping --without-ndiff --without-ncat
    make -j"$(nproc)"
    make install
fi

# Update locate database if available
if command -v updatedb >/dev/null 2>&1; then
    updatedb || true
fi

# Install Vulners NSE script
echo -e "${blue_color}[-] Installing Vulners NSE script...${end_color}"
if [[ $(which nmap) == */local/* ]]; then
    nmap_scripts_folder="/usr/local/share/nmap/scripts/"
else
    nmap_scripts_folder="/usr/share/nmap/scripts/"
fi

mkdir -p "${nmap_scripts_folder}"
wget -q https://raw.githubusercontent.com/vulnersCom/nmap-vulners/master/vulners.nse -O "${nmap_scripts_folder}vulners.nse" &>> "${log_file}"
nmap --script-updatedb