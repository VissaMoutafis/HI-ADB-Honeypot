FROM ubuntu

RUN apt-get update
RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:oisf/suricata-stable -y
RUN apt-get update
RUN apt-get install suricata -y

CMD [ "sudo systemctl start suricata" ]

