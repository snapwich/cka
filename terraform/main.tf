
provider "google" {
  credentials = file("credentials.json")
  project     = "richsnapp-174618"
  region      = "us-west1"
}

variable "local_ip" {
  description = "The IP address of the local machine"
  default     = "166.70.229.151/32"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "region" {
    description = "The GCP region"
    default     = "us-west1"
}

variable "zone" {
    description = "The GCP zone"
    default     = "us-west1-c"
}

variable "node_count" {
    description = "The number of nodes to create"
    default     = 1
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

resource "google_compute_firewall" "allow_ssh_jumpbox" {
  name    = "allow-ssh-jumpbox"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.local_ip]

  target_tags = ["ssh"]
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

  source_ranges = [var.vpc_cidr]
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

resource "google_dns_record_set" "k8s_nodes" {
  count        = length(google_compute_instance.k8s-node)
  name         = "${google_compute_instance.k8s-node[count.index].name}.internal."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.k8s-cka.name
  rrdatas      = [google_compute_instance.k8s-node[count.index].network_interface[0].network_ip]
}

resource "google_compute_instance" "jumpbox" {
  boot_disk {
    auto_delete = true
    device_name = "jumpbox"

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20240415"
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

  tags = ["ssh"]
  zone = var.zone
}


resource "google_compute_instance" "k8s-node" {
  count = var.node_count

  boot_disk {
    auto_delete = true
    device_name = "k8s-node-${count.index}"

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20240415"
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
  name         = "k8s-node-${count.index}"

  network_interface {
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

  zone = var.zone
}
