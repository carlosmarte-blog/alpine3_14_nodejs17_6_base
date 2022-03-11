#!/bin/sh
echo 
echo "=================================================="
echo " REDIS                                         "
echo " REDIS_VERSION $(redis-server -v)           "
echo "=================================================="

redis-server --daemonize yes