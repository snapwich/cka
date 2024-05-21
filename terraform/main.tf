
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.28.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }
  }
}

provider "google" {
  credentials = file(var.gcp_credentials)
  project     = var.project
  region      = var.region
}

resource "google_compute_network" "vpc_network" {
  name                    = "k8s-cka"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = "k8s-nodes"
  ip_cidr_range = var.vpc_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_router" "router" {
  name    = "k8s-cka-router"
  network = google_compute_network.vpc_network.self_link
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-gateway"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.vpc_subnetwork.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_firewall" "allow_ssh_jumpbox" {
  name    = "allow-ssh-jumpbox"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.public_ip]

  target_tags = ["ssh"]
}

resource "google_compute_firewall" "allow_kube_api_jumpbox" {
  name    = "allow-apiserver-jumpbox"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = [var.public_ip]

  target_tags = ["apiserver"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-all-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.vpc_cidr, var.pod_cidr]
  direction     = "INGRESS"
  priority      = 1000
  description   = "Allow internal traffic within the VPC"
}

resource "google_dns_managed_zone" "k8s-cka" {
  name        = "k8s-cka-internal"
  dns_name    = "internal."
  description = "Private zone for internal DNS"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc_network.self_link
    }
  }
}

resource "google_dns_record_set" "k8s_cp" {
  name         = "k8s-cp.internal."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.k8s-cka.name
  rrdatas      = [for node in module.k8s-node-cp.k8s-nodes : node.network_interface[0].network_ip]
}

resource "google_dns_record_set" "k8s_nodes_cp" {
  count        = var.cp_count
  name         = "${module.k8s-node-cp.k8s-nodes[count.index].name}.internal."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.k8s-cka.name
  rrdatas      = [module.k8s-node-cp.k8s-nodes[count.index].network_interface[0].network_ip]
}

resource "google_dns_record_set" "k8s_nodes_worker" {
  count        = var.worker_count
  name         = "${module.k8s-node-worker.k8s-nodes[count.index].name}.internal."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.k8s-cka.name
  rrdatas      = [module.k8s-node-worker.k8s-nodes[count.index].network_interface[0].network_ip]
}

resource "google_compute_instance" "jumpbox" {
  boot_disk {
    auto_delete = true
    device_name = "jumpbox"

    initialize_params {
      image = var.image
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = true
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-small"
  name         = "jumpbox"

  network_interface {
    access_config {
      network_tier = "STANDARD"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = google_compute_subnetwork.vpc_subnetwork.self_link
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

  tags = ["ssh", "apiserver"]
  zone = var.zone

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_key_file)}"
  }
}

resource "ansible_host" "k8s-jumpbox" {
  name = google_compute_instance.jumpbox.name
  groups = ["bastion"]

  variables = {
    ansible_user = var.ssh_user
    ansible_host = google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip
  }
}


locals {
  node_types = tomap({
    "cp"     = var.cp_count
    "worker" = var.worker_count
  })
}

module "k8s-node-cp" {
  source      = "./modules/k8s-node"
  node_count  = var.cp_count
  node_type   = "cp"
  subnetwork  = google_compute_subnetwork.vpc_subnetwork.self_link
  zone        = var.zone
  image       = var.image
  jumpbox_ip  = google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip
}

module "k8s-node-worker" {
  source      = "./modules/k8s-node"
  node_count  = var.worker_count
  node_type   = "worker"
  subnetwork  = google_compute_subnetwork.vpc_subnetwork.self_link
  zone        = var.zone
  image       = var.image
  jumpbox_ip = google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip
}