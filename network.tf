data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

resource "oci_core_vcn" "nl2sql_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr_block]
  display_name   = "nl2sql-vcn"
  dns_label      = "nl2sqlvcn"
}

resource "oci_core_internet_gateway" "nl2sql_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nl2sql_vcn.id
  display_name   = "nl2sql-internet-gateway"
  enabled        = true
}

resource "oci_core_nat_gateway" "nl2sql_nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nl2sql_vcn.id
  display_name   = "nl2sql-nat-gateway"
}

resource "oci_core_service_gateway" "nl2sql_service_gw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nl2sql_vcn.id
  display_name   = "nl2sql-service-gateway"

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nl2sql_vcn.id
  display_name   = "nl2sql-public-route-table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.nl2sql_igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nl2sql_vcn.id
  display_name   = "nl2sql-private-route-table"

  route_rules {
    network_entity_id = oci_core_nat_gateway.nl2sql_nat.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.nl2sql_service_gw.id
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nl2sql_vcn.id
  display_name   = "nl2sql-public-security-list"

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    
    tcp_options {
      min = 8501
      max = 8501
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "private_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.nl2sql_vcn.id
  display_name   = "nl2sql-private-security-list"

  ingress_security_rules {
    protocol    = "6"
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    
    tcp_options {
      min = 3306
      max = 3306
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    
    tcp_options {
      min = 33060
      max = 33060
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "public_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.nl2sql_vcn.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "nl2sql-public-subnet"
  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public_route_table.id
  security_list_ids          = [oci_core_security_list.public_security_list.id]
}

resource "oci_core_subnet" "private_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.nl2sql_vcn.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "nl2sql-private-subnet"
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private_route_table.id
  security_list_ids          = [oci_core_security_list.private_security_list.id]
}