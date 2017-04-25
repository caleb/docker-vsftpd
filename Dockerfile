FROM debian:stretch

MAINTAINER Caleb Land <caleb@land.fm>

ENV DOCKER_HELPERS_VERSION=2.0

# Download our docker helpers
ADD https://github.com/caleb/docker-helpers/releases/download/v${DOCKER_HELPERS_VERSION}/helpers-v${DOCKER_HELPERS_VERSION}.tar.gz /tmp/helpers.tar.gz

# Install the docker helpers
RUN mkdir -p /helpers \
&&  tar xzf /tmp/helpers.tar.gz -C / \
&&  rm /tmp/helpers.tar.gz

# Install the base system
RUN /bin/bash /helpers/install-base.sh

RUN apt-get update \
&&  apt-get install -y vsftpd \
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
