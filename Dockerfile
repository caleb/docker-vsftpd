FROM debian:stretch

MAINTAINER Caleb Land <caleb@land.fm>

RUN apt-get update \
&&  apt-get install -y vsftpd runit \
&&  rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/vsftpd.conf

# Add our entrypoint
ADD docker-entrypoint.sh /entrypoint.sh

# Add the rootfs
ADD rootfs /

EXPOSE 21 990
EXPOSE 10090-10100

ENTRYPOINT ["/entrypoint.sh"]
CMD ["vsftpd"]
