#!/bin/bash

set -eux

echo 'Creando directorio para NL2SQL...'
sudo mkdir -p /opt/nl2sql/app 
cd /opt/nl2sql || exit 1

# Ya no descargamos desde GitHub, el archivo será copiado por Terraform
echo 'Usando archivo nl2sql_app.py local...'
sudo cp /tmp/nl2sql_app.py /opt/nl2sql/app/

echo 'Creando entorno virtual de Python...'
sudo python3.11 -m venv venv
source venv/bin/activate

echo 'Instalando dependencias de Python...'
pip3 install --upgrade pip --quiet || { echo 'Error actualizando pip'; exit 1; }
pip3 install streamlit mysql-connector-python python-dotenv pandas sshtunnel numpy matplotlib seaborn setuptools oci --quiet || { echo 'Error instalando dependencias Python'; exit 1; }

echo 'Creando archivo .env...'
sudo bash -c "cat > /opt/nl2sql/app/.env << ENVEOF
HW_HOST=$HW_HOST
HW_DB_USER=$HW_DB_USER
HW_DB_PASS=$HW_DB_PASS
HW_DB_NAME=$HW_DB_NAME
MODEL_ID=$MODEL_ID
ENVEOF"

echo 'Creando servicio systemd...'
sudo bash -c "cat > /etc/systemd/system/nl2sql-streamlit.service << 'SERVICE'
[Unit]
Description=NL2SQL Streamlit Application
After=network.target

[Service]
Type=simple
User=opc
WorkingDirectory=/opt/nl2sql/app

# Cargar variables del proyecto
EnvironmentFile=/opt/nl2sql/app/.env

# IMPORTANTE: usar el streamlit del venv
ExecStart=/opt/nl2sql/venv/bin/streamlit run nl2sql_app.py --server.address=0.0.0.0 --server.port=8501

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE"

echo 'Ajustando permisos...'
sudo chown -R opc:opc /opt/nl2sql

echo 'Habilitando e iniciando servicio...'
sudo systemctl daemon-reload
sudo systemctl enable nl2sql-streamlit.service
sudo systemctl start nl2sql-streamlit.service

# Configurar firewall
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Abrir puertos requeridos
sudo firewall-cmd --add-port=8501/tcp --permanent
sudo firewall-cmd --add-port=5901/tcp --permanent
sudo firewall-cmd --reload

echo '✓ Instalación completada exitosamente'