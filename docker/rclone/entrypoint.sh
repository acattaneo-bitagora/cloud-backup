#!/bin/sh
BACKUP_COMMAND="/usr/local/bin/rclone $*"
echo "SCHEDULE: $SCHEDULE"
echo "BACKUP_COMMAND: $BACKUP_COMMAND"

# create cron job
cat <<EOF > /etc/crontabs/root
# do daily/weekly/monthly maintenance
# min   hour    day     month   weekday command
#*/15    *       *       *       *       run-parts /etc/periodic/15min
#0       *       *       *       *       run-parts /etc/periodic/hourly
#0       2       *       *       *       run-parts /etc/periodic/daily
#0       3       *       *       6       run-parts /etc/periodic/weekly
#0       5       1       *       *       run-parts /etc/periodic/monthly
$SCHEDULE $BACKUP_COMMAND
EOF

# start cron
exec /usr/sbin/crond -f -l "${LOG_LEVEL:-8}" -L /dev/stderr -c /etc/crontabs/
