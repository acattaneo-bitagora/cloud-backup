#!/bin/sh

echo "SCHEDULE: $SCHEDULE"
echo "BACKUP_ARGS: $BACKUP_ARGS $@"

# create cron job
cat <<EOF > /etc/crontab
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

$SCHEDULE /opt/backup-cloud/backup.sh $BACKUP_ARGS $@
EOF

exec /usr/sbin/cron -L ${LOG_LEVEL:-15} -f /etc/crontab
