apiVersion: v1
kind: ConfigMap
metadata:
  name: informix-scripts
  namespace: informixtest
data:
  user-setup.sh: |
    #!/bin/sh
    set -e
    # Gebruiker toevoegen aan het OS
    useradd test1 || true
    echo "test1:test123456789!" | chpasswd
    # Query uitvoeren in Informix
    echo "GRANT CONNECT TO test1;" | dbaccess sysadmin -
