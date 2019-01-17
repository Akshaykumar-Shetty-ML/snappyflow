variable "region" {}

variable "access_key" {}

variable "secret_key" {}

variable "ssh_user" {}

variable "stackname" {}

variable "nodecount" {
  default = 1 
}

variable "instance_type" {
  default = "t2.small"
}

variable "ssh_key_name" {
  default = "shared-SSHkey-fordemo"
}

variable "ssh_key_path" {
  default = "./keys"
}

variable "mysqlrootpassword" {
  default = "maplelabs"
}

