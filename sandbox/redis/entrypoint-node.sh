#!/bin/sh
echo 
echo "=================================================="
echo " NODE                                             "
echo " USER $(id -u)                                    "
echo "=================================================="

ls
find . -type f -name '*.log' -exec cat {} \;
node ./health-checks/redis.mjs
node ./src/index.js