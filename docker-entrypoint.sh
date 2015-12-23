#!/bin/bash
set -e
shopt -s globstar nullglob

. /helpers/links.sh

if [ -f /etc/vsftpd.conf.mo ]; then
    /usr/local/bin/mo /etc/vsftpd.conf.mo > /etc/vsftpd.conf
    rm /etc/vsftpd.conf.mo
fi

#
# Add users
#
if [ -n "${USER}" ]; then
    export USER__DEFAULT__="${USER}"
fi

for var in ${!USER_*}; do
    if [[ "${!var}" =~ ^([^:]+):(.*)$ ]]; then
        username="${BASH_REMATCH[1]}"
        password="${BASH_REMATCH[2]}"
        echo "Creating user \"${username}\" with password \"${password}\""
        if [ -d /home/"${username}" ]; then
            useradd "${username}"
            chown -R "${username}" /home/"${username}"
        else
            useradd -m "${username}"
        fi

        echo "${!var}" | chpasswd
    else
        echo "Misformed user variable ${var}=${!var}. Should be ${var}=username:password" >&2
        exit 1
    fi
done

# Make the secure chroot dir
mkdir -p /var/run/vsftpd/empty

if [ "${1}" = "vsftpd" ]; then
    exec /usr/sbin/vsftpd
else
    exec "${@}"
fi
