#!/bin/bash

set -eux



echo "Esperando a que MySQL HeatWave esté disponible..."

MAX_RETRIES=10
RETRY_COUNT=0

until mysql -h "$HW_HOST" -u "$HW_DB_USER" -p"$HW_DB_PASS" -e "SELECT 1" >/dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo "ERROR: MySQL no disponible después de 5 minutos. Abortando."
        exit 1
    fi
    echo "Intento $RETRY_COUNT/$MAX_RETRIES: MySQL no disponible aún. Esperando..."
    sleep 10
done

echo "MySQL disponible. Creando base de datos..."

mysql -h "$HW_HOST" -u "$HW_DB_USER" -p"$HW_DB_PASS" \
      -e "CREATE DATABASE IF NOT EXISTS $HW_DB_NAME;" \
      || { echo "Error creando base de datos"; exit 1; }

echo "Descargando dump…"

sudo mkdir -p /opt/dataDB
sudo wget -q -P /opt/dataDB \
  "https://objectstorage.us-chicago-1.oraclecloud.com/n/grri30nzv1ul/b/Mysql_AI/o/airport_db.zip" \
  || { echo "Error descargando dump"; exit 1; }

sudo unzip -o /opt/dataDB/airport_db.zip -d /opt/dataDB \
  || { echo "Error descomprimiendo dump"; exit 1; }

sudo chmod -R 755 /opt/dataDB

echo "Ejecutando carga del dump con MySQL Shell..."

mysqlsh --uri "$HW_DB_USER:$HW_DB_PASS@$HW_HOST:3306" --js -f /tmp/load_dump.js \
  || { echo "Error cargando dump"; exit 1; }

echo "Dump cargado exitosamente."
