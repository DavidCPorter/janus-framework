#
#  Author: david porter
#  Date: Mon Feb  3 15:30:24 CST 2020
#
#  vim:ts=4
#
#  https://github.com/harisekhon/Dockerfiles
#

FROM ubuntu:latest

LABEL Description="local ubuntu server for Sapa local experiments"


RUN bash -c ' \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
                       curl \
                       dnsutils \
                       dstat \
                       ethtool \
                       git \
                       golang \
                       lsof \
                       make \
                       maven \
                       netcat \
                       nmap \
                       net-tools \
                       openssh-server \
                       procps \
                       python-dev \
                       python-pip \
                       python-setuptools \
                       ruby \
                       ruby-dev \
                       socat \
                       scala \
					   strace \
                       sysstat \
                       systemd \
					   sudo \
                       tcpdump \
                       unzip \
                       vim \
                       wget \
                       zip && \
    apt-get update && \
    apt-get clean && \
	useradd -m -p $(openssl passwd -1 "password") -s /bin/bash -G sudo sapauser'

EXPOSE 22

CMD service ssh start; sleep 99999

