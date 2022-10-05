# Docker OpenVPN Access Server (openvpn-as)

An updated version of the now **DEPRECATED** [linuxserver/openvpn-as](https://github.com/linuxserver/docker-openvpn-as) docker image to be run on actual hardware, precisely on Ubuntu 22.04 LTS

[![GitHub Stars](https://img.shields.io/github/stars/stdevPavelms/openvpn-as.svg?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&logo=github)](https://github.com/stdevPavelmc/openvpn-as)
[![GitHub Release](https://img.shields.io/github/release/stdevPavelmc/openvpn-as.svg?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&logo=github)](https://github.com/stdevPavelmc/openvpn-as/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/pavelmc/openvpn-as.svg?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=pulls&logo=docker)](https://hub.docker.com/r/pavelmc/openvpn-as)
[![Docker Stars](https://img.shields.io/docker/stars/pavelmc/openvpn-as.svg?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=stars&logo=docker)](https://hub.docker.com/r/pavelmc/openvpn-as)

[Openvpn-as](https://openvpn.net/index.php/access-server/overview.html) is a full featured secure network tunneling VPN software solution that integrates OpenVPN server capabilities, enterprise management capabilities, simplified OpenVPN Connect UI, and OpenVPN Client software packages that accommodate Windows, MAC, Linux, Android, and iOS environments. OpenVPN Access Server supports a wide range of configurations, including secure and granular remote access to internal network and/ or private cloud network resources and applications with fine-grained access control.

[![openvpn-as](https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/openvpn-as-banner.png)](https://openvpn.net/index.php/access-server/overview.html)

## Supported Architectures

Only amd64 image versions for now. 

## Version Tags

This image provides various versions that are available via tags. `latest` tag usually provides the latest stable version. Others are considered under development and caution must be exercised when using them.

## Application Setup

The admin interface is available at `https://DOCKER-HOST-IP:943/admin` (assuming bridge mode) with a default user/password of admin/password unless you passed the `ADMIN` & `PASSWD` env vars are set in which case that will be used, see the [docker-compose.yml](docker-compose.yml) file for reference.

During first login, make sure that the "Authentication" in the webui is set to "Local" instead of "PAM". Then set up the user accounts with their passwords (user accounts created under PAM do not survive container update or recreation).

The "admin" account is a system (PAM) account and after container update or recreation, its password reverts back to the default. It is highly recommended to block this user's access for security reasons:
1) Create another user and set as an admin,
2) Log in as the new user,
3) Delete the "admin" user in the gui,
4) Modify the `as.conf` file under config/etc and replace the line `boot_pam_users.0=admin` with ~~`#boot_pam_users.0=admin`~~ `boot_pam_users.0=kjhvkhv` (this only has to be done once and will survive container recreation)  
* IMPORTANT NOTE: Commenting out the first pam user in as.conf creates issues in 2.7.5. To make it work while still blocking pam user access, uncomment that line and change admin to a random nonexistent user as described above.

To ensure your devices can connect to your VPN properly, goto Configuration -> Network Settings -> and change the "Hostname or IP Address" section to either your domain name or public ip address.

## Usage

### docker-compose ([recommended](https://docs.linuxserver.io/general/docker-compose))

Compatible with docker-compose v3 schemas, see the example deployment file [docker-compose.yml](docker-compose.yml)

## Environment variables

for now just this variables are used from the env:

- ADMIN: admin user of the WebUI
- PASSWD: for the admin user in the WebUI
- INTERFACE: the internal interface to use [optional, defaults to eth0]

## Docker support Info

* Shell access whilst the container is running: `docker exec -it openvpn-as /bin/bash`
* To monitor the logs of the container in realtime: `docker logs -f openvpn-as`

## Updating Info

This image is static in nature and upgrades will be supported by just replacing the image.

### Via Docker Compose

* Update all images: `docker-compose pull`
  * or update a single image: `docker-compose pull openvpn-as`
* Let compose update all containers as necessary: `docker-compose up -d`
  * or update a single container: `docker-compose up -d openvpn-as`
* You can also remove the old dangling images: `docker image prune`

### Via Docker Run

* Update the image: `docker pull stdevPavelmc/openvpn-as`
* Stop the running container: `docker stop openvpn-as`
* Delete the container: `docker rm openvpn-as`
* Recreate a new container with the same docker run parameters as instructed above (if mapped correctly to a host folder, your `/config` folder and settings will be preserved)
* You can also remove the old dangling images: `docker image prune`
