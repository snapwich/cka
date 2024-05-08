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