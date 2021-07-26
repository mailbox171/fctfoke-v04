## Source from https://registry.terraform.io/providers/hashicorp/oci/latest/docs/resources/core_security_list

############# SECURITY LIST #######################
resource "oci_core_security_list" "priv_sec_list" {
# Required
  compartment_id = var.compartment_id
  vcn_id = module.oke.vcn_id

# Optional
  display_name = "seclist-for-mysql-private-subnet"
  
  egress_security_rules {
      stateless = false
      destination = "0.0.0.0/0"
      destination_type = "CIDR_BLOCK"
      protocol = "all" 
  }

ingress_security_rules { 
      stateless = false
      source = "10.0.0.0/16"
      source_type = "CIDR_BLOCK"
      # Get protocol numbers from https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml TCP is 6
      protocol = "6"
      tcp_options { 
          min = 22
          max = 22
      }
  }
}



############# SUBNET ############################
resource "oci_core_subnet" "test_subnet" {
  cidr_block     = "10.0.3.0/24"
  #compartment_id = var.compartment_ocid
  compartment_id = var.compartment_id
  #vcn_id         = oci_core_vcn.test_vcn.id          #### NEED VCN ID <<<<<<<<<<<<<<<<<<< #######
  vcn_id         = module.oke.vcn_id 
  security_list_ids  = [oci_core_security_list.priv_sec_list.id]
}




############# BACKUP ############################
#resource "oci_mysql_mysql_backup" "test_mysql_backup" {
#  db_system_id = oci_mysql_mysql_db_system.test_mysql_backup_db_system.id
#}




############# BACKUP DB ##########################
############# BACKUP DB ##########################
#resource "oci_mysql_mysql_db_system" "test_mysql_backup_db_system" {
#  #Required
#  admin_password      = "BEstrO0ng_#11"
#  admin_username      = "adminUser"
#  availability_domain = data.oci_identity_availability_domains.test_availability_domains.availability_domains[0].name
#  #compartment_id      = var.compartment_ocid
#  compartment_id      = var.compartment_id
#  configuration_id    = data.oci_mysql_mysql_configurations.test_mysql_configurations.configurations[0].id
#  shape_name          = "VM.Standard.E2.2"
#  subnet_id           = oci_core_subnet.test_subnet.id

  #Optional
#  data_storage_size_in_gb = "50"
#}




resource "oci_mysql_mysql_db_system" "test_mysql_db_system" {
  #Required
  admin_password      = "BEstrO0ng_#11"
  admin_username      = "adminUser"
  availability_domain = data.oci_identity_availability_domains.test_availability_domains.availability_domains[0].name
  #compartment_id      = var.compartment_ocid
  compartment_id      = var.compartment_id
  configuration_id    = data.oci_mysql_mysql_configurations.test_mysql_configurations.configurations[0].id
  shape_name          = "VM.Standard.E2.2"
  subnet_id           = oci_core_subnet.test_subnet.id

  data_storage_size_in_gb = "50"

  #Optional
  backup_policy {
    is_enabled        = "false"    # BACKUP ENABLED FALSE
    retention_in_days = "10"
    window_start_time = "01:00-00:00"
  }

  #defined_tags  = {"${oci_identity_tag_namespace.tag-namespace1.name}.${oci_identity_tag.tag1.name}" = "${var.mysql_defined_tags_value}"}
  #freeform_tags = var.mysql_freeform_tags
  description = "MySQL Database Service"

  display_name   = "DBSystem001"
  fault_domain   = "FAULT-DOMAIN-1"
  hostname_label = "hostnameLabel"
  #ip_address     = "10.0.0.8"
  ip_address     = "10.0.3.8"

  maintenance {
    window_start_time = "sun 01:00"
  }

  port          = "3306"
  port_x        = "33306"


  # (Optional) (Updatable) Specifies if the DB System is highly available.
  # When creating a DB System with High Availability, three instances are created and placed
  # according to your region- and subnet-type. The secondaries are placed automatically
  # in the other two availability or fault domains. You can choose the preferred location of your primary instance, only.
  is_highly_available = "false"
   

  # OPTIONAL - Creating DB System using a backup
  #source {
    #backup_id   = oci_mysql_mysql_backup.test_mysql_backup.id
    #source_type = "BACKUP"
  #}

}




  # DATA BLOCKs
data "oci_mysql_mysql_configurations" "test_mysql_configurations" {
  compartment_id = var.compartment_id

  #Optional
  state        = "ACTIVE"
  shape_name   = "VM.Standard.E2.2"
}


   #### data source #########
data "oci_identity_availability_domains" "test_availability_domains" {
    #compartment_id = var.tenancy_ocid
    compartment_id = var.tenancy_id
}

output "configuration_id" {
    value = data.oci_mysql_mysql_configurations.test_mysql_configurations.configurations[0].id
}


 

