output "k8s-node" {
  value = google_compute_instance.k8s-node
  description = "The k8s node instances"
}