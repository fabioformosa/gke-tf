provider "google" {
  project = var.project_id
  region  = var.region
}
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gcp-network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.1"

  project_id   = var.project_id
  network_name = var.network

  subnets = [
    {
      subnet_name           = var.subnetwork
      subnet_ip             = "10.0.0.0/17"
      subnet_region         = var.region
      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    (var.subnetwork) = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }
}

data "google_compute_subnetwork" "subnetwork" {
  name       = var.subnetwork
  project    = var.project_id
  region     = var.region
  depends_on = [module.gcp-network]
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 31.0"

  project_id = var.project_id
  name       = var.cluster_name
  regional   = false
  region     = var.region
  zones      = slice(var.zones, 0, 1)

  network                 = module.gcp-network.network_name
  subnetwork              = module.gcp-network.subnets_names[0]
  ip_range_pods           = var.ip_range_pods_name
  ip_range_services       = var.ip_range_services_name
  create_service_account  = true
  enable_private_endpoint = false
  enable_private_nodes    = true
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  deletion_protection     = false

  remove_default_node_pool    = true
  horizontal_pod_autoscaling  = false

  node_pools = [
    {
      name                        = "default-node-pool"
      machine_type                = var.default_node_pool_machine_type
      node_locations              = "europe-west8-a,europe-west8-b"
      min_count                   = 1
      max_count                   = 3
      local_ssd_count             = 0
      spot                        = false
      disk_size_gb                = 12
      disk_type                   = "pd-balanced"
      image_type                  = "COS_CONTAINERD"
      enable_gcfs                 = false
      enable_gvnic                = false
      logging_variant             = "DEFAULT"
      auto_repair                 = true
      auto_upgrade                = true
      autoscaling                 = false
      create_service_account      = true
      service_account_name        = var.cluster_service_account
      preemptible                 = false
#      initial_node_count          = 80
#      accelerator_count           = 1
#      accelerator_type            = "nvidia-l4"
#      gpu_driver_version          = "LATEST"
#      gpu_sharing_strategy        = "TIME_SHARING"
#      max_shared_clients_per_gpu = 2
    },
  ]
}


#Firewall rule to solve connection timeout related to ValidatingWebhookConfiguration in GKE  https://stackoverflow.com/a/65675908/3305311
module "validating_webhook_firewall_rule" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "9.1.0"

  project_id   = var.project_id
  network_name = module.gcp-network.network_name

  rules = [{
    name                    = format("gke-validating-webhook-allowed-%s", var.network)
    description             = format("Firewall Rule for allowing ValidatingWebhook connection bw masters and workers")
    direction               = "INGRESS"
    priority                = null
    ranges                  = [var.master_ipv4_cidr_block]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = [var.cluster_service_account]
    allow = [{
      protocol = "tcp"
      ports    = [8443]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }]
}
