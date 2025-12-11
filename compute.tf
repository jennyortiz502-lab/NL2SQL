############################################
# Creates a PEM (and OpenSSH) formatted private key.
############################################

#https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
resource "tls_private_key" "instance_ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Llave privada en formato PEM
output "instance_private_key_pem" {
  description = "Private key in PEM format for SSH access"
  value       = nonsensitive(tls_private_key.instance_ssh.private_key_pem)
  sensitive   = false
}
data "oci_core_images" "oracle_linux_8" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.compute_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "nl2sql_app" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = "nl2sql-streamlit-app"
  shape               = var.compute_shape

  shape_config {
    ocpus         = var.compute_ocpus
    memory_in_gbs = var.compute_memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    display_name     = "nl2sql-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux_8.images[0].id
  }
  

  metadata = {
    ssh_authorized_keys = tls_private_key.instance_ssh.public_key_openssh
  }
  
  depends_on = [
    oci_mysql_mysql_db_system.nl2sql_mysql,
    oci_mysql_heat_wave_cluster.nl2sql_heatwave_cluster
  ]
  
}

# Variables locales para reutilizar en las conexiones
locals {
  ssh_user        = "opc"
  ssh_private_key = tls_private_key.instance_ssh.private_key_pem
  ssh_host        = oci_core_instance.nl2sql_app.public_ip
  ssh_timeout     = "15m"
  
  # MySQL endpoint - usar IP privada o hostname dependiendo de lo que esté disponible
  mysql_host = coalesce(
    try(oci_mysql_mysql_db_system.nl2sql_mysql.endpoints[0].hostname, ""),
    try(oci_mysql_mysql_db_system.nl2sql_mysql.endpoints[0].ip_address, ""),
    ""
  )
}

resource "null_resource" "nl2sql_setup" {
  depends_on = [
    oci_core_instance.nl2sql_app
  ]

  triggers = {
    instance_id = oci_core_instance.nl2sql_app.id
  }

  connection {
    type        = "ssh"
    user        = "opc"
    private_key = tls_private_key.instance_ssh.private_key_pem
    host        = oci_core_instance.nl2sql_app.public_ip
    timeout     = "5m"
  }

  ##################################################
  # 1. Copiar scripts
  ##################################################
  
  provisioner "file" {
    source      = "${path.module}/nl2sql_app.py"  
    destination = "/tmp/nl2sql_app.py"
  }
  
  provisioner "file" {
    source      = "scripts/install-nl2sql.sh"
    destination = "/tmp/install-nl2sql.sh"
  }

  provisioner "file" {
    source      = "scripts/install-db.sh"
    destination = "/tmp/install-db.sh"
  }

  provisioner "file" {
    source      = "scripts/load_dump.js"
    destination = "/tmp/load_dump.js"
  }
  
  provisioner "file" {
	  content = templatefile("${path.module}/scripts/app.env.tpl", {
		hw_host = oci_mysql_mysql_db_system.nl2sql_mysql.endpoints[0].ip_address
		db_user = var.mysql_admin_username
		db_pass = var.mysql_admin_password
		db_name = var.mysql_db_name
		model_id = var.heatwave_model_id
	  })
	  destination = "/tmp/app.env"
  }

  ##################################################
  # 2. Instalar paquetes básicos en la VM
  ##################################################
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "echo '⏳ Esperando cloud-init…'",
      "cloud-init status --wait || true",

      "echo '📦 Instalando paquetes base…'",
	  "sudo dnf install -y oracle-epel-release-el8",
	  "sudo dnf update -y",
      "sudo yum install -y python3.11 python3.11-devel python3.11-pip git gcc mysql mysql-shell wget unzip 2>&1 | sudo tee /var/log/install_packages.log",
      "echo '✔️ Paquetes instalados'"
    ]
    on_failure = fail
  }


  ##################################################
  # 4. Ejecutar install-nl2sql.sh
  ##################################################
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install-nl2sql.sh",
      "echo '▶️ Ejecutando instalación NL2SQL…'",

      # Cargamos variables desde /tmp/app.env
      "sudo bash -c 'set -a; source /tmp/app.env; bash /tmp/install-nl2sql.sh' 2>&1 | sudo tee /var/log/install-nl2sql.log",

      "echo '✔️ NL2SQL instalado correctamente'"
    ]
    on_failure = fail
  }

  ##################################################
  # 5. Ejecutar install-db.sh
  ##################################################
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install-db.sh",
      "echo '▶️ Ejecutando instalación base de MySQL…'",

      "sudo bash -c 'set -a; source /tmp/app.env; bash /tmp/install-db.sh' 2>&1 | sudo tee /var/log/install-db.log",

      "echo '✔️ MySQL configurado correctamente'"
    ]
    on_failure = fail
  }
}
