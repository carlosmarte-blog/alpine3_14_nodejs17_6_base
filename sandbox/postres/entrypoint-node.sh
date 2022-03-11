#!/bin/sh
echo 
echo "=================================================="
echo " NODE                                             "
echo " USER $(id -u)                                    "
echo " POSTGRES_STATUS $(pg_ctl -D /pgdata status)      "
echo "=================================================="

ls
find . -type f -name '*.log' -exec cat {} \;
node ./health-checks/postgres.mjs
node ./src/index.js