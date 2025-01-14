command:
  - /bin/bash
  - -c
  - |
    if [ -f /opt/ibm/init-scripts/init.sql ]; then
      cp /opt/ibm/init-scripts/init.sql /opt/ibm/data/init.sql && \
      oninit && \
      echo "Voer init-script uit om gebruikers en databases aan te maken..." && \
      dbaccess - /opt/ibm/data/init.sql
    else
      echo "Geen init.sql gevonden!"
    fi
