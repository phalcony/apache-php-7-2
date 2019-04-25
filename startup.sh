#!/bin/bash

if [ ! -f .migrated ]; then
    cd /var/www/html

    # doing migrations
    echo "Migrations started"
    php bin/console doctrine:migrations:migrate
    php bin/console doctrine:fixtures:load


    # Set lockfile
    touch .migrated
fi
    echo "Migrations already done"
exec "$@";