#!/bin/bash

# start nginx service 
nginx -g daemon off &

# start suricata
/usr/bin/suricata -c /etc/suricata/suricata.yaml -i eth0 &