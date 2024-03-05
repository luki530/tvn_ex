module "vpc" {
  source = "./modules/vpc"

  vpc_name = "tvn_ex"
  vpc_cidr = "172.16.0.0/24"
  private_subnets_by_az = {
    "eu-central-1a" = "172.16.0.0/27"
    "eu-central-1b" = "172.16.0.32/27"
    "eu-central-1c" = "172.16.0.64/27"
  }
  public_subnets_by_az = {
    "eu-central-1a" = "172.16.0.128/27"
    "eu-central-1b" = "172.16.0.160/27"
    "eu-central-1c" = "172.16.0.192/27"
  }
}

module "jenkins" {
  source = "./modules/jenkins"

  jenkins_image   = "luki530/jenkins-master:latest"
  kaniko_image    = "gcr.io/kaniko-project/executor:latest"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
}

module "app" {
  source = "./modules/app"

  app_image       = "891377188928.dkr.ecr.eu-central-1.amazonaws.com/app-repository:latest"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
}
