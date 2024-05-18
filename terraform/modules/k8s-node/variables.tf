variable "node_count" {
  description = "The number of nodes to create"
  type        = number
}

variable "node_type" {
  description = "The type of the node (cp or worker)"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork for the nodes"
  type        = string
}

variable "zone" {
  description = "The GCP zone"
  type        = string
}

variable "image" {
    description = "The image to use for the nodes"
    type        = string
}

variable "ssh_user" {
  description = "The SSH user to use for the jumpbox"
  default     = "ansible"
}

variable "ssh_key_file" {
  description = "The public SSH key file to use for the jumpbox"
  default     = "~/.ssh/id_rsa.pub"
}