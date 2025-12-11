output "instructions" {
  description = "Instrucciones para acceder a la aplicación"
  value = <<-EOT
  
  ====================================================================
  ✅ DESPLIEGUE COMPLETADO EXITOSAMENTE
  ====================================================================
  
  🌐 URL de la Aplicación Streamlit:
     http://${oci_core_instance.nl2sql_app.public_ip}:8501
  
  🔐DESCARGA LLAVE PRIVADA, IR AL APARTADO OUTPUT DEL RESOURCE MANAGER PARA OPTENER EL CONTENIDO DE LA KEY
  🔐 Conexión SSH a la instancia:
     ssh -i <tu_clave_privada> opc@${oci_core_instance.nl2sql_app.public_ip}

  🗄️ MySQL HeatWave Endpoint:
     Host: ${oci_mysql_mysql_db_system.nl2sql_mysql.endpoints[0].ip_address}
     Port: ${oci_mysql_mysql_db_system.nl2sql_mysql.endpoints[0].port}
     Usuario: ${var.mysql_admin_username}
     Base de datos: ${var.mysql_db_name}
  
    
  ⏱️  IMPORTANTE: La aplicación puede tardar 2-3 minutos adicionales
     en estar lista después de que Terraform complete el despliegue.
  
  ====================================================================
  EOT
}

output "streamlit_app_url" {
  description = "URL para acceder a la aplicación Streamlit"
  value       = "http://${oci_core_instance.nl2sql_app.public_ip}:8501"
}

output "streamlit_app_public_ip" {
  description = "IP pública de la aplicación Streamlit"
  value       = oci_core_instance.nl2sql_app.public_ip
}