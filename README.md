# Android Debug Bridge (ADB) High-Interaction Honeypot

This project implements a High-Intercation ADB Honeypot that can also be extended to other protocols. The project is meant to be deployed inside an Ubuntu Virtual Machine and is based on Docker containers. The honeypot is composed of an NGINX service that acts as a reverse proxy and load balancer, a Suricata IPS/IDS service, and several Google Android Emulator containers based on [official Google Images](https://github.com/google/android-emulator-container-scripts). The honeypot is designed to be easily extensible to support multiple protocols and honeypot instances.

## Prerequisites
- VM running any Linux distribution (developed on Ubuntu 22.04)
- Docker and Docker compose
- Suricata
- NGINX server
- At least 16GB of free disk (persistent) memory

## Install and run

- Most of the technologies needed can be installed using the `setup.sh` script
- Run the script twice if you have not docker installed in order to refresh the `docker` group permissions before starting the deployment
- At the moment, suricata uses 3 log files, with `/var/log/suricata/eve.json` being the most important one. If you want to change configurations please change the proper files in the `suricata-config` directory and run `del_suri.sh` and the setup script again. 

## Protocol extensibility

Our deployment framework supports multiple protocols and honeypot instances as long as they are wrapped in a docker image. The steps to add another honeypot are as follows:

1. Create an emulator yaml file, like the following and save it to a file, i.e. `emulator.yml`

```yaml
adb-honeypot:
    image: us-docker.pkg.dev/android-emulator-268719/images/30-google-x64:30.1.2
    container_name: android-container-1
    ports:
      - 5555:5555
    environment:
      - ADBKEY=$(cat ~/.android/adbkey)
    devices:
      - "/dev/kvm"
```

2. Run the set-up-configs.py script, i.e. `python3 ./scripts/setup-compose.py ./template/emulator.yml `

3. You are ready to go. Make any necessary changes to the nginx and compose files.

## File Structure Overview

- `compose.yml` - main docker-compose file that defines the services (with static IPs) and networks.
- `setup.sh` - setup script that installs the necessary dependencies and starts the deployment. Here, we install Docker and add the user to the docker group, install Suricata with the appropriate configuration and rules, setup iptables for Suricata to work in IPS mode, and start all services and Suricata.
- `del_suri.sh` - The script that deletes Suricata and its configuration files.
- `nginx.conf` - The NGINX configuration file that defines the reverse proxy and how it should forward traffic to the emulators.
- `suricata.service` - The systemd service file for Suricata which ensures that Suricata is started on boot.
- `suricata-config` - The directory that contains the Suricata configuration including the rules that will be applied `rules/suricata.rules` and the configuration file `suricata.yaml`.
- `suricata.yaml` - The Suricata configuration file that defines that it should run in IPS mode as well as the type of logs used, where they are saved, internal network IP range, rules to be applied, etc.

## Acknowledgements
This project was done under the supervision of [Harm Griffioen](https://www.tudelft.nl/ewi/over-de-faculteit/afdelingen/intelligent-systems/cybersecurity/people/harm-griffioen) during Hacking Lab course (IN4253ET) @ TU Delft.
Collaborators of this project:
- [Dea Llazo](d.llazo@student.tudelft.nl)
- [Tsvetomir Hristov](t.hristov@student.tudelft.nl)
- [Velyan Kolev](v.p.kolev@student.tudelft.nl)
- [Vissarion Moutafis](v.moutafis@student.tudelft.nl)
