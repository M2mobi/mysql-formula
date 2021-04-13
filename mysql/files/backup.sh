#!/bin/bash
START_TIME=$(date +"%s")
BACKUP_CMD="{{ backup_cmd }}"
S3_DIR="{{ config.s3_dir }}"
S3_BUCKET="{{ config.s3_bucket }}"
TARGET_DIR="{{ config.target_dir }}"

DATE_TODAY=$(date --rfc-3339=date)
DATE_YESTERDAY=$(date -d "yesterday" --rfc-3339=date)
DATE_LASTWEEK=$(date -d "-7 days" --rfc-3339=date)

function report() {
  TYPE=$1
  BACKUP_PATH=$2
  STATUS_CODE=$3
  END_TIME=$(date +"%s")
  TIME=$(expr $END_TIME - $START_TIME)
  if [ "$TYPE" = "unknown" ]; then
    SIZE=0
  else
    SIZE=$(du -sb $BACKUP_PATH | grep -o '[0-9]*' | head -1)
  fi
  if [ -z "$SIZE" ]; then
    SIZE=0
  fi
{%- if 'influxdb' in config %}
  {% set comma = joiner(",") -%}
  TAGS="{% for key,item in config.influxdb.tags.items() -%}
  {{comma()}}{{ key }}={{ item }}
  {%- endfor %}"
  curl -i -XPOST -u '{{ config.influxdb.user }}:{{ config.influxdb.password }}' 'http://{{ config.influxdb.host }}:8086/write?db={{ config.influxdb.database }}' \
    --data-binary "backup,$TAGS,application=database,status=$3,type=$1 size=${SIZE}i,duration=${TIME}i"
{%- endif %}
}

{%- if 'auth' in config %}
  {% set auth = '--user="' + config.auth.user + '" --password="' + config.auth.password + '"' %}
{%- else %}
  {% set auth = '' %}
{%- endif %}

if [ -e "/etc/$BACKUP_CMD-tables.conf" ]; then
  TABLES="--tables-file=/etc/$BACKUP_CMD-tables.conf"
else
  TABLES=""
fi

# s3fs manages to get stuck in odd ways. Before we access the mount point, best to remount to be sure
if ! [ -z "$S3_DIR" ]; then
  mount -o remount "$S3_BUCKET" "$S3_DIR"

  if [ "$?" != 0 ]; then
    report "incremental" "$TARGET_DIR/inc-$DATE_TODAY" 5
    exit 5
  fi
fi

if [ ! -e "$TARGET_DIR/base/xtrabackup_checkpoints" ]; then
  # remove faulty full backup
  rm -rf "$TARGET_DIR/base"
fi

if [ ! -d "$TARGET_DIR/base" ]; then
  echo "No base backup exists."
  mkdir -p "$TARGET_DIR/base"
  $BACKUP_CMD --backup $TABLES --target-dir="$TARGET_DIR/base" {{auth}}
  STATUS=$?
  report "initial" "$TARGET_DIR/base" $STATUS
else
  if [ $(date -d "-6 days" +%s) -ge $(date -r "$TARGET_DIR/base" +%s) ]; then
    if [ -e "$TARGET_DIR/base_new" ]; then
      # cleanup incomplete full backup
      rm -rf "$TARGET_DIR/base_new"
    fi

    $BACKUP_CMD --backup $TABLES --target-dir="$TARGET_DIR/base_new" {{auth}}
    STATUS=$?

    if [ $STATUS = 0 ]; then
      DATESTRING=$DATE_LASTWEEK

      mkdir -p "$TARGET_DIR/backup-$DATESTRING"
      mv "$TARGET_DIR/base" "$TARGET_DIR/backup-$DATESTRING/base" || STATUS=2
      mv "$TARGET_DIR/base_new" "$TARGET_DIR/base" || STATUS=3
      mv "$TARGET_DIR/inc-"* "$TARGET_DIR/backup-$DATESTRING/" || STATUS=4
    fi

    report "full" "$TARGET_DIR/base" $STATUS
    exit $STATUS
  fi

  if [ -d "$TARGET_DIR/inc-$DATE_YESTERDAY" ] && [ -f "$TARGET_DIR/inc-$DATE_YESTERDAY/xtrabackup_checkpoints" ]; then
    DATE_FILE="inc-"$DATE_YESTERDAY
  else
    DATE_FILE="base"
  fi

  $BACKUP_CMD --backup $TABLES --target-dir="$TARGET_DIR/inc-$DATE_TODAY" --incremental-basedir="$TARGET_DIR/$DATE_FILE" {{auth}}
  STATUS=$?
  report "incremental" "$TARGET_DIR/inc-$DATE_TODAY" $STATUS
  echo "File writing incremental backup for $DATE_TODAY"
fi

exit $STATUS
