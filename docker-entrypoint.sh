#!/bin/bash
set -e
shopt -s globstar nullglob

. /helpers/links.sh
. /helpers/vars.sh

read-var VSFTPD_PASV_PROMISCUOUS  -- YES
read-var VSFTPD_PASV_ADDR_RESOLVE -- NO
read-var VSFTPD_SECCOMP_SANDBOX   -- YES

if [ -f /etc/vsftpd.conf.mo ]; then
    /usr/local/bin/mo /etc/vsftpd.conf.mo > /etc/vsftpd.conf
    rm /etc/vsftpd.conf.mo
fi

if [ -d "${VSFTPD_LOCAL_ROOT}" ]; then
    chown -R :ftp "${VSFTPD_LOCAL_ROOT}"
    chmod -R g+w "${VSFTPD_LOCAL_ROOT}"
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

        useradd_flags=""
        if [ ! -d /home/"${username}" ]; then
            useradd_flags="-m"
        fi

        if [ -d /home/"${username}" ]; then
            chown -R "${username}" /home/"${username}"
        fi

        if ! id "${username}" > /dev/null 2>&1; then
            useradd ${useradd_flags} "${username}"
        fi

        usermod -a -G ftp "${username}"

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
