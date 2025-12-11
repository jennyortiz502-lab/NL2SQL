data "oci_mysql_mysql_configurations" "mysql_configurations" {
  compartment_id = var.compartment_ocid
  
  filter {
    name   = "shape_name"
    values = ["MySQL.2"]
  }
}

resource "oci_mysql_mysql_db_system" "nl2sql_mysql" {
  compartment_id      = var.compartment_ocid
  shape_name          = "MySQL.2"
  subnet_id           = oci_core_subnet.private_subnet.id
  admin_password      = var.mysql_admin_password
  admin_username      = var.mysql_admin_username
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  
  display_name        = "nl2sql-mysql-heatwave"
  description         = "MySQL HeatWave for NL2SQL application"
  
  configuration_id    = data.oci_mysql_mysql_configurations.mysql_configurations.configurations[0].id
  data_storage_size_in_gb = 1024
  mysql_version       = "9.5.0"
  
  is_highly_available = false

  backup_policy {
    is_enabled        = true
    retention_in_days = 7
  }

  lifecycle {
    ignore_changes = [mysql_version]
  }
}

resource "oci_mysql_heat_wave_cluster" "nl2sql_heatwave_cluster" {
  db_system_id = oci_mysql_mysql_db_system.nl2sql_mysql.id
  cluster_size = 1
  shape_name   = "HeatWave.512GB"

  depends_on = [oci_mysql_mysql_db_system.nl2sql_mysql]
}