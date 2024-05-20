
output "jumpbox_ip" {
  value = google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip
}

output "node_control_planes" {
  value = [
    for i in range(length(google_dns_record_set.k8s_nodes_cp)) : {
      dns_name = google_dns_record_set.k8s_nodes_cp[i].name
      ip_address = module.k8s-node-cp.k8s-nodes[i].network_interface[0].network_ip
    }
  ]
  description = "The DNS names and IP addresses of the control plane nodes"
}

output "node_workers" {
  value = [
    for i in range(length(google_dns_record_set.k8s_nodes_worker)) : {
      dns_name = google_dns_record_set.k8s_nodes_worker[i].name
      ip_address = module.k8s-node-worker.k8s-nodes[i].network_interface[0].network_ip
    }
  ]
  description = "The DNS names and IP addresses of the worker nodes"
}