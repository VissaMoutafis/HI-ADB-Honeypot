#!/bin/bash

setup_docker() {
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    echo "Adding user to docker group..."
    # check if docker group exists
    if [ $(getent group docker) ]; then
        echo "docker group exists."
    else
        echo "docker group does not exist... creating docker group."
        sudo groupadd docker
    fi

    sudo usermod -aG docker $USER
    newgrp docker
}

setup_suricata() {
    echo "Installing Suricata IDS..."
    echo | sudo add-apt-repository ppa:oisf/suricata-stable
    sudo apt install suricata jq -y

    # copy your configurations in /etc/suricata/suricata.yaml
    echo "Copying configurations to /etc/suricata/suricata.yaml..."
    sudo cp ./suricata-config/suricata.yaml /etc/suricata/suricata.yaml

    # copy your rules in /etc/suricata/rules
    echo "Copying rules to /etc/suricata/rules..."
    sudo cp -r ./suricata-config/rules /etc/suricata/

    # set up iptables for interface br-internal to forward in NFQUEUE
    echo "Setting up iptables for interface br-internal..."
    sudo iptables -I DOCKER-USER -i br-internal -j NFQUEUE --queue-num 0
    sudo iptables -I DOCKER-USER -o br-internal -j NFQUEUE --queue-num 0
    sudo iptables -I DOCKER-USER -i br-public -j NFQUEUE --queue-num 0
    sudo iptables -I DOCKER-USER -o br-public -j NFQUEUE --queue-num 0

    # copy the IDS service file into /etc/systemd/system
    echo "Setting up suricata service..."
    sudo cp suricata.service /etc/systemd/system/suricata.service

    # # reload the systemd daemon
    sudo systemctl daemon-reload

    echo "Starting/Enabling Suricata service..."
    # start the suricata engine and make sure it starts on boot
    sudo systemctl start suricata.service
    sudo systemctl enable suricata.service

    sudo systemctl restart suricata.service
}


start_docker() {
    # check if docker and docker-compose is installed
    if ! [ -x "$(command -v docker)" ]; then
        echo "Docker is not installed. Installing Docker..."
        setup_docker
    fi

    echo "Starting docker network and containers..."
    docker compose up -d --build
}


start_docker
setup_suricata

