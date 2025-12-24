output "vpcs" {
  description = "Map of created VPCs and their properties"
  value = {
    for k, v in module.vpc : k => {
      vpc_id             = v.vpc_id
      public_subnet_ids  = module.subnets[k].public_subnet_ids
      private_subnet_ids = module.subnets[k].private_subnet_ids
    }
  }
}
