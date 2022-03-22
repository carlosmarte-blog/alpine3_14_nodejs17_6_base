#!/bin/sh
echo 
echo "=================================================="
echo " POSTGRES                                         "
echo " POSTGRES_VERSION $(postgres --version)           "
echo "=================================================="

ls -ld /pgdata
ls -ls /var/lib/postgresql
# cat "/pgdata/pg_hba.conf"
# cat "/pgdata/postgresql.conf"

nohup postgres -W -p 5432 -D /pgdata >/opt/app-root/app.log 2>&1 </dev/null &

