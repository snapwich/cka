variable "project" {
  description = "The GCP project"
  default     = "richsnapp-174618"
}

variable "image" {
  description = "The image to use for the nodes"
  default     = "projects/debian-cloud/global/images/debian-12-bookworm-v20240415"
}

variable "local_ip" {
  description = "The IP address of the local machine"
  default     = "166.70.229.151/32"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "pod_cidr" {
  description = "The CIDR block for the pods"
  default     = "10.244.0.0/16"
}

variable "region" {
  description = "The GCP region"
  default     = "us-west1"
}

variable "zone" {
  description = "The GCP zone"
  default     = "us-west1-c"
}

variable "cp_count" {
  description = "The number of control plane nodes to create"
  default     = 3
}

variable "worker_count" {
  description = "The number of worker nodes to create"
  default     = 1
}

variable "ssh_user" {
  description = "The SSH user to use for the jumpbox"
  default     = "ansible"
}

variable "ssh_key_file" {
  description = "The public SSH key file to use for the jumpbox"
  default     = "~/.ssh/id_rsa.pub"
}