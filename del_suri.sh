#!/bin/bash

sudo apt remove suricata --purge -y

sudo rm -r /etc/suricata
sudo rm -r /var/log/suricata
sudo rm -r /etc/suricata

sudo systemctl stop suricata.service
sudo systemctl disable suricata.service

sudo rm /etc/systemd/system/suricata.service