#!/bin/sh


# Retries a command on failure (idea stolen from http://fahdshariff.blogspot.com/2014/02/retrying-commands-in-shell-scripts.html).
# $1 - the max number of attempts
# $2 - the seconds to sleep
# $3... - the command to run
retry() {
  max_attempts="$1"; shift
  seconds="$1"; shift
  cmd="$@"
  attempt_num=1

  until $cmd
  do
    if [ $attempt_num -eq $max_attempts ]
    then
      echo "Attempt $attempt_num failed and there are no more attempts left!"
      return 1
    else
      echo "Attempt $attempt_num failed! Trying again in $seconds seconds..."
      attempt_num=`expr "$attempt_num" + 1`
      sleep "$seconds"
    fi
  done
}

retry 5 1 psql --dbname=postgres -c '\l' >/dev/null

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