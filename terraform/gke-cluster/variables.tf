variable "project_id" {
  default = ""
}
variable "region" {
  default = "europe-west8"
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  default     = "gke-cluster"
}

variable "zones" {
  type        = list(string)
  default = ["europe-west8-a"]
  description = "The zone to host the cluster in (required if is a zonal cluster)"
}

variable "network" {
  description = "The VPC network created to host the cluster in"
  default     = "gke-network"
}

variable "subnetwork" {
  description = "The subnetwork created to host the cluster in"
  default     = "gke-subnet"
}

variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "ip-range-pods"
}

variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = "ip-range-svc"
}
