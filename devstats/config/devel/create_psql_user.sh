#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi

if [ -z "$1" ]
then
  echo "$0: user name required"
  exit 1
fi

if [ -z "$ONLY" ]
then
  all="kubeflow devstats"
else
  all=$ONLY
fi

cp ./util_sql/drop_psql_user.sql /tmp/drop_user.sql || exit 1
FROM="{{user}}" TO="$1" MODE=ss ./replacer /tmp/drop_user.sql || exit 1

if [ ! -z "$DROP" ]
then
  echo "Drop from public"
  sudo -E -u postgres psql < /tmp/drop_user.sql || exit 1
  for proj in $all
  do
    echo "Drop from $proj"
    sudo -E -u postgres psql "$proj" < /tmp/drop_user.sql || exit 1
  done
fi

if [ ! -z "$NOCREATE" ]
then
  echo "Skipping create"
  exit 0
fi

echo "Create role"
sudo -E -u postgres psql -c "create user \"$1\" with password '$PG_PASS'" || exit 1

for proj in $all
do
  echo "Grants $proj"
  ./devel/psql_user_grants.sh "$1" "$proj" || exit 2
done
echo 'OK'
