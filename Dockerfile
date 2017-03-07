FROM ubuntu:trusty

# install all packages
RUN echo 'mysql-server mysql-server/root_password password thisIsNotSecure' | debconf-set-selections && \
    echo 'mysql-server mysql-server/root_password_again password thisIsNotSecure' | debconf-set-selections && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
                     apache2 \
                     apache2-utils \
                     ca-certificates \
                     curl \
                     ipmitool \
                     libapache2-mod-php5 \
                     libapache2-mod-proxy-html \
                     libtime-modules-perl \
                     logrotate \
                     mysql-server \
                     nmap \
                     openssh-client \
                     php5 \
                     php5-cli \
                     php5-ldap \
                     php5-mcrypt \
                     php5-mysql \
                     php5-snmp \
                     screen \
                     smbclient \
                     sshpass \
                     wget \
                     zip \
                     && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl "$(curl "https://opmantek.com/network-tools-download/?action=download&dl_id=1051&dl_field=linux-64-bit&dl_tool=Open-AudIT&dl-action=Download&dl_name=Dusty%20Wilson&dl_email=dusty.wilson@scjalliance.com" | grep 'http-equiv="refresh"' | grep '.run"' | grep -o 'href="https*:.*\.run"' | cut -d'"' -f2)" > /tmp/openaudit.run && \
    chmod 755 /tmp/openaudit.run && \
    /tmp/openaudit.run --check && \
    /tmp/openaudit.run --noexec --keep && \
    rm /tmp/openaudit.run

VOLUME /data/mysql
CMD chown -Rf mysql: /data/mysql
EXPOSE 80

ENV OPT_MROOTPWD 'thisIsNotSecure'
RUN service mysql start && \
    cd /tmp/Open-AudIT* && \
    ./installer ; \
    service mysql stop

RUN mv /var/lib/mysql /var/lib/mysql-dist && \
    mv /usr/local/omk/conf /usr/local/omk/conf-dist

RUN chmod g+s $(which nmap)

WORKDIR /usr/local/omk
COPY run.sh run.sh
RUN chmod 755 run.sh

CMD ["./run.sh"]
