#!/bin/bash

# populate /var/lib/mysql if empty
chown -R mysql: /var/lib/mysql
[ -z "$(ls -A /var/lib/mysql)" ] && cp -a /var/lib/mysql-dist/* /var/lib/mysql/
rm -Rf /var/lib/mysql-dist

# populate /usr/local/omk/conf if empty
[ -z "$(ls -A /usr/local/omk/conf)" ] && cp -a /usr/local/omk/conf-dist/* /usr/local/omk/conf/
rm -Rf /usr/local/omk/conf-dist

service mysql start
service omkd start
service apache2 start

tail -f /var/log/apache2/*.log /usr/local/omk/log/*.log
