module "vpc" {
  for_each = var.vpcs
  source   = "../modules/networking/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = each.value.cidr_block
}

module "subnets" {
  for_each = var.vpcs
  source   = "../modules/networking/subnets"

  project_name  = var.project_name
  environment   = var.environment
  vpc_id        = module.vpc[each.key].vpc_id
  subnet_config = each.value.subnets
}

module "gateways" {
  for_each = var.vpcs
  source   = "../modules/networking/gateways"

  project_name = var.project_name
  environment  = var.environment

  nat_gateway_config = {
    for k, v in each.value.subnets : k => module.subnets[each.key].subnet_ids[k] if v.public
  }
}

module "routing" {
  for_each = var.vpcs
  source   = "../modules/networking/routing"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc[each.key].vpc_id
  igw_id            = module.vpc[each.key].igw_id
  public_subnet_ids = module.subnets[each.key].public_subnet_ids

  private_routing_config = {
    for k, v in each.value.subnets : k => {
      subnet_id      = module.subnets[each.key].subnet_ids[k]
      nat_gateway_id = module.gateways[each.key].nat_gateway_ids[[for pk, pv in each.value.subnets : pk if pv.public && pv.availability_zone == v.availability_zone][0]]
    } if !v.public
  }
}
