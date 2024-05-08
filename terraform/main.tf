
provider "google" {
  credentials = file("credentials.json")
  project     = "richsnapp-174618"
  region      = "us-west1"
}

resource "google_compute_network" "vpc_network" {
  name                    = "k8s"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = "k8s-nodes"
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-west1"
  network       = google_compute_network.vpc_network.self_link
}

resource "google_compute_instance" "k8s-node" {
  count = 1

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

  zone = "us-west1-c"
}
