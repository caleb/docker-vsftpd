#!/bin/bash
set -e
shopt -s globstar nullglob

[[ -z "${VSFTPD_CHROOT_LOCAL_USER}" ]]      && export VSFTPD_CHROOT_LOCAL_USER=NO
[[ -z "${VSFTPD_CHROOT_LIST_ENABLE}" ]]     && export VSFTPD_CHROOT_LIST_ENABLE=NO
[[ -z "${VSFTPD_ALLOW_WRITABLE_CHROOT}" ]]  && export VSFTPD_ALLOW_WRITABLE_CHROOT=NO

[[ -z "${VSFTPD_PASV_PROMISCUOUS}" ]]       && export VSFTPD_PASV_PROMISCUOUS=YES
[[ -z "${VSFTPD_PASV_ADDR_RESOLVE}" ]]      && export VSFTPD_PASV_ADDR_RESOLVE=NO
[[ -z "${VSFTPD_SECCOMP_SANDBOX}" ]]        && export VSFTPD_SECCOMP_SANDBOX=YES
[[ -z "${VSFTPD_FORCE_LOCAL_DATA_SSL}" ]]   && export VSFTPD_FORCE_LOCAL_DATA_SSL=YES
[[ -z "${VSFTPD_FORCE_LOCAL_LOGINS_SSL}" ]] && export VSFTPD_FORCE_LOCAL_LOGINS_SSL=YES

[[ -z "${VSFTPD_IMPLICIT_SSL}" ]]           && export VSFTPD_IMPLICIT_SSL=NO
[[ -z "${VSFTPD_LISTEN_PORT}" ]]            && export VSFTPD_LISTEN_PORT=21


[[ -z "${VSFTPD_SSL_TLSV1}" ]]              && export VSFTPD_SSL_TLSV1=NO
[[ -z "${VSFTPD_SSL_SSLV2}" ]]              && export VSFTPD_SSL_SSLV2=YES
[[ -z "${VSFTPD_SSL_SSLV3}" ]]              && export VSFTPD_SSL_SSLV3=YES

if [ -d "${VSFTPD_LOCAL_ROOT}" ]; then
    chown -R :ftp "${VSFTPD_LOCAL_ROOT}"
    chmod -R g+w "${VSFTPD_LOCAL_ROOT}"
fi

if [[ -z "${VSFTPD_RSA_CERT_FILE}" ]] || [[ -z "${VSFTPD_RSA_PRIVATE_KEY_FILE}" ]]; then
  mkdir -p /etc/vsftpd/certs
  pushd /etc/vsftpd/certs

  cd /etc/vsftpd/certs
  openssl req -x509 -nodes -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -subj "/C=US/ST=New York/L=Rochester/O=Caleb Land/CN=ftp/emailAddress=caleb@land.fm"

  export VSFTPD_RSA_CERT_FILE=/etc/vsftpd/certs/cert.pem
  export VSFTPD_RSA_PRIVATE_KEY_FILE=/etc/vsftpd/certs/key.pem

  popd
fi

#
# Write the VSFTPD config file
#
if [ -f /etc/vsftpd.conf.mo ] && [ ! -f /etc/vsftpd.conf ]; then
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

        useradd_flags="--shell=/bin/bash"
        if [ ! -d /home/"${username}" ]; then
            useradd_flags="${useradd_flags} -m"
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
        echo "Malformed user variable ${var}=${!var}. Should be ${var}=username:password" >&2
        exit 1
    fi
done

# Make the secure chroot dir
mkdir -p /var/run/vsftpd/empty

if [ "${1}" = "vsftpd" ]; then
    exec /usr/bin/runsvdir /etc/service
else
    exec "${@}"
fi
