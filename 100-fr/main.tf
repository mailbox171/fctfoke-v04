module "oke" {
  source  = "oracle-terraform-modules/oke/oci"
  #version = "3.2.0"
  version="3.3.0"

  #KUBERNETES VERSION
  kubernetes_version=var.kubernetes_version

  # Identity and access
  api_fingerprint      = var.api_fingerprint
  api_private_key_path = var.api_private_key_path
  compartment_id       = var.compartment_id
  tenancy_id           = var.tenancy_id
  user_id              = var.user_id


  # SSH Keys
  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path


  # General OCI Environment 
  label_prefix = var.label_prefix
  region       = var.region

  #VCN
  vcn_cidr      = var.vcn_cidr
  vcn_dns_label = var.vcn_dns_label
  vcn_name      = var.vcn_name


  #BASTION
  bastion_shape    = var.bastion_shape
  bastion_timezone = var.bastion_timezone


  #OPERATOR ENABLED 
  operator_enabled  = true
  operator_instance_principal = true #required for CALICO, metrics server, ...
  operator_shape    = var.operator_shape
  operator_timezone = var.operator_timezone


  #DISABLE SIGNED IMAGES
  #OKE also supports enforcing the use of signed images
  use_signed_images = false
  image_signing_keys = []
  #image_signing_keys = ["ocid1.key.oc1....", "ocid1.key.oc1...."]


  #node_pools
  node_pools = var.node_pools
  #node_pool_os = var.node_pool_os
  #node_pool_os_version = var.node_pool_os_version 
  node_pool_image_id = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaprt6uk32tylin3owcddyllao3uthmo7vheqepeybvjj6to7xkdgq"
  
  ###############################################################################################################
  # default of both properties is "public"
  #
  # If you intend to use internal load balancers, you must ensure the following:
  #      preferred_lb_subnet is set to "internal"
  #      subnet_type is set to either "both" or "internal"
  #
  # Even if you set the load balancer subnets to be internal, 
  # you still need to set the correct annotations when creating internal load balancers. 
  # Just setting the subnet to be private is not sufficient e.g. :
  #       service.beta.kubernetes.io/oci-load-balancer-internal: "true"
  # REF: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingloadbalancer.htm#CreatingInternalLoadBalancersinPublicandPrivateSubnets
  lb_subnet_type       = var.lb_subnet_type
  preferred_lb_subnets = var.preferred_lb_subnets


  #Configure KMS Integration parameters
  #The KMS integration parameters control whether OCI Key Management Service will be used for encrypting Kubernetes secrets. 
  #Additionally, the bastion and operator hosts must be enabled as well as instance_principal on the operator.
  use_encryption  = false  
  existing_key_id = "<existing_key_id>"

  #WAF
  waf_enabled = var.waf_enabled
  
  allow_node_port_access = var.allow_node_port_access
  

  #NODE DOCTOR
  allow_worker_ssh_access = var.allow_worker_ssh_access

  #CALICO
  calico_enabled = var.calico_enabled
 
  #METRICS SERVER
  metricserver_enabled = var.metricserver_enabled 

}
