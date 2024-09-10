module "autoscaling" {
  source                  = "./modules/autoscaling"
  namespace               = var.namespace
  region                  = var.region

  subnet                  = module.networking.subnet
  sg                      = module.networking.sg
  lb_target_group         = module.loadbalancer.lb_target_group
  efs_id                  = module.filesystem.efs_id
  efs_mount_targetA       = module.filesystem.efs_mount_targetA
  efs_mount_targetB       = module.filesystem.efs_mount_targetB
}

module "filesystem" {
  source     = "./modules/filesystem"
  namespace  = var.namespace

  subnet     = module.networking.subnet
  sg         = module.networking.sg
}

module "loadbalancer" {
  source     = "./modules/loadbalancer"
  namespace  = var.namespace

  vpc_id     = module.networking.vpc_id
  subnet     = module.networking.subnet
  sg         = module.networking.sg
}

module "networking" {
  source    = "./modules/networking"
  namespace = var.namespace
}
