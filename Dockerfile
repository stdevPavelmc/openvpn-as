FROM ubuntu:jammy

LABEL maintainer="Pavel Milanes <pavelmc@gmail.com>"

# environment settings
ENV DEBIAN_FRONTEND="noninteractive"

# Only on dev
#RUN rm /etc/apt/apt.conf.d/docker-clean

# Pre-requisites
RUN apt-get update && \
    apt-get -y install \
        ca-certificates \
        wget \
        net-tools \
        gnupg \
        tzdata \
        sqlite3

# App repository install (App will be installed on the container, not on the image)
RUN wget -qO - https://as-repository.openvpn.net/as-repo-public.gpg > \
        /etc/apt/trusted.gpg.d/openvpn-as.asc && \
    echo "deb http://as-repository.openvpn.net/as/debian jammy main" > \
        /etc/apt/sources.list.d/openvpn-as-repo.list

RUN mkdir /config
WORKDIR /config
VOLUME /config

EXPOSE 943/tcp 1194/udp 9443/tcp

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["openvpn"]

# Only on dev
#VOLUME /var/cache/apt/
#VOLUME /var/lib/apt/
