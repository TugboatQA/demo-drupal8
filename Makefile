packages:
	apt-get install -y python-software-properties software-properties-common
	add-apt-repository -y ppa:ondrej/php
	apt-get update
	apt-get install -y \
		php7.1 \
		php7.1-xml \
		php7.1-mbstring \
		php7.1-zip \
		mysql-client \
		rsync
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	a2enmod php7.1
	composer install
	ln -sf ${TUGBOAT_ROOT}/web /var/www/html
	# By exporting the vendor/bin directory to our path, Drush 9 will work.
	echo "PATH=\"${TUGBOAT_ROOT}/vendor/bin:$PATH\"" > /etc/environment


drupalconfig:
	cp ${TUGBOAT_ROOT}/dist/settings.php /var/www/html/sites/default/settings.php
	cp ${TUGBOAT_ROOT}/dist/tugboat.settings.php /var/www/html/sites/default/settings.local.php
	echo "\$$settings['hash_salt'] = '$$(openssl rand -hex 32)';" >> /var/www/html/sites/default/settings.local.php

createdb:
	mysql -h mysql -u tugboat -ptugboat -e "create database demo;"

importdb:
	curl -L "https://www.dropbox.com/s/ji41n0q14qgky9a/demo-drupal8-database.sql.gz?dl=0" > /tmp/database.sql.gz
	zcat /tmp/database.sql.gz | mysql -h mysql -u tugboat -ptugboat demo

importfiles:
	curl -L "https://www.dropbox.com/s/jveuu586eb49kho/demo-drupal8-files.tar.gz?dl=0" > /tmp/files.tar.gz
	tar -C /tmp -zxf /tmp/files.tar.gz
	rsync -av --delete /tmp/files/ /var/www/html/sites/default/files/

build:
	drush -r /var/www/html cache-rebuild
	drush -r /var/www/html updb -y

cleanup:
	apt-get clean
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

tugboat-init: packages createdb drupalconfig importdb importfiles build cleanup
tugboat-update: importdb importfiles build cleanup
tugboat-build: build
