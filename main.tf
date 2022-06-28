data "alicloud_images" "ubuntu" {
  most_recent = true
  name_regex  = "^ubuntu_18.*64"
}

provider "alicloud" {
  region  = var.region
  profile = var.profile
}

module "vpc" {
  source  = "alibaba/vpc/alicloud"

  create            = true
  vpc_name          = "eth-vpc"
  vpc_cidr          = "10.10.0.0/16"

  availability_zones = ["ap-southeast-1b"]
  vswitch_cidrs      = ["10.10.1.0/24"]

  vpc_tags = {
    Environment = "product"
    Project        = "ethereum"
  }

  vswitch_tags = {
    Project  = "ethereum"
  }
}

module "security_group" {
  source  = "alibaba/security-group/alicloud"
  vpc_id  = module.vpc.this_vpc_id
  version = "~> 2.0"
  ingress_rules              = ["ssh-tcp"]
  ingress_cidr_blocks        = ["0.0.0.0/0"]

  ingress_with_cidr_blocks = [
    {
      priority    = 1
      from_port   = 8545
      to_port     = 8545
      protocol    = "tcp"
      description = "geth_port"
    }
  ]
}

module "ecs" {
  source  = "alibaba/ecs-instance/alicloud"
  region              = var.region
  profile             = var.profile
  number_of_instances = 1

  name                        = var.ecs_instance_name
  image_id                    = data.alicloud_images.ubuntu.ids.0
  instance_type               = var.instance_type
  vswitch_id                  = module.vpc.this_vswitch_ids[0]
  security_group_ids          = [module.security_group.this_security_group_id]
  associate_public_ip_address = true
  internet_max_bandwidth_out  = 10
  role_name = module.ram_role.this_role_name

  system_disk_category = "cloud_essd"
  system_disk_size     = 50

//  create essd disk==================
//  data_disks  = [{
//    name  = "eth-node-data-disk"
//    size  = 560
//    category = "cloud_essd"
//    delete_with_instance = false
//  }]
//  create essd disk==================

  tags = {
    Created      = "Terraform"
    Environment = "product"
  }
}

module "ram_role" {
  source = "terraform-alicloud-modules/ram-role/alicloud"
  create = true

  role_name = var.ram_role_name
  services  = ["ecs.aliyuncs.com"]
  force                = true
  policies = [
    # Binding a system policy.
    {
      policy_names = join(",", ["AliyunKMSSecretAdminAccess"])
      policy_type  = "System"
    }
  ]
}

resource "alicloud_kms_secret" "ethereum" {
  secret_name                   = var.secret_name
  description                   = "from terraform"
  secret_data                   = var.secret_data
  version_id                    = "1.0"
  force_delete_without_recovery = true
}


module "file_system" {
  source = "terraform-alicloud-modules/nas/alicloud"

//  create a new access group==================
//  create_access_group = true
//  access_group_name = "GETH_ACCESS_GROUP_NAME"
//  access_group_description = "default_access_group"
//  create a new access group==================

//  use default access group==================
  access_group_name = "DEFAULT_VPC_GROUP_NAME"
//  use default access group==================

  create_access_rule = true
  source_cidr_ip       = var.file_system_source_cidr_ip

  create_mount_target = true
  create_file_system       = true
  file_system_type = var.file_system_type
  file_system_protocol_type = var.file_system_protocol_type
  file_system_storage_type = var.file_system_storage_type
  file_system_description = var.file_system_description

  vswitch_id          = module.vpc.vswitch_ids[0]
}

# Create log service by sls module
module "sls" {
  source = "terraform-alicloud-modules/sls/alicloud"
  project_name = "ethnode-project"
  store_name = "geth-log"
}

//sls-logtail
module "logtail" {
  source = "terraform-alicloud-modules/sls-logtail/alicloud"

  //ecs-instance
  create_instance = false

  //sls-logtail
  create_log_service = true

  //alicloud_log_machine_group
  log_machine_group_name        = "tf-log-ethnode-group-name"
  log_machine_identify_type = "ip"
  project_name                  = module.sls.this_log_project_name
  log_machine_topic             = "tf-log-ethnode-topic"

  //alicloud_logtail_config
  config_input_type   = "file"
  config_input_detail       = <<EOF
                              {
                                  "discardUnmatch": false,
                                  "enableRawLog": true,
                                  "fileEncoding": "gbk",
                                  "filePattern": "ethnode.log",
                                  "logPath": "/ethlog",
                                  "logType": "json_log",
                                  "maxDepth": 10,
                                  "topicFormat": "default"
                              }
                              EOF
  logstore_name       = module.sls.this_log_store_name
  config_name         = "tf-logtail-eth-config-name"
  config_output_type  = "LogService"

  existing_instance_private_ips = module.ecs.this_private_ip
}
