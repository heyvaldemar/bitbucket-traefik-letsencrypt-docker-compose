#!/bin/bash

BITBUCKET_CONTAINER=$(docker ps -aqf "name=bitbucket_bitbucket")
BITBUCKET_BACKUPS_CONTAINER=$(docker ps -aqf "name=bitbucket_backups")

echo "--> All available database backups:"

for entry in $(docker container exec -it $BITBUCKET_BACKUPS_CONTAINER sh -c "ls /srv/bitbucket-postgres/backups/")
do
  echo "$entry"
done

echo "--> Copy and paste the backup name from the list above to restore database and press [ENTER]
--> Example: bitbucket-postgres-backup-YYYY-MM-DD_hh-mm.gz"
echo -n "--> "

read SELECTED_DATABASE_BACKUP

echo "--> $SELECTED_DATABASE_BACKUP was selected"

echo "--> Stopping service..."
docker stop $BITBUCKET_CONTAINER

echo "--> Restoring database..."
docker exec -it $BITBUCKET_BACKUPS_CONTAINER sh -c 'PGPASSWORD="$(echo $POSTGRES_PASSWORD)" dropdb -h postgres -p 5432 bitbucketdb -U bitbucketdbuser \
&& PGPASSWORD="$(echo $POSTGRES_PASSWORD)" createdb -h postgres -p 5432 bitbucketdb -U bitbucketdbuser \
&& PGPASSWORD="$(echo $POSTGRES_PASSWORD)" gunzip -c /srv/bitbucket-postgres/backups/'$SELECTED_DATABASE_BACKUP' | PGPASSWORD=$(echo $POSTGRES_PASSWORD) psql -h postgres -p 5432 bitbucketdb -U bitbucketdbuser'
echo "--> Database recovery completed..."

echo "--> Starting service..."
docker start $BITBUCKET_CONTAINER
