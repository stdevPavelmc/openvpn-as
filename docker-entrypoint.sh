#!/bin/bash
set -e

### timezone config: UTC
ln -fs "/usr/share/zoneinfo/Etc/UTC" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata || exit
apt-get install tree

### Common folders and check
mkdir -p /openvpn/{tmp,sock,pid} /dev/net /config/log /config/etc/tmp
if [ ! -f /usr/bin/systemctl ] ; then
    ln -s /usr/bin/true /usr/bin/systemctl
fi
if [ -f /config/twistd.pid ] ; then 
    rm /config/twistd.pid 
fi

# redirect /config to the install path
rm -rdf /usr/local/openvpn_as || exit
ln -s /config /usr/local/openvpn_as

### Initial config
if [ ! -f /config/configured ]; then
    # initial config follows

    # create tun device
    if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
    fi

    echo "installing openvpn-as for the first time"
	apt-get update && apt-get install -y openvpn-as

    # change dirs
    sed -i \
        -e 's#~/tmp#/openvpn/tmp#g' \
        -e 's#~/sock#/openvpn/sock#g' \
        /config/etc/as_templ.conf

    # if all gone ok, touch the configured flag
    touch /config/configured
else
    # old config found, backup
    echo "existing data found, backing up before restart"
    mkdir -p /config/backup
    cd /config/etc/db || exit
    DBFILESBAK="*.db"
    for f in $DBFILESBAK ; do
        echo "backing up $f"
        sqlite3 "$f" .dump > /config/backup/"$f"
    done
    echo "backing up as.conf"
    cp /config/etc/as.conf /config/backup/as.conf
    cd /config || exit

    # Install
    apt-get update && apt-get reinstall -y openvpn-as

    # change dirs
    sed -i \
        -e 's#~/tmp#/openvpn/tmp#g' \
        -e 's#~/sock#/openvpn/sock#g' \
        /config/etc/as_templ.conf
    
    # restore backups
    cd /config/backup || exit
    DBFILERES="*.db"
    for f in $DBFILERES
    do
        echo "restoring $f"
        rm -f /config/etc/db/"$f"
        sqlite3 </config/backup/"$f" /config/etc/db/"$f"
    done
    rm -f /config/etc/as.conf
    echo "restoring as.conf"
    cp /config/backup/as.conf /config/etc/as.conf

    # remove the backup folder
    rm -rf /config/backup
fi

### Startup secuence
cd /config

# check if the ADMIN & PASSWD was passed
if [ -z "${ADMIN}" ] ; then
    ADMIN="openvpnadmin"
fi
if [ -z "${PASSWD}" ] ; then
    PASSWD=''
fi

NOASCONFIG='DELETE\n'
ASCONFIG='yes\nyes\n1\nrsa\n4096\nrsa\n4096\n943\n9443\nyes\nyes\nno\nnon\'${ADMIN}'\n'${PASSWD}'\n\n'

if [ ! -f "/config/etc/as.conf" ]; then
CONFINPUT=$ASCONFIG
else
CONFINPUT=$NOASCONFIG$ASCONFIG
fi

if [ $(find /config/etc/db -type f | wc -l) -eq 0 -o ! -f "/config/etc/as.conf" ] ; then
    printf "${CONFINPUT}" | /config/bin/ovpn-init > /config/init.log
fi

#chown -R openvpn_as:openvpn_as /config

if [ -z "$INTERFACE" ]; then
SET_INTERFACE="eth0"
else
SET_INTERFACE=$INTERFACE
fi

/config/scripts/confdba -mk "admin_ui.https.ip_address" -v "$SET_INTERFACE"
/config/scripts/confdba -mk "cs.https.ip_address" -v "$SET_INTERFACE"
/config/scripts/confdba -mk "vpn.daemon.0.listen.ip_address" -v "$SET_INTERFACE"
/config/scripts/confdba -mk "vpn.daemon.0.server.ip_address" -v "$SET_INTERFACE"

/config/scripts/openvpnas -n -l - -p /openvpn/pid/openvpn.pid &

# run CMD parameters
if [ "${1}" != "openvpn" ] ; then
    "$@" &
fi

# recognize PIDs
pidlist=$(jobs -p)

# initialize latest result var
latest_exit=0

# define shutdown helper
function shutdown {
    trap "" SIGINT

    for single in $pidlist; do
        if ! kill -0 "$single" 2> /dev/null; then
            wait "$single"
            latest_exit=$?
        fi
    done

    kill "$pidlist" 2> /dev/null
    /bin/bash /config/scripts/openvpn_service_cleanup
}

# run shutdown
trap shutdown SIGINT
wait -n

# return received result
exit $latest_exit