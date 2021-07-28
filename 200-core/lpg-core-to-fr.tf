#### test ####

data "terraform_remote_state" "fr-data" {
  backend = "local"

  config = {
    path = "../${var.fr-dir}/terraform.tfstate"
  }
}

output "fr_100_vcn_id" {
  value = data.terraform_remote_state.fr-data.outputs.vcn_id 
  description = "OCID of FR VCN"
}






# LPG in VCN 100 FR
resource "oci_core_local_peering_gateway" "LPG100" {
  compartment_id = var.compartment_id
  ### vcn of lower layer FR ###
  vcn_id         = data.terraform_remote_state.fr-data.outputs.vcn_id
  display_name   = "LPG100"
  freeform_tags = {"VCN"= "FR"}
  
}

# LPG route table in VCN 
resource "oci_core_route_table" "LPG100RouteTable" {
  compartment_id = var.compartment_id
  ### vcn of lower layer FR ###
  vcn_id         = data.terraform_remote_state.fr-data.outputs.vcn_id
  display_name   = "LPG100RouteTable"
  route_rules {
    ### CORE LAYER CIDR ###
    destination       = "10.1.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.LPG100.id
    #cidr_block = DEPRECATED
  
  /*
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.FoggyKitchenNATGateway.id
  }
  */
  }
}



# LPG in VCN 200 CORE (current root dir)
resource "oci_core_local_peering_gateway" "LPG200" {
  compartment_id = var.compartment_id
  vcn_id         = module.oke.vcn_id
  display_name   = "LPG200"
  freeform_tags = {"VCN"= "CORE"}
  # peered to 100 FR *
  peer_id        = oci_core_local_peering_gateway.LPG100.id
}

# LPG route table in VCN 200 CORE
resource "oci_core_route_table" "LPG200RouteTable" {
  compartment_id = var.compartment_id
  vcn_id         = module.oke.vcn_id
  display_name   = "FLPG200RouteTable"
  route_rules {
    destination       = "10.0.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.LPG200.id
    #cidr_block = DEPRECATED
  }
}
 









/*
bastion_public_ip = "130.61.37.66"
cluster_id = "ocid1.cluster.oc1.eu-frankfurt-1.aaaaaaaa7jewvqq7odj3rvrbjujto26yuw5hx3uaangfow5nachgsl6wekba"
configuration_id = "ocid1.mysqlconfiguration.oc1..aaaaaaaah6o6qu3gdbxnqg6aw56amnosmnaycusttaa7abyq2tdgpgubvsgj"
ig_route_id = "ocid1.routetable.oc1.eu-frankfurt-1.aaaaaaaa324i5lrnupbok3d6cjspetmvhkrydia3opcqioirnl37secxtqla"
kubeconfig = "export KUBECONFIG=generated/kubeconfig"
nat_route_id = "ocid1.routetable.oc1.eu-frankfurt-1.aaaaaaaaq3udryw2uic2skmfssy7qjrb54oz2myymb27diqopiaskfi6ozgq"
nodepool_ids = {
  "dev-np1" = "ocid1.nodepool.oc1.eu-frankfurt-1.aaaaaaaavl3rvgbirv2ws6cxb6u7gcscytw5leofxsp77k7vxnll5lgrofla"
}
operator_private_ip = "10.0.0.6"
ssh_to_bastion = "ssh -i ~/keys/ssh-key-2021-07-01.key opc@130.61.37.66"
ssh_to_operator = "ssh -i ~/keys/ssh-key-2021-07-01.key -J opc@130.61.37.66 opc@10.0.0.6"
subnet_ids = {
  "cp" = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaabcqeil2urufn7yqlna2w5zsnlzulfsdn6wxxmxte2xb5wywnhzra"
  "int_lb" = ""
  "pub_lb" = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaasbrex4t6eekj467mahmoqsi24z5s7s63gibuvmbed3pbu6fw4yja"
  "workers" = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaaac5fd3izsznccd3ydrougan2b6i6cuh2raw27y6u6s2omwcq35xa"
}
vcn_id = "ocid1.vcn.oc1.eu-frankfurt-1.amaaaaaazjgvoqyaub4rh2xb34vduqbgibbldrtnhyexaydxeig2ktx54e7a"
[opc@h-k8s-lab-a-helidon-2020-29-10-fc 100-fr]$ ls

*/