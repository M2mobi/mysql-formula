{% set config = salt['pillar.get']('mysql:ssl', None) %}
{% set hierarchy = salt['grains.get']('ec2_tags:hierarchy', None) %}
{% if config != None and hierarchy == 'master' %}
# This will create a full stack of certificates, you should only use this once, and copy files over.
# For replication you should copy over ca.crt, server.key and server.crt
# For the frontend you should copy over ca.crt, client.key and client.crt
# For another environment you should copy ca.key and ca.crt and create the rest of the files in the new environment

openssl genrsa 2048 > ca.key:
  cmd.run:
    - cwd: /etc/my.cnf.d/ssl
    - creates: /etc/my.cnf.d/ssl/ca.key
    - unless: /etc/my.cnf.d/ssl/ca.crt

openssl req -new -x509 -nodes -days 365000 -key ca.key -out ca.crt -subj "/emailAddress=sysadmin@moveagency.com/C=NL/L=Amsterdam/O=M2mobi/CN={{config.ca_domain}}":
  cmd.run:
    - cwd: /etc/my.cnf.d/ssl
    - creates: /etc/my.cnf.d/ssl/ca.crt
    - onlyif: cat /etc/my.cnf.d/ssl/ca.key

openssl req -newkey rsa:2048 -days 365000 -nodes -keyout server.key -out server-req.pem -subj "/emailAddress=sysadmin@moveagency.com/C=NL/L=Amsterdam/O=M2mobi/CN={{config.server_domain}}":
  cmd.run:
    - cwd: /etc/my.cnf.d/ssl
    - creates: /etc/my.cnf.d/ssl/server.key

openssl rsa -in server.key -out server.key:
  cmd.run:
    - cwd: /etc/my.cnf.d/ssl
    - onlyif: cat /etc/my.cnf.d/ssl/server.key

openssl x509 -req -in server-req.pem -days 365000 -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt:
  cmd.run:
    - cwd: /etc/my.cnf.d/ssl
    - creates: /etc/my.cnf.d/ssl/server.crt
    - onlyif: cat /etc/my.cnf.d/ssl/ca.key && /etc/my.cnf.d/ssl/ca.crt

rm server-req.pem:
    cmd.run:
      - cwd: /etc/my.cnf.d/ssl
      - onlyif: cat server-req.pem

openssl req -newkey rsa:2048 -days 365000 -nodes -keyout client.key -out client-req.pem -subj "/emailAddress=sysadmin@moveagency.com/C=NL/L=Amsterdam/O=M2mobi/CN={{config.client_domain}}":
  cmd.run:
    - cwd: /etc/my.cnf.d/ssl
    - creates: /etc/my.cnf.d/ssl/client.key

openssl rsa -in client.key -out client.key:
  cmd.run:
    - cwd: /etc/my.cnf.d/ssl
    - onlyif: cat /etc/my.cnf.d/ssl/client.key

openssl x509 -req -in client-req.pem -days 365000 -CA ca.crt -CAkey ca.key -set_serial 01 -out client.crt:
  cmd.run:
    - cwd: /etc/my.cnf.d/ssl
    - creates: /etc/my.cnf.d/ssl/client.crt
    - onlyif: cat /etc/my.cnf.d/ssl/ca.key && /etc/my.cnf.d/ssl/ca.crt

rm client-req.pem:
    cmd.run:
      - cwd: /etc/my.cnf.d/ssl
      - onlyif: cat client-req.pem
{% endif %}
