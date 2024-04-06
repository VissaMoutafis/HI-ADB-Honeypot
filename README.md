# Overview
This project implements a honeypot deployment system along with a high-interaction ADB honeypot. The technology stack is 
- Docker
- NGINX server, as reverse proxy and load balancer
- Suricata as an IPS/IDS service
- google's android emulator [image](https://github.com/google/android-emulator-container-scripts)

This honeypot is supposed to be run inside an Ubuntu system.

# Install and run
- Most of the technologies needed can be installed using the `setup.sh` script
- Run the script twice if you have not docker installed in order to refresh the `docker` group permissions before start the deployment
- At the moment, suricata uses 3 log files, with `/var/log/suricata/eve.json` being the one the most important one. If you want to change configurations please change the proper files in the `suricata-config` directory and run 'del_suri.sh` and the setup script again. 

# Protocol extensibility
Our deployment framework supports multiple protocols and honeypot instances as long as they are wrapped in a docker image. The steps to add another honeypot would be
1. Configure the new service on `compose.yml` by adding the example as follows
```yaml
emulator-1:
    image: <image>
    container_name: <container name IMPORTANT>
    hostname: <container hostname IMPORTANT>
    networks:
      # this is the internal net
      - br-internal
    depends_on:
      - nginx
```
2. Add the container in the restarter's container list to restart
```yaml
restarter:
    image: docker:cli
    ...
    command:
      - |
        while true; do
          sleep 1800
          docker restart android-container-1 android-container-2 <container name>
        done
```
3. Make sure to expose the necessary ports on the nginx configuration in `compose.yml` and also add the reverse proxy configuration for your honeypot container service in `nginx.conf`
```yaml
    upstream new_emulator {
        hash $binary_remote_addr consistent;

        server <container hostname>:<PORT>;
    }
    server {
        listen <PORT>;
        proxy_pass new_emulator;
    }
```

# Acknowledgements
This project was done under the supervision of [Harm Griffioen](https://www.tudelft.nl/ewi/over-de-faculteit/afdelingen/intelligent-systems/cybersecurity/people/harm-griffioen) during Hacking Lab course (IN4253ET) @ TU Delft.
Collaborators of this project:
- [Dea Llazo](d.llazo@student.tudelft.nl)
- [Tsvetomir Hristov](t.hristov@student.tudelft.nl)
- [Velyan Kolev](v.p.kolev@student.tudelft.nl)
- [Vissarion Moutafis](v.moutafis@student.tudelft.nl)
