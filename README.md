# gke-tf

This terraform module creates a VPC and a private GKE cluster

Create a `terraform.tfvars` file to pass the required variables

For instance, I used
```
project_id = "MY_PROJECT"
bucket_name= "it-fabioformosa.MY_PROJECT"
bucket_prefix = "terraform/state"
cluster_service_account = "tf-gke@quartz-manager-test.iam.gserviceaccount.com"
```

## QUICK START
Launch ./terraform-init.sh to create a GCS bucket to use as backend for a terraform remote state

The script requires to specify as argument the name of bucket used to store the terraform remote state.
Make sure this bucket name matches with that one specified in the `terraform.tfvars` file

```
terraform plan
terraform apply
```

Finally `gcloud container clusters get-credentials CLUSTER_NAME --location=LOCATION`
