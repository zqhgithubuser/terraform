module "autoscaling" {
  source      = "./modules/autoscaling"
  namespace   = var.namespace

  vpc         = module.networking.vpc
  sg          = module.networking.sg
  db_config   = module.database.db_config
  ssh_keypair = var.ssh_keypair
}

module "database" {
  source    = "./modules/database"
  namespace = var.namespace

  vpc = module.networking.vpc
  sg  = module.networking.sg
}

module "networking" {
  source    = "./modules/networking"
  namespace = var.namespace
}
