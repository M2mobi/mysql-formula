{% from tpldir ~ "/map.jinja" import mysql with context %}

{% if 'backup' in mysql %}
mysql-packages-backup:
  pkg.installed:
    - name: {{ mysql.backuppkg }}

{% if 'tables' in mysql.backup %}
mysql-script-backup-config:
  file.managed:
    - name: /etc/{{ mysql.backupcmd }}-tables.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - contents: |
        {% for table in mysql.backup.tables -%}
        {{ table }}
        {% endfor -%}
{% endif %}

mysql-script-backup:
  file.managed:
    - name: /usr/local/bin/db_backup
    - user: root
    - group: root
    - mode: 755
    - source: salt://mysql/files/backup.sh
    - template: jinja
    - defaults:
        backup_cmd: {{ mysql.backupcmd }}
        config: {{ mysql.backup }}

mysql-script-backup-logdir:
  file.directory:
    - name: {{ mysql.backup.log_dir }}
    - user: root
    - group: root
    - mode: 755

mysql-script-backup-cronjob:
  cron.present:
    - name: /usr/local/bin/db_backup &>> {{ mysql.backup.log_dir }}/database.log
    - identifier: mysql_backup
    - special: '@daily'
{% endif %}
