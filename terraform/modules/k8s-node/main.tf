terraform {
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
  }
}

resource "google_compute_instance" "k8s-node" {
  count = var.node_count

  boot_disk {
    auto_delete = true
    device_name = "k8s-node-${var.node_type}-${count.index}"

    initialize_params {
      image = var.image
      size  = 10
      type  = "pd-standard"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = true
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-standard-2"
  name         = "k8s-node-${var.node_type}-${count.index}"

  network_interface {
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = var.subnetwork
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_key_file)}"
  }

  zone = var.zone
}

resource "ansible_host" "k8s-node" {
  count = var.node_count

  name = google_compute_instance.k8s-node[count.index].name
  groups = concat(
    [var.node_type == "cp" ? "kube_control_plane" : "kube_node", "k8s_cluster"],
    var.node_type == "cp" ? ["etcd"] : []
  )

  variables = {
    ansible_user = var.ssh_user
    ansible_host = google_compute_instance.k8s-node[count.index].network_interface[0].network_ip
    ansible_ssh_common_args = var.jumpbox_ip != "" ? "-o ProxyJump=${var.ssh_user}@${var.jumpbox_ip}" : null
  }
}
