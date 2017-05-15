{%- from tpldir ~ "/map.jinja" import mysql with context %}
{%- set os_family = salt['grains.get']('os_family', None) %}

{%- if "config_directory" in mysql %}
mysql_config_directory:
  file.directory:
    - name: {{ mysql.config_directory }}
    {%- if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - user: root
    - group: root
    - mode: 755
    {%- endif %}
    - makedirs: True

mysql_auth_config:
  file.managed:
    - name: {{ mysql.config_directory + mysql.auth_config.file }}
    - template: jinja
    - source: salt://mysql/files/authentication.cnf
    {% if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - context:
      tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    {% endif %}

{%- if "server_config" in mysql %}
mysql_server_config:
  file.managed:
    - name: {{ mysql.config_directory + mysql.server_config.file }}
    - template: jinja
    - source: salt://{{ tpldir }}/files/server.cnf
    {%- if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - context:
      tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    {%- endif %}
    - require:
      - file: mysql_config_directory
{%- endif %}

{%- if "galera_config" in mysql %}
mysql_galera_config:
  file.managed:
    - name: {{ mysql.config_directory + mysql.galera_config.file }}
    - template: jinja
    - source: salt://{{ tpldir }}/files/galera.cnf
    {%- if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - context:
      tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    {%- endif %}
    - require:
      - file: mysql_config_directory
{%- endif %}

{%- if "library_config" in mysql %}
mysql_library_config:
  file.managed:
    - name: {{ mysql.config_directory + mysql.library_config.file }}
    - template: jinja
    - source: salt://{{ tpldir }}/files/client.cnf
    {%- if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - context:
      tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    {%- endif %}
    - require:
      - file: mysql_config_directory
{%- endif %}

{%- if "clients_config" in mysql %}
mysql_clients_config:
  file.managed:
    - name: {{ mysql.config_directory + mysql.clients_config.file }}
    - template: jinja
    - source: salt://{{ tpldir }}/files/mysql-clients.cnf
    {%- if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - context:
      tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    {%- endif %}
    - require:
      - file: mysql_config_directory
{%- endif %}

{% if "tokudb_config" in mysql %}
mysql_tokudb_config:
  file.managed:
    - name: {{ mysql.config_directory + mysql.tokudb_config.file }}
    - template: jinja
    - source: salt://mysql/files/tokudb.cnf
    {% if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - context:
      tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    {% endif %}
{% endif %}

{% if "oqgraph_config" in mysql %}
mysql_oqgraph_config:
  file.managed:
    - name: {{ mysql.config_directory + mysql.oqgraph_config.file }}
    - template: jinja
    - source: salt://mysql/files/oqgraph.cnf
    {% if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - context:
      tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    {% endif %}
{% endif %}

{% if "audit_config" in mysql %}
mysql_audit_config:
  file.managed:
    - name: {{ mysql.config_directory + mysql.audit_config.file }}
    - template: jinja
    - source: salt://mysql/files/audit.cnf
    {% if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - context:
      tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    {% endif %}
{% endif %}

{% set mysql_aws_kms = salt['pillar.get']('mysql:aws_kms:master_key_id', False) %}
{% if "aws_kms_config" in mysql and mysql_aws_kms %}
mysql_aws_kms_config:
  file.managed:
    - name: {{ mysql.config_directory + mysql.aws_kms_config.file }}
    - template: jinja
    - source: salt://mysql/files/aws-kms.cnf
    {% if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - context:
      tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    {% endif %}
{% endif %}

{%- endif %}

mysql_config:
  file.managed:
    - name: {{ mysql.config.file }}
    - template: jinja
{%- if "config_directory" in mysql %}
    - source: salt://{{ tpldir }}/files/my-include.cnf
{%- else %}
    - source: salt://{{ tpldir }}/files/my.cnf
{%- endif %}
    - context:
      tpldir: {{ tpldir }}
    {%- if os_family in ['Debian', 'Gentoo', 'RedHat'] %}
    - user: root
    - group: root
    - mode: 644
    {%- endif %}
