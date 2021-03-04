# RaspberryPi-HomeServer

**Note**: This project is currently work in progress. Things might change, so check for updates! If you have suggestions for improvements or solutions for [known problems](#known-problems), I would love to hear them. Let me know!

This documentation explains how to setup your Raspberry Pi with Docker and run [Traefik](https://traefik.io/traefik/), [PiHole](https://pi-hole.net), [Portainer](https://www.portainer.io),  [Nextcloud](https://nextcloud.com) and [Bitwarden](https://bitwarden.com) within your local network using local (sub)domains and TLS encryption (HTTPS). To access the services from outside the local network a private network connection (VPN) can be used. 

![Hardware Image](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/hardware_image.png?raw=true)

## Table of contents

- [RaspberryPi-HomeServer](#raspberrypi-homeserver)
  * [Table of contents](#table-of-contents)
  * [Prerequisites](#prerequisites)
- [Prepare the setup process](#prepare-the-setup-process)
- [Install host software](#install-host-software)
  * [Install Docker](#install-docker)
  * [Install Git](#install-git)
- [Install Docker services](#install-docker-services)
  * [Install Traefik](#install-traefik)
  * [Install PiHole](#install-pihole)
  * [Install Portainer](#install-portainer)
  * [Install Nextcloud](#install-nextcloud)
  * [Install Bitwarden](#install-bitwarden)
  * [Install RaspberryMatic](#install-raspberrymatic)
- [Finish the setup process](#finish-the-setup-process)
  * [Recommended (personal) configurations](#recommended--personal--configurations)
    + [PiHole](#pihole)
    + [Portainer](#portainer)
  * [Nice to know](#nice-to-know)
- [Backup the system](#backup-the-system)
  * [System backup](#system-backup)
  * [Data backup](#data-backup)
- [Update the system](#update-the-system)
- [Known problems](#known-problems)

## Prerequisites

- A [Raspberry Pi 3 Model B](https://www.raspberrypi.org/products/raspberry-pi-3-model-b/) or [Raspberry Pi 4 Model B](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/) with an original/sufficient power supply. (Other models might work as well but weren't tested.)
- A microSD card and optionally any USB device to flash the firmware on. (The best performance will be reached with an SSD connected to an USB 3 port of a Raspberry Pi 4 Model B - the SSD to USB adapter should be able to support UASP.) 
- This tutorial assumes using the "Raspberry Pi OS Lite" image. (Other images most likely work with small modifications as well but weren't tested.)
- A LAN connection. (Wi-Fi will work as well but is not recommended due to it's performance and reliability in contrast to a physical connection.) 
- No monitor or other external I/O devices are needed - the setup will be complete headless. (Of course you need a second computer for preparation.) 

# Prepare the setup process

- Flash an image to your microSD card. 
    >https://www.raspberrypi.org/software/  
    >![Flash Image](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/flash_image_1.png?raw=true)

- Enable SSH on your Raspberry Pi. Reconnect the flashed microSD card and place a file called "ssh" without extension and content at the root directory of the card. 
    >https://www.raspberrypi.org/documentation/remote-access/ssh/  
    >![Enable SSH](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/flash_image_2.png?raw=true)

- Establish a LAN connection and plug in the power supply to boot your system. 
    >**Note**: default login credentials are - username "pi", password "raspberry".

- Get the IP address of your Raspberry Pi from your router.
    >![Raspberry Pi IP](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_ip_1.png?raw=true)  
    
- Set IP address to be static or define a custom static address.
    >![Raspberry Pi IP](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_ip_2.png?raw=true)

- Restart your router to apply the settings.    
    >![Raspberry Pi IP](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_settings_3.png?raw=true)
    
- Establish a SSH connection.  
    >https://www.raspberrypi.org/documentation/remote-access/ssh/  
    >![Connect SSH](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/connect_ssh.png?raw=true)
    
- **Optional**, but recommended to avoid boot up alters in the future: 
    - Change the default password.
        >passwd
        
    - Set the Wi-Fi country.
        >sudo raspi-config (Localisation Options > WLAN Country)

- Update the system.
    >sudo apt update && sudo apt upgrade -y  
    >sudo apt full-upgrade

- Expand the filesystem.
    >sudo raspi-config (Advanced Options > Expand Filesystem)

- Restart the system.
    >sudo reboot

- **Optional**: If you would like to boot your system from an USB device.
    - Define the preferred system boot order.
        >sudo rpi-eeprom-update  
        >sudo raspi-config (Advanced Options > Boot Order)
    
    - Shutdown the system.
        >sudo shutdown -h 0
    
    - Unplugg the microSD card and repeat all previous steps with your USB device. 

# Install host software

Install the necessary software packages on your system to setup your home server. 

## Install Docker

- Download and install Docker.
    >sudo curl -fsSL https://get.docker.com | sh

- Install Docker-Compose.
    >sudo apt install -y python3-pip  
    >sudo pip3 install docker-compose

- **Optional**: Check the Docker installation.
    >sudo docker run hello-world

- **Optional**: Restart the system.
    >sudo reboot

## Install Git

- Download and install Git.
    >sudo apt install -y git

- Create a Docker-Compose directory.
    >mkdir /home/pi/homeserver

- Download the preconfigured Docker-Compose files.
    >git clone https://github.com/Chr1k0/RaspberryPi-HomeServer.git /home/pi/homeserver

# Install Docker services

Install and  launch the docker services on your system to setup your home server. 

## Install Traefik

- Create a custom docker network.
    >sudo docker network create local 

- Create a custom docker volume for persistence data storage.
    >sudo docker volume create traefik     
    >sudo mkdir /var/lib/docker/volumes/traefik/_data/certs  
    >sudo mkdir /var/lib/docker/volumes/traefik/_data/config

- Create a self-signed SSL certificate for your network services to use TLS encryption (HTTPS). 
    >sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout raspberrypi.local.key -out raspberrypi.local.crt

    >**Note**: You don't have (but are free) to specify any custom entries, except the second last "Common Name". Here you configure the local domain under which you like your services to be accessible later. For example: *.raspberrypi.local  
    >![SSL Certificate](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/ssl_certificate.png?raw=true)

- Move the created certificate files to the Traefik docker volume.   
    >sudo mv raspberrypi.local.key /var/lib/docker/volumes/traefik/_data/certs/raspberrypi.local.key  
    >sudo mv raspberrypi.local.crt /var/lib/docker/volumes/traefik/_data/certs/raspberrypi.local.crt

- Create a dynamic configuration file for Traefik at the corresponding docker volume defining the location of the certificate files within the docker container. 
    >echo 'cat > /var/lib/docker/volumes/traefik/_data/config/dynamic_config.yml <\<END  
    >tls:  
    >&nbsp;&nbsp;certificates:  
    >&nbsp;&nbsp;&nbsp;&nbsp;- certFile: /etc/traefik/certs/raspberrypi.local.crt  
    >&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;keyFile: /etc/traefik/certs/raspberrypi.local.key  
    >END' | sudo -s

- Start Traefik.
    >sudo docker-compose -p traefik -f /home/pi/homeserver/docker/docker-compose.traefik.yml up -d 

## Install PiHole

- Create a custom docker volume for persistence data storage.
    >sudo docker volume create pihole  
    >sudo mkdir /var/lib/docker/volumes/pihole/_data/etc-pihole  
    >sudo mkdir /var/lib/docker/volumes/pihole/_data/etc-dnsmasq.d  

- Define PiHole DNS entries for your local network at the corresponding docker volume.
    >echo 'cat > /var/lib/docker/volumes/pihole/_data/etc-pihole/custom.list <\<END  
    >192.168.178.1 fritz.box  
    >192.168.178.2 traefik.raspberrypi.local  
    >192.168.178.2 pihole.raspberrypi.local  
    >192.168.178.2 portainer.raspberrypi.local  
    >192.168.178.2 nextcloud.raspberrypi.local  
    >192.168.178.2 bitwarden.raspberrypi.local  
    >END' | sudo -s  
    
    >**Note**: Adjust the IP addresses (and domains) matching your configuration (chapters [Prepare the setup process](#prepare-the-setup-process) and [Install Traefik](#install-traefik)).

- Start PiHole.
    >sudo docker-compose -p pihole -f /home/pi/homeserver/docker/docker-compose.pihole.yml up -d


- Set an admin password for PiHole.
    >sudo docker exec -it pihole pihole -a -p

## Install Portainer

- Create a custom docker volume for persistence data storage.
    >sudo docker volume create portainer

- Start Portainer.
    >sudo docker-compose -p portainer -f /home/pi/homeserver/docker/docker-compose.portainer.yml up -d

## Install Nextcloud

- Create a custom docker volume for persistence data storage.
    >sudo docker volume create nextcloud

- Start Nextcloud.
    >sudo docker-compose -p nextcloud -f /home/pi/homeserver/docker/docker-compose.nextcloud.yml up -d

## Install Bitwarden

- Create a custom docker volume for persistence data storage.
    >sudo docker volume create bitwarden  
    >sudo mkdir /var/lib/docker/volumes/bitwarden/_data/data  
    >sudo mkdir /var/lib/docker/volumes/bitwarden/_data/config  

- Start Bitwarden
    >sudo docker-compose -p bitwarden -f /home/pi/homeserver/docker/docker-compose.bitwarden.yml up -d

## Install RaspberryMatic

... Comming sooner or later ... 

- https://github.com/jens-maus/RaspberryMatic
- https://github.com/jens-maus/RaspberryMatic/wiki/Einleitung
- https://github.com/jens-maus/RaspberryMatic/wiki/Installation
- https://github.com/jens-maus/RaspberryMatic/wiki/Installation-Docker-OCI
- https://www.thingiverse.com/thing:4558687

# Finish the setup process

To complete the setup process you now need to configure your router to make the services accessible.

- Update the DNS server. Set the DNS server IP address to the one of your Raspberry Pi (chapter [Prepare the setup process](#prepare-the-setup-process)).
    >![Router DNS Setting](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_settings_1.png?raw=true)

- Disable the DNS Rebind Protection (maybe not necessary depending on the router) for the domains specified (chapter [Install PiHole](#install-pihole)).
    >![Router DNS Setting](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_settings_2.png?raw=true)

- Restart your router to apply the settings.
    >![Router DNS Setting](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_settings_3.png?raw=true)
    
- All services should now be reachable. You can start to use and configure them.
    >https://traefik.raspberrypi.local  
    >https://pihole.raspberrypi.local  
    >https://portainer.raspberrypi.local  
    >https://nextcloud.raspberrypi.local  
    >https://bitwarden.raspberrypi.local  

## Recommended (personal) configurations

### PiHole

- Change the default DNS (Google) to Cloudflare for more privacy (https://1.1.1.1/).   
    >Settings > DNS

### Portainer

- Disable the collection of anonymous statistics. 
    >Settings > Application settings > Allow the collection of anonymous statistics

## Nice to know

If you want to temporarily disable your PiHole DNS filter you can do this (beside within the web dashboard) also with a browser bookmark shortcut.

- Get the PiHole password hash.
    >sudo nano /var/lib/docker/volumes/pihole/_data/etc-pihole/setupVars.conf  
    >WEBPASSWORD=...
    
- Create a browser bookmark or just browse the following URL. Replace `WEBPASSWORD_HASH` with your hash value.
    >https://pihole.raspberrypi.local/api.php?disable=300&auth=WEBPASSWORD_HASH
    
- **Optional**, but recommended: Flash your computers DNS cache.
    >sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

If you like to test the performance of your microSD card or USB device running the operating system you could use agnostics to do so (https://www.raspberrypi.org/blog/sd-card-speed-test/).

- Install Agnostics.
    >sudo apt install -y agnostics   
- Start Agnostics.
    >sh /usr/share/agnostics/sdtest.sh





# Backup the system

## System backup

## Data backup





# Update the system

- Update the DNS server. Temporarily set a different (valid) DNS server IP address than the one of your Raspberry Pi.
    >![Router DNS Setting](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_settings_4.png?raw=true)

- Restart your router to apply the settings.
    >![Router DNS Setting](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_settings_3.png?raw=true)

- Update the system.
    >sudo apt update && sudo apt upgrade -y   
    >sudo apt full-upgrade

- Update Docker-Compose.
    >sudo pip3 install docker-compose --upgrade

- Update the the preconfigured Docker-Compose files.
    >git -C /home/pi/homeserver pull

- Stop the running docker services.
    >sudo docker-compose -p bitwarden -f /home/pi/homeserver/docker/docker-compose.bitwarden.yml down   
    >sudo docker-compose -p nextcloud -f /home/pi/homeserver/docker/docker-compose.nextcloud.yml down   
    >sudo docker-compose -p portainer -f /home/pi/homeserver/docker/docker-compose.portainer.yml down   
    >sudo docker-compose -p pihole -f /home/pi/homeserver/docker/docker-compose.pihole.yml down   
    >sudo docker-compose -p traefik -f /home/pi/homeserver/docker/docker-compose.traefik.yml down   

- Remove the old docker images. 
    >sudo docker image rm bitwardenrs/server   
    >sudo docker image rm nextcloud  
    >sudo docker image rm portainer/portainer-ce  
    >sudo docker image rm pihole/pihole    
    >sudo docker image rm traefik 

- Restart the docker services with the latest docker container versions
    >sudo docker-compose -p traefik -f /home/pi/homeserver/docker/docker-compose.traefik.yml up -d   
    >sudo docker-compose -p pihole -f /home/pi/homeserver/docker/docker-compose.pihole.yml up -d  
    >sudo docker-compose -p portainer -f /home/pi/homeserver/docker/docker-compose.portainer.yml up -d  
    >sudo docker-compose -p nextcloud -f /home/pi/homeserver/docker/docker-compose.nextcloud.yml up -d  
    >sudo docker-compose -p bitwarden -f /home/pi/homeserver/docker/docker-compose.bitwarden.yml up -d  

- Update the DNS server. Set the DNS server IP address back to the one of your Raspberry Pi (chapter [Prepare the setup process](#prepare-the-setup-process)).
    >![Router DNS Setting](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_settings_1.png?raw=true)

- Restart your router to apply the settings.
    >![Router DNS Setting](https://github.com/Chr1k0/RaspberryPi-HomeServer/blob/main/documentation/images/router_settings_3.png?raw=true)

# Known problems
