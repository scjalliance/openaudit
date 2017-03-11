#!/bin/bash

# ENVIRONMENT VARIABLES OPTIONALLY PROVIDED ON DOCKER RUN, along with example value:
#
# TIMEZONE=America/Los_Angeles
#        - Defaults to UTC if not defined or if not correctly formatted (case-sensitive!)
#        - Uses IANA time zone naming (see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
#
# BASEURL=http://oa.example.com
#        - If not provided, uses pre-existing value of http://localhost
#        - Certainly use https:// when available and appropriate.
#

# first run tasks
if [ ! -f /.first-run-done ]; then
	touch /.first-run-done

	# set timezone
	TIMEZONE=${TIMEZONE:-UTC}
	rm /etc/{timezone,localtime}
	[ ! -f "/usr/share/zoneinfo/$TIMEZONE" ] && TIMEZONE=UTC
	ln -s "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
	dpkg-reconfigure -f noninteractive tzdata
	ex -s +'g/^\s*date.timezone\s*=/d' -cwq /etc/php5/apache2/php.ini
	echo         "date.timezone = $TIMEZONE" >> /etc/php5/apache2/php.ini

	# set PHP config
	ex -s +'g/^\s*memory_limit\s*=/d' -cwq /etc/php5/apache2/php.ini
	echo         "memory_limit = 512M" >> /etc/php5/apache2/php.ini
	ex -s +'g/^\s*max_execution_time\s*=/d' -cwq /etc/php5/apache2/php.ini
	echo         "max_execution_time = 300" >> /etc/php5/apache2/php.ini
	ex -s +'g/^\s*max_input_time\s*=/d' -cwq /etc/php5/apache2/php.ini
	echo         "max_input_time = 600" >> /etc/php5/apache2/php.ini
	ex -s +'g/^\s*error_reporting\s*=/d' -cwq /etc/php5/apache2/php.ini
	echo         "error_reporting = E_ALL" >> /etc/php5/apache2/php.ini
	ex -s +'g/^\s*display_errors\s*=/d' -cwq /etc/php5/apache2/php.ini
	echo         "display_errors = On" >> /etc/php5/apache2/php.ini
	ex -s +'g/^\s*upload_max_filesize\s*=/d' -cwq /etc/php5/apache2/php.ini
	echo         "upload_max_filesize = 10M" >> /etc/php5/apache2/php.ini

	# set URL
	if [ ! -z "$BASEURL" ]; then
		for VBS in /usr/local/open-audit/other/*.{sh,vbs}; do
			sed -i 's@"http://localhost/"@"${BASEURL}/@g' "$VBS"
		done
	fi
fi

# populate /var/lib/mysql if empty (generally, but not exclusively, a first-run thing)
chown -R mysql: /var/lib/mysql
[ -z "$(ls -A /var/lib/mysql)" ] && cp -a /var/lib/mysql-dist/* /var/lib/mysql/
rm -Rf /var/lib/mysql-dist

# populate /usr/local/omk/conf if empty (generally, but not exclusively, a first-run thing)
[ -z "$(ls -A /usr/local/omk/conf)" ] && cp -a /usr/local/omk/conf-dist/* /usr/local/omk/conf/
rm -Rf /usr/local/omk/conf-dist

# start cron
cron

# start mysql service (FIXME: would be better to do this in a separate container)
service mysql start

# start the Opmentek service
service omkd start

# start the Apache2 service (FIXME: might consider using NGINX instead?)
service apache2 start

# tail the applicable logs so they appear in the Docker logs output
tail -f /var/log/apache2/*.log /usr/local/omk/log/*.log
