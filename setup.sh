#!/bin/bash

setup_suricata() {
    config_yaml="$1"

    echo "Installing Suricata IDS..."
    echo | sudo add-apt-repository ppa:oisf/suricata-stable
    sudo apt install suricata jq -y

    # copy your configurations in /etc/suricata/suricata.yaml
    echo "Copying configurations to /etc/suricata/suricata.yaml..."
    sudo cp ./suricata-config/suricata.yaml /etc/suricata/suricata.yaml

    # copy your rules in /etc/suricata/rules
    echo "Copying rules to /etc/suricata/rules..."
    sudo cp -r ./suricata-config/rules /etc/suricata/

    # create suri:suri user and group
    echo "Creating suri:suri user and group..."
    sudo useradd -r -s /usr/sbin/nologin suri
    sudo groupadd suri
    sudo usermod -a -G suri suri

    sudo chown root:suri /var/log/suricata
    sudo chmod 750 /var/log/suricata

    # # copy the IDS service file into /etc/systemd/system
    echo "Setting up suricata service..."
    sudo cp suricata.service /etc/systemd/system/suricata.service

    # # reload the systemd daemon
    sudo systemctl daemon-reload

    # echo "Starting/Enabling Suricata service..."
    # # # start the suricata engine and make sure it starts on boot
    sudo systemctl start suricata.service
    sudo systemctl enable suricata.service

    # sudo /usr/bin/suricata -q 0 -c /etc/suricata/suricata.yaml --pidfile /var/run/suricata.pid -D
    # echo "Run 'sudo /usr/bin/suricata -q 0 -c /etc/suricata/suricata.yaml -D --pidfile /var/run/suricata.pid' in case you want to start suricata..." 
    # set up iptables for interface br-android to forward in NFQUEUE
    echo "Setting up iptables for interface br-android..."
    sudo iptables -I INPUT -i br-android -j NFQUEUE --queue-num 0
    sudo iptables -I OUTPUT -o br-android -j NFQUEUE --queue-num 0
}


start_docker() {
    echo "Starting docker network and containers..."
    docker compose up -d --build
}

start_docker
setup_suricata $1

