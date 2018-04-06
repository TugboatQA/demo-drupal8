# Drupal Makefile template for Tugboat.

# Please modify the following environment variables to match your project.
# Specify the desired version of PHP in major.minor format, e.g. 7.1.
PHP_VERSION := 7.2
# Specify the Drupal site, which corellates to the name of the directory in
# your Drupal /sites directory. This is typically just default unless you are
# using Drupal multisite.
DRUPAL_SITE := default
# Specify the name of the Drupal database that is configured in settings. Note
# that the username and password for this database is tugboat/tugboat.
DRUPAL_DB_NAME := drupal8
# Specify the location of the directory that is the web root of the site,
# relative to the repo root, i.e. $TUGBOAT_ROOT. For example, if /web is where
# Drupal is installed, set DRUPAL_ROOT = ${TUGBOAT_ROOT}/web.
DRUPAL_ROOT = ${TUGBOAT_ROOT}/web
# This is the directory where you might keep configuration files that need to
# be distributed into your project for Tugboat, such as Drupal's settings.php
# or a .env specific to Tugboat.
DIST_DIR = ${TUGBOAT_ROOT}/.tugboat/dist

# Tugboat services have a handy Makefile in /usr/share/tugboat that we can use
# to simplify our setup process. We include that here. If you're curious what
# that gives you, you can run 'make -C /usr/share/tugboat' from any Tugboat
# service.
-include /usr/share/tugboat/Makefile

packages: install-php-$(PHP_VERSION) install-composer install-drush-launcher
#	# Point /var/www/html to the drupal root.
	ln -sf ${DRUPAL_ROOT} ${WWW_DIR}

drupalconfig:
#	# Copy the settings.local.php that works for Tugboat into sites/default.
	cp ${DIST_DIR}/settings.local.php ${DRUPAL_SITE_DIR}/settings.local.php
#	# Generate a hash_salt to secure the site.
	echo "\$$settings['hash_salt'] = '$$(openssl rand -hex 32)';" >> ${DRUPAL_SITE_DIR}/settings.local.php

createdb:
	$(DRUSH) sql-create -y

importdb:
	curl -L "https://www.dropbox.com/s/ji41n0q14qgky9a/demo-drupal8-database.sql.gz?dl=0" > /tmp/database.sql.gz
	zcat /tmp/database.sql.gz | $(DRUSH) sql-cli

importfiles:
	curl -L "https://www.dropbox.com/s/jveuu586eb49kho/demo-drupal8-files.tar.gz?dl=0" > /tmp/files.tar.gz
	tar -C /tmp -zxf /tmp/files.tar.gz
	rsync -av --delete /tmp/files/ $(DRUPAL_SITE_DIR)/files

build:
	$(DRUSH) cache-rebuild
	$(DRUSH) updb -y

cleanup:
	apt-get clean
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

tugboat-init: packages createdb drupalconfig importdb importfiles build cleanup
tugboat-update: importdb importfiles build cleanup
tugboat-build: build

#########
# There is often no need to modify anything below here.
DRUSH := drush -y --root=${DRUPAL_ROOT} --uri=${TUGBOAT_URL}
# The directory that the web server serves the site from. On Apache services
# this is /var/www/html. On Nginx services, it is /usr/share/nginx/html.
ifneq (,$(findstring nginx, $(TUGBOAT_SERVICE)))
  WWW_DIR := /usr/share/nginx/html
else
  WWW_DIR := /var/www/html
endif
# The path to the Drupal site dir.
DRUPAL_SITE_DIR := ${DRUPAL_ROOT}/sites/${DRUPAL_SITE}
