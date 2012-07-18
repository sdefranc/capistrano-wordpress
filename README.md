capistrano-wordpress
====================

This is a basic capistrano recipe for deploying Wordpress installs.
It assumes a sensible hosting environment like php-fpm where the server
runs as the deploy user.

Requirements
------------

* railsless-deploy gem
* capistrano-ext gem (this is overkill and will be removed in the future)