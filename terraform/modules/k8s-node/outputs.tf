
output "k8s-nodes" {
  description = "The k8s node instances"
  value = google_compute_instance.k8s-node
}

output "hostnames" {
  description = "The hostnames of the nodes"
  value = [for i in google_compute_instance.k8s-node : i.name]
}