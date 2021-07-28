# tags

tags = {
  # vcn, bastion and operator tags are required
  # add more tags in each as desired
  vcn = {
    # department = "finance"
    environment = "dev"
  }
  bastion = {
    # department  = "finance"
    environment = "dev"
    role        = "bastion"
  }
  operator = {
    # department = "finance"
    environment = "dev"
    role        = "operator"
  }
}


kubernetes_version = "v1.20.8"