compartment_id = "ocid1.compartment.oc1..aaaaaaaawb5bs2tee5hxwyor7evurum3voo6eq5ub73a3fpxvuv4q5zmckra"

vcn_name = "eu-framkfurt-1-dev-fr-k8s-vcn" 

node_pools = {
  #np1 = { shape = "VM.Standard.E3.Flex", ocpus = 2, memory = 20, node_pool_size = 2, boot_volume_size = 150 }
  #np2 = { shape = "VM.Standard.E2.2", node_pool_size = 2, boot_volume_size = 150, label = { app = "application", name = "test" } }
  #np3 = { shape = "VM.Standard.E2.2", node_pool_size = 1 }
  np1 = { shape = "VM.Standard.E3.Flex", ocpus = 2, memory = 20, node_pool_size = 1, boot_volume_size = 150 }
}

node_pool_image_id = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaprt6uk32tylin3owcddyllao3uthmo7vheqepeybvjj6to7xkdgq"
node_pool_os = "Oracle Linux"
node_pool_os_version = "7.9"
